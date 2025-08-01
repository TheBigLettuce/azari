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
        gallery => GallerySubPage.of(context).translatedString(l10n),
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
  bookmarks(
    icon: Icons.bookmarks_outlined,
    selectedIcon: Icons.bookmarks_rounded,
  ),
  hiddenPosts(
    icon: Icons.hide_image_outlined,
    selectedIcon: Icons.hide_image_rounded,
  ),
  downloads(
    icon: Icons.download_outlined,
    selectedIcon: Icons.download_rounded,
  ),
  visited(icon: Icons.schedule_outlined, selectedIcon: Icons.schedule_rounded);

  const BooruSubPage({required this.icon, required this.selectedIcon});

  factory BooruSubPage.fromIdx(int idx) => switch (idx) {
    0 => booru,
    1 => favorites,
    2 => bookmarks,
    3 => hiddenPosts,
    4 => downloads,
    5 => visited,
    int() => booru,
  };

  final IconData icon;
  final IconData selectedIcon;

  bool hasServices() => switch (this) {
    BooruSubPage.booru => BooruPage.hasServicesRequired(),
    BooruSubPage.favorites => FavoritePostsPage.hasServicesRequired(),
    BooruSubPage.bookmarks => BookmarkPage.hasServicesRequired(),
    BooruSubPage.hiddenPosts => HiddenPostsPage.hasServicesRequired(),
    BooruSubPage.downloads => DownloadsPage.hasServicesRequired(),
    BooruSubPage.visited => VisitedPostsPage.hasServicesRequired(),
  };

  String translatedString(AppLocalizations l10n) => switch (this) {
    booru => l10n.booruLabel,
    favorites => l10n.favoritesLabel,
    bookmarks => l10n.bookmarksPageName,
    hiddenPosts => l10n.hiddenPostsPageName,
    downloads => l10n.downloadsPageName,
    visited => l10n.visitedPage,
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

enum GallerySubPage {
  gallery(
    icon: Icons.collections_outlined,
    selectedIcon: Icons.collections_rounded,
  ),
  blacklisted(
    icon: Icons.folder_off_outlined,
    selectedIcon: Icons.folder_off_rounded,
  );

  const GallerySubPage({required this.icon, required this.selectedIcon});

  factory GallerySubPage.fromIdx(int idx) => switch (idx) {
    0 => gallery,
    1 => blacklisted,
    int() => gallery,
  };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
    GallerySubPage.gallery => l10n.galleryLabel,
    GallerySubPage.blacklisted => l10n.blacklistedFoldersPage,
  };

  static Widget wrap(ValueNotifier<GallerySubPage> notifier, Widget child) =>
      _SelectedGalleryPage(notifier: notifier, child: child);

  static GallerySubPage of(BuildContext context) => maybeOf(context)!;

  static GallerySubPage? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

    return widget?.notifier!.value;
  }

  static void selectOf(BuildContext context, GallerySubPage page) {
    SelectionActions.controllerOf(context).setCount(0);

    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

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
    if (!themeIsChanging) {
      _routeNotifier.dispose();
      pagingRegistry.recycle();
    } else {
      themeChangeOver();
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
      restartOver();
    } else {
      restartStart();
    }

    icons.pageFadeAnimation.animateTo(1).then((value) {
      _routeNotifier.value = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      animateIcons(icons);
    });
  }

  void _procPopAll(
    ValueNotifier<GallerySubPage> galleryPage,
    AnimatedIconsMixin icons,
    bool _,
  ) {
    mainKey.currentState?.maybePop();

    galleryKey.currentState?.maybePop();
    settingsKey.currentState?.maybePop().then((value) {
      if (!value) {
        _procPop(galleryPage, icons, false);
      }
    });
  }

  void _procPop(
    ValueNotifier<GallerySubPage> galleryPage,
    AnimatedIconsMixin icons,
    bool pop,
  ) {
    if (!pop) {
      if (_routeNotifier.value == CurrentRoute.gallery &&
          galleryPage.value != GallerySubPage.gallery) {
        galleryPage.value = GallerySubPage.gallery;
        animateIcons(icons);
      } else {
        switchPage(icons, CurrentRoute.home);
      }
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
    required this.galleryPageNotifier,
  });

  final AnimatedIconsMixin icons;
  final ChangePageMixin changePage;
  final ValueNotifier<GallerySubPage> galleryPageNotifier;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final booruPage = changePage._booruPageNotifier;

    // final db = Services.of(context);
    // final (gridDbs, galleryService, gridSettings) = (
    //   db.get<GridDbService>(),
    //   db.get<GalleryService>(),
    //   db.get<GridSettingsService>(),
    // );

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
        CurrentRoute.gallery =>
          !GridDbService.available ||
                  !GridSettingsService.available ||
                  !GalleryService.available
              ? const SizedBox.shrink()
              : _NavigatorShell(
                  navigatorKey: changePage.galleryKey,
                  child: DirectoriesPage(
                    procPop: (pop) =>
                        changePage._procPop(galleryPageNotifier, icons, pop),
                    selectionController: SelectionActions.controllerOf(context),
                  ),
                ),
        CurrentRoute.discover => const DiscoverPage(),
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

class _SelectedGalleryPage
    extends InheritedNotifier<ValueNotifier<GallerySubPage>> {
  const _SelectedGalleryPage({
    required ValueNotifier<GallerySubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
