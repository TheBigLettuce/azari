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

  final mainKey = GlobalKey<NavigatorState>();
  final galleryKey = GlobalKey<NavigatorState>();
  final moreKey = GlobalKey<NavigatorState>();

  int currentRoute = 0;

  String? restoreBookmarksPage;

  void initChangePage(_AnimatedIconsMixin icons, Settings settings) {
    mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);

    glueState = SelectionGlueState(
      hide: (hide) {
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
      _switchPage(icons, kAnimePageRoute);
    }
  }

  void _popGallery(bool b) {
    final state = switch (currentRoute) {
      kBooruPageRoute => mainKey.currentState,
      kGalleryPageRoute => galleryKey.currentState,
      kMorePageRoute => moreKey.currentState,
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
      case kFavoriteBooruPageRoute:
        icons.favoritesIconController
            .reverse()
            .then((value) => icons.favoritesIconController.forward());
      case kAnimePageRoute:
        icons.animeIconController
            .forward()
            .then((value) => icons.animeIconController.value = 0);
    }
  }

  Widget _currentPage(BuildContext context, _AnimatedIconsMixin icons,
      _MainGridRefreshingInterfaceMixin refresh, EdgeInsets padding) {
    SelectionGlue<T> generateGluePadding<T extends Cell>() {
      return glueState.glue(
        keyboardVisible,
        setState,
        () => 80 + MediaQuery.viewPaddingOf(this.context).bottom.toInt(),
        true,
      );
    }

    if (widget.callback != null) {
      if (currentRoute == kBooruPageRoute) {
        return _NavigatorShell(
          pop: _popGallery,
          navigatorKey: mainKey,
          child: GlueProvider<SystemGalleryDirectory>(
            generate: _generateGlue,
            glue: _generateGlue(),
            child: GalleryDirectories(
              viewPadding: padding,
              nestedCallback: widget.callback,
              procPop: (pop) => _procPop(icons, pop),
            ),
          ),
        );
      } else {
        return NotesPage(
          callback: widget.callback,
          bottomPadding: 80,
        );
      }
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
                child: MainBooruGrid(
                  restoreSelectedPage: restoreBookmarksPage,
                  saveSelectedPage: (e) {
                    restoreBookmarksPage = e;
                  },
                  generateGlue: generateGluePadding,
                  mainGrid: mainGrid,
                  viewPadding: padding,
                  refreshingInterface: refresh.refreshInterface,
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
          kFavoriteBooruPageRoute => GlueProvider<FavoriteBooru>(
              generate: _generateGlue,
              glue: _generateGlue(),
              child: FavoriteBooruPage(
                procPop: (pop) => _procPop(icons, pop),
                viewPadding: padding,
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
                  tagManager:
                      TagManager.fromEnum(Settings.fromDb().selectedBooru),
                  api: BooruAPIState.fromEnum(Settings.fromDb().selectedBooru,
                      page: null),
                ).animate(),
              ),
            ),
          int() => throw "unimpl",
        });
  }

  static const int kBooruPageRoute = 0;
  static const int kGalleryPageRoute = 1;
  static const int kFavoriteBooruPageRoute = 2;
  static const int kAnimePageRoute = 3;
  static const int kMorePageRoute = 4;
}
