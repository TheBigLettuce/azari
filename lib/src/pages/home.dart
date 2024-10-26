// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/gallery/callback_description.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/more/settings/settings_page.dart";
import "package:azari/src/platform/network_status.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:azari/src/widgets/skeletons/home.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

part "home/animated_icons_mixin.dart";
part "home/before_you_continue_dialog_mixin.dart";
part "home/change_page_mixin.dart";
part "home/icons/anime_icon.dart";
part "home/icons/booru_icon.dart";
part "home/icons/gallery_icon.dart";
part "home/navigator_shell.dart";

class Home extends StatefulWidget {
  const Home({
    super.key,
    this.callback,
    required this.stream,
  });

  final CallbackDescriptionNested? callback;
  final Stream<NotificationRouteEvent> stream;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin,
        ChangePageMixin,
        AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin {
  final state = SkeletonState();
  final settings = SettingsService.db().current;

  late final StreamSubscription<NotificationRouteEvent> notificationEvents;

  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    notificationEvents = widget.stream.listen((route) {
      final currentRoute = _routeNotifier.value;

      switch (route) {
        case NotificationRouteEvent.downloads:
          if (currentRoute != CurrentRoute.booru) {
            switchPage(this, CurrentRoute.booru);
          }

          _booruPageNotifier.value = BooruSubPage.downloads;
      }
    });

    initChangePage(this, settings);
    initIcons(this);

    maybeBeforeYouContinueDialog(context, settings);

    if (isRestart) {
      restartOver();
    }

    NetworkStatus.g.notify = () {
      try {
        setState(() {});
      } catch (_) {}
    };
  }

  @override
  void dispose() {
    notificationEvents.cancel();

    _galleryPageNotifier.dispose();
    _booruPageNotifier.dispose();
    disposeIcons();
    disposeChangePage();

    NetworkStatus.g.notify = null;

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurrentRoute.wrap(
      _routeNotifier,
      GallerySubPage.wrap(
        _galleryPageNotifier,
        BooruSubPage.wrap(
          _booruPageNotifier,
          PopScope(
            canPop: widget.callback != null,
            onPopInvokedWithResult: (pop, _) => _procPopAll(
              _galleryPageNotifier,
              this,
              pop,
            ),
            child: HomeSkeleton(
              _CurrentPageWidget(
                icons: this,
                changePage: this,
                callback: widget.callback,
              ),
              noNavBar: widget.callback != null,
              animatedIcons: this,
              onDestinationSelected: (context, route) {
                GlueProvider.generateOf(context)().updateCount(0);

                final currentRoute = _routeNotifier.value;

                if (route == CurrentRoute.booru &&
                    currentRoute == CurrentRoute.booru) {
                  Scaffold.of(context).openDrawer();
                } else if (route == CurrentRoute.gallery &&
                    currentRoute == CurrentRoute.gallery) {
                  final nav = galleryKey.currentState;
                  if (nav != null) {
                    while (nav.canPop()) {
                      nav.pop();
                    }
                  }

                  _galleryPageNotifier.value =
                      _galleryPageNotifier.value == GallerySubPage.gallery
                          ? GallerySubPage.blacklisted
                          : GallerySubPage.gallery;

                  animateIcons(this);
                } else {
                  switchPage(this, route);
                }
              },
              changePage: this,
              booru: settings.selectedBooru,
              callback: widget.callback,
            ),
          ),
        ),
      ),
    );
  }
}

class GlueStateProvider extends InheritedWidget {
  const GlueStateProvider({
    required this.state,
    required super.child,
  });

  final SelectionGlueState state;

  static SelectionGlueState of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GlueStateProvider>();

    return widget!.state;
  }

  @override
  bool updateShouldNotify(GlueStateProvider oldWidget) {
    return state != oldWidget.state;
  }
}
