// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/app.dart";
import "package:azari/src/ui/material/pages/base/home_skeleton.dart";
import "package:azari/src/ui/material/pages/discover/discover.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/home/downloads.dart";
import "package:azari/src/ui/material/pages/home/favorite_posts_page.dart";
import "package:azari/src/ui/material/pages/settings/settings_page.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

part "animated_icons_mixin.dart";
part "before_you_continue_dialog_mixin.dart";
part "change_page_mixin.dart";
part "icons/discover.dart";
part "icons/gallery.dart";
part "icons/home.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin<Home>,
        ChangePageMixin,
        AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin,
        WebLinksImplMixin {
  late final SettingsData settings;

  late final StreamSubscription<NotificationRouteEvent> notificationEvents;
  final navBarEvents = StreamController<void>.broadcast();
  final scrollingState = ScrollingStateSink();

  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    Events.procWebLinks();

    settings = const SettingsService().current;

    notificationEvents = const AppApi().notificationEvents.listen((route) {
      final currentRoute = _routeNotifier.value;

      switch (route) {
        case NotificationRouteEvent.downloads:
          if (currentRoute != CurrentRoute.home) {
            switchPage(this, CurrentRoute.home);
          }

          _booruPageNotifier.value = BooruSubPage.downloads;
      }
    });

    if (GalleryService.available) {
      maybeBeforeYouContinueDialog(context, settings, const GalleryService());
    }

    if (SettingsPage.isRestart) {
      SettingsPage.restartOver();
    }
  }

  @override
  void dispose() {
    scrollingState.dispose();
    navBarEvents.close();
    notificationEvents.cancel();

    _booruPageNotifier.dispose();

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

      animateIcons(this);
    } else {
      switchPage(this, route);
    }

    scrollingState.sink.add(true);
  }

  void onPop(bool didPop, Object? _) {
    _procPopAll(this, didPop);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollingStateSinkProvider(
      stateSink: scrollingState,
      child: NavigationButtonEvents(
        events: navBarEvents.stream,
        child: CurrentRoute.wrap(
          _routeNotifier,
          BooruSubPage.wrap(
            _booruPageNotifier,
            PopScope(
              canPop: false,
              onPopInvokedWithResult: onPop,
              child: HomeSkeleton(
                animatedIcons: this,
                onDestinationSelected: onDestinationSelected,
                booru: settings.selectedBooru,
                scrollingState: scrollingState,
                drawer: HomeDrawer(
                  changePage: this,
                  animatedIcons: this,
                  switchToHome: () =>
                      onDestinationSelected(context, CurrentRoute.home),
                  settingsService: const SettingsService(),
                  gridBookmarks: GridBookmarkService.safe(),
                  favoritePosts: FavoritePostSourceService.safe(),
                ),
                child: _CurrentPageWidget(
                  icons: this,
                  changePage: this,
                  settingsService: const SettingsService(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScrollingStateSink {
  ScrollingStateSink();

  final _scrollingEvents = StreamController<bool>.broadcast();

  IsExpandedConnector? _connector;

  StreamSink<bool> get sink => _scrollingEvents.sink;
  Stream<bool> get stream => _scrollingEvents.stream;
  bool get isExpanded => _connector?.isExpanded ?? false;

  // ignore: use_setters_to_change_properties
  void connect(IsExpandedConnector connector) {
    _connector = connector;
  }

  void disconnect() {
    _connector = null;
  }

  void dispose() {
    _connector = null;
    _scrollingEvents.close();
  }
}

class ScrollingStateSinkProvider extends InheritedWidget {
  const ScrollingStateSinkProvider({
    required this.stateSink,
    required super.child,
  });

  final ScrollingStateSink stateSink;

  static ScrollingStateSink? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ScrollingStateSinkProvider>();

    return widget?.stateSink;
  }

  @override
  bool updateShouldNotify(ScrollingStateSinkProvider oldWidget) {
    return stateSink != oldWidget.stateSink;
  }
}

class NavigationButtonEvents extends InheritedWidget {
  const NavigationButtonEvents({required this.events, required super.child});

  final Stream<void> events;

  static Stream<void>? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<NavigationButtonEvents>();

    return widget?.events;
  }

  @override
  bool updateShouldNotify(NavigationButtonEvents oldWidget) {
    return events != oldWidget.events;
  }
}

class PinnedTagsProvider extends InheritedWidget {
  const PinnedTagsProvider({required this.pinnedTags, required super.child});

  final ({Map<String, void> map, int count}) pinnedTags;

  static ({Map<String, void> map, int count}) of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<PinnedTagsProvider>();

    return widget!.pinnedTags;
  }

  @override
  bool updateShouldNotify(PinnedTagsProvider oldWidget) {
    return pinnedTags != oldWidget.pinnedTags;
  }
}
