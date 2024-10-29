// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

enum CurrentRoute {
  booru,
  gallery
  // anime
  ;
  // downloads,
  // settings;

  factory CurrentRoute.fromIndex(int i) => switch (i) {
        0 => booru,
        1 => gallery,
        // 2 => anime,
        // 3 => downloads,
        // 3 => settings,
        int() => throw "no route",
      };

  Widget icon(AnimatedIconsMixin mixin) => switch (this) {
        booru => BooruDestinationIcon(
            controller: mixin.booruIconController,
          ),
        gallery => GalleryDestinationIcon(
            controller: mixin.galleryIconController,
          ),
        // anime => AnimeDestinationIcon(
        //     controller: mixin.animeIconController,
        //   ),
        // downloads => Icon(Icons.download_rounded),
        // settings => SettingsDestinationIcon(
        //     controller: mixin.downloadsIconController,
        //   ),
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
        gallery => GallerySubPage.of(context).translatedString(l10n),
        // anime => l10n.animePage,
        // downloads => l10n.downloadsPageName,
        // settings => SettingsSubPage.of(context).translatedString(l10n),
      };

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
  ),
  downloads(
    icon: Icons.download_outlined,
    selectedIcon: Icons.download_rounded,
  ),
  visited(
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule_rounded,
  ),
  anime(
    icon: Icons.video_collection_outlined,
    selectedIcon: Icons.video_collection_rounded,
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
        4 => downloads,
        5 => visited,
        6 => anime,
        int() => booru,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        booru => l10n.booruLabel,
        favorites => l10n.favoritesLabel,
        bookmarks => l10n.bookmarksPageName,
        hiddenPosts => l10n.hiddenPostsPageName,
        downloads => l10n.downloadsPageName,
        visited => l10n.visitedPage,
        anime => l10n.animePage,
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

// enum SettingsSubPage {
//   settings(
//     icon: Icons.account_circle_outlined,
//     selectedIcon: Icons.account_circle_rounded,
//   ),
//   dashboard(
//     icon: Icons.dashboard_outlined,
//     selectedIcon: Icons.dashboard_rounded,
//   );

//   const SettingsSubPage({
//     required this.icon,
//     required this.selectedIcon,
//   });

//   factory SettingsSubPage.fromIdx(int idx) => switch (idx) {
//         0 => settings,
//         1 => dashboard,
//         int() => settings,
//       };

//   final IconData icon;
//   final IconData selectedIcon;

//   String translatedString(AppLocalizations l10n) => switch (this) {
//         SettingsSubPage.settings => l10n.settingsLabel,
//         SettingsSubPage.dashboard => l10n.dashboardPage,
//       };

//   static Widget wrap(ValueNotifier<SettingsSubPage> notifier, Widget child) =>
//       _SelectedMorePage(notifier: notifier, child: child);

//   static SettingsSubPage of(BuildContext context) {
//     final widget =
//         context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

//     return widget!.notifier!.value;
//   }

//   static void selectOf(BuildContext context, SettingsSubPage page) {
//     GlueProvider.generateOf(context)().updateCount(0);

//     final widget =
//         context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

//     widget!.notifier!.value = page;
//   }
// }

mixin ChangePageMixin on State<Home> {
  final pagingRegistry = PagingStateRegistry();

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final settingsKey = GlobalKey<NavigatorState>();

  final _routeNotifier = ValueNotifier<CurrentRoute>(CurrentRoute.booru);

  final _booruPageNotifier = ValueNotifier<BooruSubPage>(BooruSubPage.booru);
  final _galleryPageNotifier =
      ValueNotifier<GallerySubPage>(GallerySubPage.gallery);
  // final _settingsPageNotifier =
  // ValueNotifier<SettingsSubPage>(SettingsSubPage.settings);

  String? restoreBookmarksPage;

  void _procPopAll(
    ValueNotifier<GallerySubPage> galleryPage,
    // ValueNotifier<SettingsSubPage> morePage,
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
    settingsKey.currentState?.maybePop().then((value) {
      if (!value) {
        _procPop(galleryPage, icons, false);
      }
    });
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

  void switchPage(AnimatedIconsMixin icons, CurrentRoute to) {
    if (to == _routeNotifier.value) {
      return;
    }

    if (to == CurrentRoute.booru) {
      restartOver();
    } else {
      restartStart();
    }

    // icons.pageRiseAnimation.reset();

    icons.pageFadeAnimation.animateTo(1).then((value) {
      _routeNotifier.value = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      animateIcons(icons);

      // icons.pageRiseAnimation.forward();
    });
  }

  void _procPop(
    ValueNotifier<GallerySubPage> galleryPage,
    // ValueNotifier<SettingsSubPage> morePage,
    AnimatedIconsMixin icons,
    bool pop,
  ) {
    if (!pop) {
      if (_routeNotifier.value == CurrentRoute.gallery &&
          galleryPage.value != GallerySubPage.gallery) {
        galleryPage.value = GallerySubPage.gallery;
        animateIcons(icons);
      }
      // else if (_routeNotifier.value == CurrentRoute.gallery &&
      //     morePage.value != SettingsSubPage.settings) {
      //   morePage.value = SettingsSubPage.settings;
      //   animateIcons(icons);
      // }
      else {
        switchPage(icons, CurrentRoute.booru);
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
        animateIcons(icons);
      } else {
        switchPage(icons, CurrentRoute.gallery);
      }
    }
  }

  Future<void> animateIcons(AnimatedIconsMixin icons) {
    return switch (_routeNotifier.value) {
      CurrentRoute.booru => icons.booruIconController
          .reverse()
          .then((value) => icons.booruIconController.forward()),
      CurrentRoute.gallery => icons.galleryIconController
          .reverse()
          .then((value) => icons.galleryIconController.forward()),
      // CurrentRoute.anime => icons.animeIconController
      //     .reverse()
      //     .then((value) => icons.animeIconController.forward()),
      // CurrentRoute.settings => icons.downloadsIconController
      //     .reverse()
      //     .then((value) => icons.downloadsIconController.forward()),
      // CurrentRoute.downloads => Future.value(),
    };
  }
}

class _CurrentPageWidget extends StatelessWidget {
  const _CurrentPageWidget({
    // super.key,
    required this.icons,
    required this.changePage,
    required this.callback,
  });

  final AnimatedIconsMixin icons;
  final ChangePageMixin changePage;

  final CallbackDescriptionNested? callback;

  @override
  Widget build(BuildContext context) {
    final galleryPage = changePage._galleryPageNotifier;
    // final morePage = changePage._settingsPageNotifier;
    final booruPage = changePage._booruPageNotifier;

    if (callback != null) {
      return GalleryDirectories(
        nestedCallback: callback,
        procPop: (pop) => changePage._procPop(galleryPage, icons, pop),
        db: DatabaseConnectionNotifier.of(context),
        l10n: AppLocalizations.of(context)!,
      );
    }

    return Animate(
      target: 0,
      effects: [
        FadeEffect(duration: 50.ms, begin: 1, end: 0),
        const ThenEffect(delay: Duration(milliseconds: 50)),
      ],
      controller: icons.pageFadeAnimation,
      child: switch (changePage._routeNotifier.value) {
        CurrentRoute.booru => _NavigatorShell(
            navigatorKey: changePage.mainKey,
            child: BooruPage(
              pagingRegistry: changePage.pagingRegistry,
              procPop: (pop) => changePage._procPopA(booruPage, icons, pop),
              db: DatabaseConnectionNotifier.of(context),
            ),
          ),
        CurrentRoute.gallery => _NavigatorShell(
            navigatorKey: changePage.galleryKey,
            child: GalleryDirectories(
              procPop: (pop) => changePage._procPop(
                galleryPage,
                icons,
                pop,
              ),
              db: DatabaseConnectionNotifier.of(context),
              l10n: AppLocalizations.of(context)!,
            ),
          ),
        // CurrentRoute.anime => AnimePage(
        //     procPop: (pop) => changePage._procPop(galleryPage, icons, pop),
        //     db: DatabaseConnectionNotifier.of(context),
        //   ),
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

// class _SelectedMorePage
//     extends InheritedNotifier<ValueNotifier<SettingsSubPage>> {
//   const _SelectedMorePage({
//     required ValueNotifier<SettingsSubPage> notifier,
//     required super.child,
//   }) : super(notifier: notifier);
// }
