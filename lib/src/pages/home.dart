// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/pages/more/more_page.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:gallery/src/widgets/skeletons/home.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

part "home/animated_icons_mixin.dart";
part "home/before_you_continue_dialog_mixin.dart";
part "home/change_page_mixin.dart";
part "home/icons/anime_icon.dart";
part "home/icons/booru_icon.dart";
part "home/icons/gallery_icon.dart";
part "home/icons/manga_icon.dart";
part "home/navigator_shell.dart";

class Home extends StatefulWidget {
  const Home({super.key, this.callback});
  final CallbackDescriptionNested? callback;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin,
        ChangePageMixin,
        AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin {
  late final StreamSubscription<void> _settingsSubscription;

  final state = SkeletonState();
  final settings = SettingsService.db().current;

  bool isRefreshing = false;

  late bool showAnimeMangaPages = settings.showAnimeMangaPages;

  @override
  void initState() {
    super.initState();

    _settingsSubscription = settings.s.watch((s) {
      if (showAnimeMangaPages != s!.showAnimeMangaPages) {
        setState(() {
          showAnimeMangaPages = s.showAnimeMangaPages;
          if (showAnimeMangaPages &&
              _routeNotifier.value == CurrentRoute.manga) {
            _routeNotifier.value = CurrentRoute.more;
          } else if (!showAnimeMangaPages &&
              _routeNotifier.value == CurrentRoute.more) {
            _routeNotifier.value = CurrentRoute.manga;
          }
        });
      }
    });

    initChangePage(this, settings);
    initIcons(this);

    maybeBeforeYouContinueDialog(context, settings);

    NetworkStatus.g.notify = () {
      try {
        setState(() {});
      } catch (_) {}
    };
  }

  @override
  void dispose() {
    _morePageNotifier.dispose();
    _galleryPageNotifier.dispose();
    _booruPageNotifier.dispose();
    _settingsSubscription.cancel();
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
      MoreSubPage.wrap(
        _morePageNotifier,
        GallerySubPage.wrap(
          _galleryPageNotifier,
          BooruSubPage.wrap(
            _booruPageNotifier,
            PopScope(
              canPop: widget.callback != null,
              onPopInvokedWithResult: (pop, _) => _procPopAll(
                _galleryPageNotifier,
                _morePageNotifier,
                this,
                pop,
              ),
              child: HomeSkeleton(
                key: ValueKey(showAnimeMangaPages),
                _CurrentPageWidget(
                  icons: this,
                  changePage: this,
                  callback: widget.callback,
                  showAnimeMangaPages: showAnimeMangaPages,
                ),
                extendBody: true,
                noNavBar: widget.callback != null,
                animatedIcons: this,
                showAnimeMangaPages: showAnimeMangaPages,
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

                    animateIcons(this, showAnimeMangaPages);
                  } else if (showAnimeMangaPages
                      ? route == CurrentRoute.more &&
                          currentRoute == CurrentRoute.more
                      : route == CurrentRoute.manga &&
                          currentRoute == CurrentRoute.manga) {
                    final nav = moreKey.currentState;
                    if (nav != null) {
                      while (nav.canPop()) {
                        nav.pop();
                      }
                    }

                    _morePageNotifier.value =
                        _morePageNotifier.value == MoreSubPage.more
                            ? MoreSubPage.dashboard
                            : MoreSubPage.more;

                    animateIcons(this, showAnimeMangaPages);
                  } else {
                    switchPage(
                      this,
                      route,
                      showAnimeMangaPages,
                    );
                  }
                },
                changePage: this,
                booru: settings.selectedBooru,
                callback: widget.callback,
              ),
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
