// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

mixin _ChangePageMixin on State<Home> {
  // late final Isar mainGrid;

  final pagingRegistry = PagingStateRegistry();

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final moreKey = GlobalKey<NavigatorState>();
  final mangaKey = GlobalKey<NavigatorState>();

  int currentRoute = 0;

  String? restoreBookmarksPage;

  void _procPopAll(_AnimatedIconsMixin icons, bool _) {
    final f = mainKey.currentState?.maybePop();
    if (widget.callback != null) {
      f?.then((value) {
        if (!value) {
          Navigator.of(context);
        }
      });
    }

    galleryKey.currentState?.maybePop();
    moreKey.currentState?.maybePop().then((value) {
      if (!value) {
        _procPop(icons, false);
      }
    });
    mangaKey.currentState?.maybePop();
  }

  void initChangePage(_AnimatedIconsMixin icons, SettingsData settings) {
    // mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);
  }

  void disposeChangePage() {
    if (!themeIsChanging) {
      // mainGrid.close().then((value) => restartOver());
      pagingRegistry.dispose();
    } else {
      themeChangeOver();
    }
  }

  void _switchPage(
    _AnimatedIconsMixin icons,
    int to,
    bool showAnimeMangaPages,
  ) {
    if (to == currentRoute) {
      return;
    }

    if (to == kBooruPageRoute) {
      restartOver();
    } else {
      restartStart();
    }

    icons.pageRiseAnimation.reset();

    icons.pageFadeAnimation.animateTo(1).then((value) {
      currentRoute = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      _animateIcons(icons, showAnimeMangaPages);

      icons.pageRiseAnimation.forward();
    });
  }

  void _procPop(_AnimatedIconsMixin icons, bool pop) {
    if (!pop) {
      _switchPage(
        icons,
        kBooruPageRoute,
        SettingsService.db().current.showAnimeMangaPages,
      );
    }
  }

  void _procPopA(_AnimatedIconsMixin icons, bool pop) {
    if (!pop) {
      final showAnimeMangaPages =
          SettingsService.db().current.showAnimeMangaPages;

      _switchPage(
        icons,
        showAnimeMangaPages ? kMangaPageRoute : kGalleryPageRoute,
        showAnimeMangaPages,
      );
    }
  }

  Future<void> _animateIcons(
    _AnimatedIconsMixin icons,
    bool showAnimeMangaPages,
  ) {
    return !showAnimeMangaPages
        ? switch (currentRoute) {
            kBooruPageRoute => icons.booruIconController
                .reverse()
                .then((value) => icons.booruIconController.forward()),
            kGalleryPageRoute => icons.galleryIconController
                .reverse()
                .then((value) => icons.galleryIconController.forward()),
            int() => Future.value(),
          }
        : switch (currentRoute) {
            kBooruPageRoute => icons.booruIconController
                .reverse()
                .then((value) => icons.booruIconController.forward()),
            kGalleryPageRoute => icons.galleryIconController
                .reverse()
                .then((value) => icons.galleryIconController.forward()),
            kMangaPageRoute => icons.favoritesIconController
                .reverse()
                .then((value) => icons.favoritesIconController.forward()),
            kAnimePageRoute => icons.animeIconController
                .forward()
                .then((value) => icons.animeIconController.value = 0),
            int() => Future.value(),
          };
  }

  Widget _currentPage(
    BuildContext context,
    _AnimatedIconsMixin icons,
    bool showAnimeMangaPages,
  ) {
    if (widget.callback != null) {
      return GalleryDirectories(
        nestedCallback: widget.callback,
        procPop: (pop) => _procPop(icons, pop),
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
          begin: const Offset(-0.35, 0.15),
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
            ? switch (currentRoute) {
                kBooruPageRoute => _NavigatorShell(
                    navigatorKey: mainKey,
                    child: BooruPage(
                      pagingRegistry: pagingRegistry,
                      procPop: (pop) => _procPopA(icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                kGalleryPageRoute => _NavigatorShell(
                    navigatorKey: galleryKey,
                    child: GalleryDirectories(
                      procPop: (pop) => _procPop(icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                      l10n: AppLocalizations.of(context)!,
                    ),
                  ),
                kMangaPageRoute => _NavigatorShell(
                    navigatorKey: mangaKey,
                    child: MangaPage(
                      procPop: (pop) => _procPop(icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                kAnimePageRoute => AnimePage(
                    procPop: (pop) => _procPop(icons, pop),
                    db: DatabaseConnectionNotifier.of(context),
                  ),
                kMorePageRoute => _NavigatorShell(
                    navigatorKey: moreKey,
                    child: MorePage(
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                int() => throw "unimpl",
              }
            : switch (currentRoute) {
                kBooruPageRoute => _NavigatorShell(
                    navigatorKey: mainKey,
                    child: BooruPage(
                      pagingRegistry: pagingRegistry,
                      procPop: (pop) => _procPopA(icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
                kGalleryPageRoute => _NavigatorShell(
                    navigatorKey: galleryKey,
                    child: GalleryDirectories(
                      procPop: (pop) => _procPop(icons, pop),
                      db: DatabaseConnectionNotifier.of(context),
                      l10n: AppLocalizations.of(context)!,
                    ),
                  ),
                int() => _NavigatorShell(
                    navigatorKey: moreKey,
                    child: MorePage(
                      db: DatabaseConnectionNotifier.of(context),
                    ),
                  ),
              },
      ),
    );
  }

  static const int kBooruPageRoute = 0;
  static const int kGalleryPageRoute = 1;
  static const int kMangaPageRoute = 2;
  static const int kAnimePageRoute = 3;
  static const int kMorePageRoute = 4;
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
