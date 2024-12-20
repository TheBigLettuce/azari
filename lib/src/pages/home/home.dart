// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/discover/discover.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/home/home_skeleton.dart";
import "package:azari/src/pages/other/settings/settings_page.dart";
import "package:azari/src/platform/network_status.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

part "animated_icons_mixin.dart";
part "before_you_continue_dialog_mixin.dart";
part "change_page_mixin.dart";
part "icons/discover.dart";
part "icons/gallery.dart";
part "icons/home.dart";
part "icons/search.dart";
part "navigator_shell.dart";

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.stream,
  });

  final Stream<NotificationRouteEvent> stream;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin<Home>,
        ChangePageMixin,
        AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin {
  final settings = SettingsService.db().current;

  late final StreamSubscription<NotificationRouteEvent> notificationEvents;
  final navBarEvents = StreamController<void>.broadcast();
  final scrollingEvents = StreamController<bool>.broadcast();

  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    notificationEvents = widget.stream.listen((route) {
      final currentRoute = _routeNotifier.value;

      switch (route) {
        case NotificationRouteEvent.downloads:
          if (currentRoute != CurrentRoute.home) {
            switchPage(this, CurrentRoute.home);
          }

          _booruPageNotifier.value = BooruSubPage.downloads;
      }
    });

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
    scrollingEvents.close();
    navBarEvents.close();
    notificationEvents.cancel();

    _galleryPageNotifier.dispose();
    _booruPageNotifier.dispose();

    NetworkStatus.g.notify = null;

    super.dispose();
  }

  void onDestinationSelected(BuildContext context, CurrentRoute route) {
    if (route == _routeNotifier.value) {
      navBarEvents.add(null);
      return;
    }

    SelectionActions.controllerOf(context).setCount(0);

    final currentRoute = _routeNotifier.value;

    if (route == CurrentRoute.home && currentRoute == CurrentRoute.home) {
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

    scrollingEvents.add(true);
  }

  void onPop(bool didPop, Object? _) {
    _procPopAll(
      _galleryPageNotifier,
      this,
      didPop,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollingSinkProvider(
      sink: scrollingEvents.sink,
      child: NavigationButtonEvents(
        events: navBarEvents.stream,
        child: CurrentRoute.wrap(
          _routeNotifier,
          GallerySubPage.wrap(
            _galleryPageNotifier,
            BooruSubPage.wrap(
              _booruPageNotifier,
              PopScope(
                canPop: false,
                onPopInvokedWithResult: onPop,
                child: HomeSkeleton(
                  animatedIcons: this,
                  onDestinationSelected: onDestinationSelected,
                  changePage: this,
                  booru: settings.selectedBooru,
                  scrollingEvents: scrollingEvents.stream,
                  child: _CurrentPageWidget(
                    icons: this,
                    changePage: this,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScrollingSinkProvider extends InheritedWidget {
  const ScrollingSinkProvider({
    required this.sink,
    required super.child,
  });

  final StreamSink<bool> sink;

  static StreamSink<bool>? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ScrollingSinkProvider>();

    return widget?.sink;
  }

  @override
  bool updateShouldNotify(ScrollingSinkProvider oldWidget) {
    return sink != oldWidget.sink;
  }
}

class NavigationButtonEvents extends InheritedWidget {
  const NavigationButtonEvents({
    required this.events,
    required super.child,
  });

  final Stream<void> events;

  static Stream<void>? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<NavigationButtonEvents>();

    return widget?.events;
  }

  @override
  bool updateShouldNotify(NavigationButtonEvents oldWidget) {
    return events != oldWidget.events;
  }
}

class PinnedTagsProvider extends InheritedWidget {
  const PinnedTagsProvider({
    required this.pinnedTags,
    required super.child,
  });

  final (Map<String, void> map, int count) pinnedTags;

  static (Map<String, void> map, int count) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PinnedTagsProvider>();

    return widget!.pinnedTags;
  }

  @override
  bool updateShouldNotify(PinnedTagsProvider oldWidget) {
    return pinnedTags != oldWidget.pinnedTags;
  }
}
