// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

enum CurrentRoute {
  booru,
  gallery,
  manga,
  anime,
  more;

  factory CurrentRoute.fromIndex(int i) => switch (i) {
        0 => booru,
        1 => gallery,
        2 => manga,
        3 => anime,
        4 => more,
        int() => throw "no route",
      };

  Widget icon(
    bool showAnimeMangaPages,
    AnimatedIconsMixin mixin,
  ) =>
      switch (this) {
        CurrentRoute.booru => BooruDestinationIcon(
            controller: mixin.booruIconController,
          ),
        CurrentRoute.gallery => GalleryDestinationIcon(
            controller: mixin.galleryIconController,
          ),
        CurrentRoute.manga => MangaDestinationIcon(
            controller: mixin.favoritesIconController,
          ),
        CurrentRoute.anime => AnimeDestinationIcon(
            controller: mixin.animeIconController,
          ),
        CurrentRoute.more => MoreDestinationIcon(
            controller: mixin.moreIconController,
            showAnimeMangaPages: showAnimeMangaPages,
          ),
      };

  static Widget wrap(ValueNotifier<CurrentRoute> notifier, Widget child) =>
      _SelectedRoute(
        notifier: notifier,
        child: child,
      );

  String label(BuildContext context, AppLocalizations l10n, Booru booru) =>
      switch (this) {
        CurrentRoute.booru =>
          _booruDestinationLabel(context, l10n, booru.string),
        CurrentRoute.gallery =>
          GallerySubPage.of(context).translatedString(l10n),
        CurrentRoute.manga => l10n.mangaPage,
        CurrentRoute.anime => l10n.animePage,
        CurrentRoute.more => MoreSubPage.of(context).translatedString(l10n),
      };

  static Iterable<CurrentRoute> valuesAnimeManga(bool showAnimeMangaPages) {
    return !showAnimeMangaPages
        ? const [
            booru,
            gallery,
            more,
          ]
        : values;
  }

  static CurrentRoute of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SelectedRoute>()!
        .notifier!
        .value;
  }

  static void selectOf(BuildContext context, CurrentRoute route) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedRoute>()!;

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
  booru(
    icon: Icons.photo_outlined,
    selectedIcon: Icons.photo_rounded,
  ),
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
  );

  const BooruSubPage({
    required this.icon,
    required this.selectedIcon,
  });

  factory BooruSubPage.fromIdx(int idx) => switch (idx) {
        0 => booru,
        1 => favorites,
        2 => bookmarks,
        3 => hiddenPosts,
        int() => booru,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        BooruSubPage.booru => l10n.booruLabel,
        BooruSubPage.favorites => l10n.favoritesLabel,
        BooruSubPage.bookmarks => l10n.bookmarksPageName,
        BooruSubPage.hiddenPosts => l10n.hiddenPostsPageName,
      };

  static Widget wrap(ValueNotifier<BooruSubPage> notifier, Widget child) =>
      _SelectedBooruPage(notifier: notifier, child: child);

  static BooruSubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, BooruSubPage page) {
    GlueProvider.generateOf(context)().updateCount(0);

    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

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

  const GallerySubPage({
    required this.icon,
    required this.selectedIcon,
  });

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

  static GallerySubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, GallerySubPage page) {
    GlueProvider.generateOf(context)().updateCount(0);

    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

    widget!.notifier!.value = page;
  }
}

enum MoreSubPage {
  more(
    icon: Icons.more_horiz_outlined,
    selectedIcon: Icons.more_horiz_rounded,
  ),
  dashboard(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  );

  const MoreSubPage({
    required this.icon,
    required this.selectedIcon,
  });

  factory MoreSubPage.fromIdx(int idx) => switch (idx) {
        0 => more,
        1 => dashboard,
        int() => more,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        MoreSubPage.more => l10n.more,
        MoreSubPage.dashboard => l10n.dashboardPage,
      };

  static Widget wrap(ValueNotifier<MoreSubPage> notifier, Widget child) =>
      _SelectedMorePage(notifier: notifier, child: child);

  static MoreSubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, MoreSubPage page) {
    GlueProvider.generateOf(context)().updateCount(0);

    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

    widget!.notifier!.value = page;
  }
}

mixin ChangePageMixin on State<Home> {
  final pagingRegistry = PagingStateRegistry();

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final moreKey = GlobalKey<NavigatorState>();
  final mangaKey = GlobalKey<NavigatorState>();

  final _routeNotifier = ValueNotifier<CurrentRoute>(CurrentRoute.booru);

  final _booruPageNotifier = ValueNotifier<BooruSubPage>(BooruSubPage.booru);
  final _galleryPageNotifier =
      ValueNotifier<GallerySubPage>(GallerySubPage.gallery);
  final _morePageNotifier = ValueNotifier<MoreSubPage>(MoreSubPage.more);

  String? restoreBookmarksPage;

  void _procPopAll(
    ValueNotifier<GallerySubPage> galleryPage,
    ValueNotifier<MoreSubPage> morePage,
    AnimatedIconsMixin icons,
    bool _,
  ) {
    final f = mainKey.currentState?.maybePop();
    if (widget.callback != null) {
      f?.then((value) {
        if (!value) {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context);
          }
        }
      });
    }

    galleryKey.currentState?.maybePop();
    moreKey.currentState?.maybePop().then((value) {
      if (!value) {
        _procPop(galleryPage, morePage, icons, false);
      }
    });
    mangaKey.currentState?.maybePop();
  }

  void initChangePage(AnimatedIconsMixin icons, SettingsData settings) {}

  void disposeChangePage() {
    if (!themeIsChanging) {
      _routeNotifier.dispose();
      pagingRegistry.dispose();
    } else {
      themeChangeOver();
    }
  }

  void switchPage(
    AnimatedIconsMixin icons,
    CurrentRoute to,
    bool showAnimeMangaPages,
  ) {
    if (to == _routeNotifier.value) {
      return;
    }

    if (to == CurrentRoute.booru) {
      restartOver();
    } else {
      restartStart();
    }

    icons.pageRiseAnimation.reset();

    icons.pageFadeAnimation.animateTo(1).then((value) {
      _routeNotifier.value = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      animateIcons(icons, showAnimeMangaPages);

      icons.pageRiseAnimation.forward();
    });
  }

  void _procPop(
    ValueNotifier<GallerySubPage> galleryPage,
    ValueNotifier<MoreSubPage> morePage,
    AnimatedIconsMixin icons,
    bool pop,
  ) {
    if (!pop) {
      final showAnimeMangaPages =
          SettingsService.db().current.showAnimeMangaPages;

      if (_routeNotifier.value == CurrentRoute.gallery &&
          galleryPage.value != GallerySubPage.gallery) {
        galleryPage.value = GallerySubPage.gallery;
        animateIcons(icons, showAnimeMangaPages);
      } else if (_routeNotifier.value ==
              (showAnimeMangaPages
                  ? CurrentRoute.gallery
                  : CurrentRoute.manga) &&
          morePage.value != MoreSubPage.more) {
        morePage.value = MoreSubPage.more;
        animateIcons(icons, showAnimeMangaPages);
      } else {
        switchPage(
          icons,
          CurrentRoute.booru,
          showAnimeMangaPages,
        );
      }
    }
  }

  void _procPopA(
    ValueNotifier<BooruSubPage> booruPage,
    AnimatedIconsMixin icons,
    bool pop,
  ) {
    if (!pop) {
      if (_routeNotifier.value == CurrentRoute.booru &&
          booruPage.value != BooruSubPage.booru) {
        booruPage.value = BooruSubPage.booru;
        animateIcons(icons, SettingsService.db().current.showAnimeMangaPages);
      } else {
        final showAnimeMangaPages =
            SettingsService.db().current.showAnimeMangaPages;

        switchPage(
          icons,
          showAnimeMangaPages ? CurrentRoute.manga : CurrentRoute.gallery,
          showAnimeMangaPages,
        );
      }
    }
  }

  Future<void> animateIcons(
    AnimatedIconsMixin icons,
    bool showAnimeMangaPages,
  ) {
    return !showAnimeMangaPages
        ? switch (_routeNotifier.value) {
            CurrentRoute.booru => icons.booruIconController
                .reverse()
                .then((value) => icons.booruIconController.forward()),
            CurrentRoute.gallery => icons.galleryIconController
                .reverse()
                .then((value) => icons.galleryIconController.forward()),
            CurrentRoute.manga => icons.moreIconController
                .reverse()
                .then((value) => icons.moreIconController.forward()),
            CurrentRoute() => Future.value(),
          }
        : switch (_routeNotifier.value) {
            CurrentRoute.booru => icons.booruIconController
                .reverse()
                .then((value) => icons.booruIconController.forward()),
            CurrentRoute.gallery => icons.galleryIconController
                .reverse()
                .then((value) => icons.galleryIconController.forward()),
            CurrentRoute.manga => icons.favoritesIconController
                .reverse()
                .then((value) => icons.favoritesIconController.forward()),
            CurrentRoute.anime => icons.animeIconController
                .forward()
                .then((value) => icons.animeIconController.value = 0),
            CurrentRoute.more => icons.moreIconController
                .reverse()
                .then((value) => icons.moreIconController.forward()),
          };
  }
}

class _CurrentPageWidget extends StatelessWidget {
  const _CurrentPageWidget({
    // super.key,
    required this.icons,
    required this.changePage,
    required this.callback,
    required this.showAnimeMangaPages,
  });

  final AnimatedIconsMixin icons;
  final ChangePageMixin changePage;

  final CallbackDescriptionNested? callback;

  final bool showAnimeMangaPages;

  @override
  Widget build(BuildContext context) {
    final galleryPage = changePage._galleryPageNotifier;
    final morePage = changePage._morePageNotifier;
    final booruPage = changePage._booruPageNotifier;

    if (callback != null) {
      return GalleryDirectories(
        nestedCallback: callback,
        procPop: (pop) =>
            changePage._procPop(galleryPage, morePage, icons, pop),
        db: DatabaseConnectionNotifier.of(context),
        l10n: AppLocalizations.of(context)!,
      );
    }

    return Animate(
      controller: icons.pageRiseAnimation,
      effects: [
        FadeEffect(
          delay: const Duration(milliseconds: 50),
          end: 1,
          begin: 0,
          duration: 220.ms,
          curve: Easing.emphasizedAccelerate,
        ),
        SlideEffect(
          delay: const Duration(milliseconds: 50),
          begin: const Offset(0, 0.25),
          end: Offset.zero,
          duration: 280.ms,
          curve: Easing.standard,
        ),
      ],
      child: Animate(
        target: 0,
        effects: [
          FadeEffect(duration: 50.ms, begin: 1, end: 0),
          const ThenEffect(delay: Duration(milliseconds: 50)),
        ],
        controller: icons.pageFadeAnimation,
        child: showAnimeMangaPages
            ? switch (changePage._routeNotifier.value) {
                CurrentRoute.booru => _NavigatorShell(
                    navigatorKey: changePage.mainKey,
                    child: BooruPage(
                      pagingRegistry: changePage.pagingRegistry,
                      procPop: (pop) =>
                          changePage._procPopA(booruPage, icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                CurrentRoute.gallery => _NavigatorShell(
                    navigatorKey: changePage.galleryKey,
                    child: GalleryDirectories(
                      procPop: (pop) => changePage._procPop(
                        galleryPage,
                        morePage,
                        icons,
                        pop,
                      ),
                      db: DatabaseConnectionNotifier.of(context),
                      l10n: AppLocalizations.of(context)!,
                    ),
                  ),
                CurrentRoute.manga => _NavigatorShell(
                    navigatorKey: changePage.mangaKey,
                    child: MangaPage(
                      procPop: (pop) => changePage._procPop(
                        galleryPage,
                        morePage,
                        icons,
                        pop,
                      ),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                CurrentRoute.anime => AnimePage(
                    procPop: (pop) =>
                        changePage._procPop(galleryPage, morePage, icons, pop),
                    db: DatabaseConnectionNotifier.of(context),
                  ),
                CurrentRoute.more => _NavigatorShell(
                    navigatorKey: changePage.moreKey,
                    child: MorePage(
                      popScope: (pop) => changePage._procPop(
                        galleryPage,
                        morePage,
                        icons,
                        pop,
                      ),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
              }
            : switch (changePage._routeNotifier.value) {
                CurrentRoute.booru => _NavigatorShell(
                    navigatorKey: changePage.mainKey,
                    child: BooruPage(
                      pagingRegistry: changePage.pagingRegistry,
                      procPop: (pop) =>
                          changePage._procPopA(booruPage, icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                CurrentRoute.gallery => _NavigatorShell(
                    navigatorKey: changePage.galleryKey,
                    child: GalleryDirectories(
                      procPop: (pop) => changePage._procPop(
                        galleryPage,
                        morePage,
                        icons,
                        pop,
                      ),
                      db: DatabaseConnectionNotifier.of(context),
                      l10n: AppLocalizations.of(context)!,
                    ),
                  ),
                CurrentRoute() => _NavigatorShell(
                    navigatorKey: changePage.moreKey,
                    child: MorePage(
                      popScope: (pop) => changePage._procPop(
                        galleryPage,
                        morePage,
                        icons,
                        pop,
                      ),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
              },
      ),
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

  void dispose() {
    for (final e in _map.entries) {
      e.value.dispose();
    }
  }

  void clear() {
    _map.clear();
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

class _SelectedMorePage extends InheritedNotifier<ValueNotifier<MoreSubPage>> {
  const _SelectedMorePage({
    required ValueNotifier<MoreSubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
