// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../home.dart';

mixin _ChangePageMixin on State<Home> {
  late final Isar mainGrid;

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

  void initChangePage(_AnimatedIconsMixin icons, Settings settings) {
    mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);
  }

  void disposeChangePage() {
    if (!themeIsChanging) {
      mainGrid.close().then((value) => restartOver());
      pagingRegistry.dispose();
    } else {
      themeChangeOver();
    }
  }

  void _switchPage(_AnimatedIconsMixin icons, int to) {
    if (to == currentRoute) {
      return;
    }

    if (to == kBooruPageRoute) {
      restartOver();
    } else {
      restartStart();
    }

    icons.pageFadeAnimation.animateTo(1).then((value) {
      currentRoute = to;

      icons.pageFadeAnimation.reset();
      setState(() {});

      _animateIcons(icons);
    });
  }

  void _procPop(_AnimatedIconsMixin icons, bool pop) {
    if (!pop) {
      _switchPage(icons, kBooruPageRoute);
    }
  }

  void _procPopA(_AnimatedIconsMixin icons, bool pop) {
    if (!pop) {
      _switchPage(icons, kMangaPageRoute);
    }
  }

  void _popGallery(bool b) {
    final state = switch (currentRoute) {
      kBooruPageRoute => mainKey.currentState,
      kGalleryPageRoute => galleryKey.currentState,
      kMorePageRoute => moreKey.currentState,
      kMangaPageRoute => mangaKey.currentState,
      int() => null,
    };
    if (state == null) {
      return;
    }

    state.maybePop();
  }

  void _animateIcons(_AnimatedIconsMixin icons) {
    switch (currentRoute) {
      case kBooruPageRoute:
        icons.booruIconController
            .reverse()
            .then((value) => icons.booruIconController.forward());
      case kGalleryPageRoute:
        icons.galleryIconController
            .reverse()
            .then((value) => icons.galleryIconController.forward());
      case kMangaPageRoute:
        icons.favoritesIconController
            .reverse()
            .then((value) => icons.favoritesIconController.forward());
      case kAnimePageRoute:
        icons.animeIconController
            .forward()
            .then((value) => icons.animeIconController.value = 0);
    }
  }

  Widget _currentPage(BuildContext context, _AnimatedIconsMixin icons) {
    if (widget.callback != null) {
      return GalleryDirectories(
        nestedCallback: widget.callback,
        procPop: (pop) => _procPop(icons, pop),
      );
    }

    if (Settings.fromDb().buddhaMode) {
      return BooruPage(
        pagingRegistry: pagingRegistry,
        procPop: (pop) {},
      );
    }

    return Animate(
        target: 0,
        effects: [FadeEffect(duration: 50.ms, begin: 1, end: 0)],
        controller: icons.pageFadeAnimation,
        child: switch (currentRoute) {
          kBooruPageRoute => _NavigatorShell(
              navigatorKey: mainKey,
              child: BooruPage(
                pagingRegistry: pagingRegistry,
                procPop: (pop) => _procPopA(icons, pop),
              ),
            ),
          kGalleryPageRoute => _NavigatorShell(
              navigatorKey: galleryKey,
              child: GalleryDirectories(
                procPop: (pop) => _procPop(icons, pop),
              ),
            ),
          kMangaPageRoute => _NavigatorShell(
              navigatorKey: mangaKey,
              child: MangaPage(
                procPop: (pop) => _procPop(icons, pop),
              ),
            ),
          kAnimePageRoute => AnimePage(
              procPop: (pop) => _procPop(icons, pop),
            ),
          kMorePageRoute => _NavigatorShell(
              navigatorKey: moreKey,
              child: const MorePage(),
            ),
          int() => throw "unimpl",
        });
  }

  static const int kBooruPageRoute = 0;
  static const int kGalleryPageRoute = 1;
  static const int kMangaPageRoute = 2;
  static const int kAnimePageRoute = 3;
  static const int kMorePageRoute = 4;
}

class PagingStateRegistry {
  final Map<String, PagingEntry> _map = {};

  PagingEntry getOrRegister(String key, PagingEntry Function() prototype) {
    final e = _map[key];
    if (e != null) {
      return e;
    }

    _map[key] = prototype();

    return _map[key]!;
  }

  void remove(String key) {
    _map.remove(key)?.dispose();
  }

  void dispose() {
    for (final e in _map.entries) {
      e.value.dispose();
    }
  }
}

abstract class PagingEntry {
  double get offset;
  void setOffset(double o);

  int get page;
  void setPage(int p);

  void dispose();
}
