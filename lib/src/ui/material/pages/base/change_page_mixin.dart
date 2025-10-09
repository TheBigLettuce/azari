// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "home.dart";

enum CurrentRoute {
  home,
  discover,
  gallery;

  factory CurrentRoute.fromIndex(int i) => switch (i) {
    0 => home,
    1 => discover,
    2 => gallery,
    int() => throw "no route",
  };

  bool hasServices() => switch (this) {
    CurrentRoute.home => BooruPage.hasServicesRequired(),
    CurrentRoute.discover => DiscoverPage.hasServicesRequired(),
    CurrentRoute.gallery => DirectoriesPage.hasServicesRequired(),
  };

  Widget icon(AnimatedIconsMixin mixin) => switch (this) {
    home => HomeDestinationIcon(controller: mixin.homeIconController),
    discover => DiscoverDestinationIcon(
      controller: mixin.discoverIconController,
    ),
    gallery => GalleryDestinationIcon(controller: mixin.galleryIconController),
  };

  static Widget wrap(ValueNotifier<CurrentRoute> notifier, Widget child) =>
      _SelectedRoute(notifier: notifier, child: child);

  String label(BuildContext context, AppLocalizations l10n, Booru booru) =>
      switch (this) {
        home => _booruDestinationLabel(context, l10n, booru.string),
        gallery => l10n.galleryLabel,
        discover => l10n.discoverPage,
      };

  static CurrentRoute of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SelectedRoute>()!
        .notifier!
        .value;
  }

  static void selectOf(BuildContext context, CurrentRoute route) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectedRoute>()!;

    widget.notifier!.value = route;
  }
}

String _booruDestinationLabel(
  BuildContext context,
  AppLocalizations l10n,
  String label,
) {
  final selectedBooruPage = BooruSubPage.of(context);

  return selectedBooruPage == BooruSubPage.booru
      ? label
      : selectedBooruPage.translatedString(l10n);
}

enum BooruSubPage {
  booru(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
  favorites(
    icon: Icons.favorite_outline_rounded,
    selectedIcon: Icons.favorite_rounded,
  ),
  downloads(
    icon: Icons.download_outlined,
    selectedIcon: Icons.download_rounded,
  ),
  more(icon: Icons.more_horiz_outlined, selectedIcon: Icons.more_horiz_rounded);

  const BooruSubPage({required this.icon, required this.selectedIcon});

  factory BooruSubPage.fromIdx(int idx) => switch (idx) {
    0 => booru,
    1 => favorites,
    2 => downloads,
    3 => more,
    int() => booru,
  };

  final IconData icon;
  final IconData selectedIcon;

  bool hasServices() => switch (this) {
    BooruSubPage.booru => BooruPage.hasServicesRequired(),
    BooruSubPage.favorites => FavoritePostsPage.hasServicesRequired(),
    BooruSubPage.downloads => DownloadsPage.hasServicesRequired(),
    BooruSubPage.more => MorePage.hasServicesRequired(),
  };

  String translatedString(AppLocalizations l10n) => switch (this) {
    booru => l10n.booruLabel,
    favorites => l10n.favoritesLabel,
    downloads => l10n.downloadsPageName,
    more => l10n.more,
  };

  static Widget wrap(ValueNotifier<BooruSubPage> notifier, Widget child) =>
      _SelectedBooruPage(notifier: notifier, child: child);

  static BooruSubPage of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, BooruSubPage page) {
    SelectionActions.controllerOf(context).setCount(0);

    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    widget!.notifier!.value = page;
  }
}

mixin ChangePageMixin on State<Home> {
  final pagingRegistry = PagingStateRegistry();

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final settingsKey = GlobalKey<NavigatorState>();

  final _routeNotifier = ValueNotifier<CurrentRoute>(CurrentRoute.home);

  final _booruPageNotifier = ValueNotifier<BooruSubPage>(BooruSubPage.booru);

  String? restoreBookmarksPage;

  @override
  void dispose() {
    if (!SettingsPage.themeIsChanging) {
      _routeNotifier.dispose();
      pagingRegistry.recycle();
    } else {
      SettingsPage.themeChangeOver();
    }

    super.dispose();
  }

  Future<void> animateIcons(AnimatedIconsMixin icons) {
    return switch (_routeNotifier.value) {
      CurrentRoute.home => icons.homeIconController.reverse().then(
        (value) => icons.homeIconController.forward(),
      ),
      CurrentRoute.gallery => icons.galleryIconController.reverse().then(
        (value) => icons.galleryIconController.forward(),
      ),
      CurrentRoute.discover => icons.discoverIconController.reverse().then(
        (value) => icons.discoverIconController.forward(),
      ),
    };
  }

  void switchPage(AnimatedIconsMixin icons, CurrentRoute to) {
    if (to == _routeNotifier.value) {
      return;
    }

    if (to == CurrentRoute.home) {
      SettingsPage.restartOver();
    } else {
      SettingsPage.restartStart();
    }

    icons.pageFadeAnimation.animateTo(1).then((value) {
      _routeNotifier.value = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      animateIcons(icons);
    });
  }

  void _procPopAll(AnimatedIconsMixin icons, bool _) {
    mainKey.currentState?.maybePop();

    galleryKey.currentState?.maybePop();
    settingsKey.currentState?.maybePop().then((value) {
      if (!value) {
        _procPop(icons, false);
      }
    });
  }

  void _procPop(AnimatedIconsMixin icons, bool pop) {
    if (!pop) {
      switchPage(icons, CurrentRoute.home);
    }
  }

  void _procPopA(
    ValueNotifier<BooruSubPage> booruPage,
    AnimatedIconsMixin icons,
    bool pop,
  ) {
    if (!pop) {
      if (_routeNotifier.value == CurrentRoute.home &&
          booruPage.value != BooruSubPage.booru) {
        booruPage.value = BooruSubPage.booru;
        animateIcons(icons);
      } else {
        switchPage(icons, CurrentRoute.gallery);
      }
    }
  }
}

class _CurrentPageWidget extends StatelessWidget {
  const _CurrentPageWidget({
    // super.key,
    required this.icons,
    required this.changePage,
    required this.settingsService,
  });

  final AnimatedIconsMixin icons;
  final ChangePageMixin changePage;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final booruPage = changePage._booruPageNotifier;

    return Animate(
      target: 0,
      effects: [
        FadeEffect(duration: 50.ms, begin: 1, end: 0),
        const ThenEffect(delay: Duration(milliseconds: 50)),
      ],
      controller: icons.pageFadeAnimation,
      child: switch (changePage._routeNotifier.value) {
        CurrentRoute.home =>
          !GridDbService.available
              ? const SizedBox.shrink()
              : _NavigatorShell(
                  navigatorKey: changePage.mainKey,
                  child: BooruPage(
                    pagingRegistry: changePage.pagingRegistry,
                    procPop: (pop) =>
                        changePage._procPopA(booruPage, icons, pop),
                    selectionController: SelectionActions.controllerOf(context),
                  ),
                ),
        CurrentRoute.discover => _NavigatorShell(
          navigatorKey: changePage.settingsKey,
          child: DiscoverPage(
            procPop: (pop) => changePage._procPop(icons, pop),
            selectionController: SelectionActions.controllerOf(context),
          ),
        ),
        CurrentRoute.gallery =>
          !GridDbService.available ||
                  !GridSettingsService.available ||
                  !GalleryService.available
              ? const SizedBox.shrink()
              : _NavigatorShell(
                  navigatorKey: changePage.galleryKey,
                  child: DirectoriesPage(
                    procPop: (pop) => changePage._procPop(icons, pop),
                    selectionController: SelectionActions.controllerOf(context),
                  ),
                ),
      },
    );
  }
}

class PagingStateRegistry {
  final Map<String, PagingEntry> _map = {};

  T getOrRegister<T extends PagingEntry>(String key, T Function() prototype) {
    final e = _map[key];
    if (e != null) {
      return e as T;
    }

    _map[key] = prototype();

    return _map[key]! as T;
  }

  PagingEntry? remove(String key) => _map.remove(key);

  void recycle() {
    for (final e in _map.entries) {
      e.value.dispose();
    }
    clear();
  }

  void clear() {
    _map.clear();
  }

  Widget inject(Widget child) =>
      _PagingStateProvider(registry: this, child: child);

  static PagingStateRegistry of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_PagingStateProvider>();

    return widget!.registry;
  }
}

class _PagingStateProvider extends InheritedWidget {
  const _PagingStateProvider({required this.registry, required super.child});

  final PagingStateRegistry registry;

  @override
  bool updateShouldNotify(_PagingStateProvider oldWidget) {
    return registry != oldWidget.registry;
  }
}

abstract class PagingEntry implements PageSaver {
  double get offset;
  void setOffset(double o);

  bool get reachedEnd;
  set reachedEnd(bool r);

  void updateTime();

  void dispose();
}

class _NavigatorShell extends StatefulWidget {
  const _NavigatorShell({required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<_NavigatorShell> createState() => __NavigatorShellState();
}

class __NavigatorShellState extends State<_NavigatorShell> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(
            builder: (_) {
              return widget.child;
            },
          ),
        ];
      },
    );
  }
}

class _SelectedRoute extends InheritedNotifier<ValueNotifier<CurrentRoute>> {
  const _SelectedRoute({
    required ValueNotifier<CurrentRoute> notifier,
    required super.child,
  }) : super(notifier: notifier);
}

class _SelectedBooruPage
    extends InheritedNotifier<ValueNotifier<BooruSubPage>> {
  const _SelectedBooruPage({
    required ValueNotifier<BooruSubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
