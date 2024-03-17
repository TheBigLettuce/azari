// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../home.dart';

mixin _ChangePageMixin on State<Home> {
  late final SelectionGlueState glueState;
  late final Isar mainGrid;

  final pagingRegistry = PagingStateRegistry();

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final moreKey = GlobalKey<NavigatorState>();
  final mangaKey = GlobalKey<NavigatorState>();

  int currentRoute = 0;

  String? restoreBookmarksPage;

  void initChangePage(_AnimatedIconsMixin icons, Settings settings) {
    mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);

    glueState = SelectionGlueState(
      hide: (hide) {
        if (Settings.fromDb().buddhaMode) {
          return;
        }

        if (hide) {
          icons.controllerNavBar.animateTo(1);
        } else {
          icons.controllerNavBar.animateBack(0);
        }
      },
    );
  }

  void disposeChangePage() {
    if (!themeIsChanging) {
      mainGrid.close().then((value) => restartOver());
      pagingRegistry.dispose();
    } else {
      themeChangeOver();
    }
  }

  bool keyboardVisible() => MediaQuery.viewInsetsOf(context).bottom != 0;

  SelectionGlue<T> _generateGlue<T extends Cell>() =>
      glueState.glue(keyboardVisible, setState, () => 80, true);

  SelectionGlue<T> _generateGlueB<T extends Cell>() =>
      glueState.glue(keyboardVisible, setState, () => 0, true);

  void _switchPage(_AnimatedIconsMixin icons, int to) {
    if (to == currentRoute) {
      return;
    }

    if (to == kBooruPageRoute) {
      restartOver();
    } else {
      restartStart();
    }

    icons.controller.animateTo(1).then((value) {
      currentRoute = to;

      icons.controller.reset();
      setState(() {});
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

  Widget _currentPage(
      BuildContext context, _AnimatedIconsMixin icons, EdgeInsets padding) {
    SelectionGlue<T> generateGluePadding<T extends Cell>() {
      return glueState.glue(
        keyboardVisible,
        setState,
        () => 80 + MediaQuery.viewPaddingOf(this.context).bottom.toInt(),
        true,
      );
    }

    SelectionGlue<T> generateGlueC<T extends Cell>() =>
        glueState.glue(keyboardVisible, setState, () => 80, false);

    if (widget.callback != null) {
      return WrapGridPage<SystemGalleryDirectory>(
        scaffoldKey: GlobalKey(),
        child: GalleryDirectories(
          viewPadding: padding,
          nestedCallback: widget.callback,
          procPop: (pop) => _procPop(icons, pop),
        ),
      );
    }

    if (Settings.fromDb().buddhaMode) {
      return GlueProvider<Post>(
        generate: generateGlueC,
        glue: generateGlueC(),
        child: BooruPage(
          pagingRegistry: pagingRegistry,
          generateGlue: generateGlueC,
          viewPadding: padding,
          procPop: (pop) {},
        ),
      );
    }

    _animateIcons(icons);

    return Animate(
        target: 0,
        effects: [FadeEffect(duration: 50.ms, begin: 1, end: 0)],
        controller: icons.controller,
        child: switch (currentRoute) {
          kBooruPageRoute => _NavigatorShell(
              navigatorKey: mainKey,
              pop: _popGallery,
              child: GlueProvider<Post>(
                generate: generateGluePadding,
                glue: _generateGlue(),
                child: BooruPage(
                  pagingRegistry: pagingRegistry,
                  generateGlue: generateGluePadding,
                  viewPadding: padding,
                  procPop: (pop) => _procPopA(icons, pop),
                ),
              ),
            ),
          kGalleryPageRoute => _NavigatorShell(
              navigatorKey: galleryKey,
              pop: _popGallery,
              child: GlueProvider<SystemGalleryDirectory>(
                generate: _generateGlue,
                glue: _generateGlue(),
                child: GalleryDirectories(
                  procPop: (pop) => _procPop(icons, pop),
                  viewPadding: padding,
                ),
              ),
            ),
          kMangaPageRoute => _NavigatorShell(
              navigatorKey: mangaKey,
              pop: _popGallery,
              child: GlueProvider<CompactMangaDataBase>(
                generate: _generateGlue,
                glue: _generateGlue(),
                child: MangaPage(
                  procPop: (pop) => _procPop(icons, pop),
                  viewPadding: padding,
                ),
              ),
            ),
          kAnimePageRoute => GlueProvider<AnimeEntry>(
              generate: _generateGlue,
              glue: _generateGlue(),
              child: AnimePage(
                procPop: (pop) => _procPop(icons, pop),
                viewPadding: padding,
              ),
            ),
          kMorePageRoute => _NavigatorShell(
              navigatorKey: moreKey,
              pop: _popGallery,
              child: PopScope(
                canPop: currentRoute == kBooruPageRoute,
                onPopInvoked: (pop) => _procPop(icons, pop),
                child: MorePage(
                  generateGlue: _generateGlueB,
                ).animate(),
              ),
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
