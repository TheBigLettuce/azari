// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../home.dart';

mixin _AnimatedIconsMixin on State<Home> {
  late final AnimationController controllerNavBar;
  late final AnimationController pageFadeAnimation;
  late final AnimationController booruIconController;
  late final AnimationController galleryIconController;
  late final AnimationController favoritesIconController;
  late final AnimationController animeIconController;

  void hide(bool hide) {
    if (Settings.fromDb().buddhaMode) {
      return;
    }

    if (hide) {
      controllerNavBar.animateTo(1);
    } else {
      controllerNavBar.animateBack(0);
    }
  }

  void initIcons(TickerProviderStateMixin ticker) {
    controllerNavBar = AnimationController(vsync: ticker);
    pageFadeAnimation = AnimationController(
        vsync: ticker, duration: const Duration(milliseconds: 200));
    booruIconController = AnimationController(vsync: ticker);

    galleryIconController = AnimationController(vsync: ticker);
    favoritesIconController = AnimationController(vsync: ticker);
    animeIconController = AnimationController(vsync: ticker);
  }

  void disposeIcons() {
    controllerNavBar.dispose();
    pageFadeAnimation.dispose();
    booruIconController.dispose();

    galleryIconController.dispose();
    favoritesIconController.dispose();
    animeIconController.dispose();
  }

  List<Widget> icons(BuildContext context, int currentRoute) => [
        _BooruIcon(
          isSelected: currentRoute == _ChangePageMixin.kBooruPageRoute,
          controller: booruIconController,
        ),
        _GalleryIcon(
          isSelected: currentRoute == _ChangePageMixin.kGalleryPageRoute,
          controller: galleryIconController,
        ),
        _MangaIcon(
          isSelected: currentRoute == _ChangePageMixin.kMangaPageRoute,
          controller: favoritesIconController,
        ),
        _AnimeIcon(
          isSelected: currentRoute == _ChangePageMixin.kAnimePageRoute,
          controller: animeIconController,
        ),
        NavigationDestination(
          icon: Icon(
            Icons.more_horiz,
            color: currentRoute == _ChangePageMixin.kMorePageRoute
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          label: AppLocalizations.of(context)!.more,
        ),
      ];

  List<Widget> iconsGalleryNotes(BuildContext context) => [
        NavigationDestination(
          icon: const Icon(Icons.collections),
          label: AppLocalizations.of(context)!.galleryLabel,
        ),
        NavigationDestination(
            icon: const Icon(Icons.sticky_note_2),
            label: AppLocalizations.of(context)!.notesPage),
      ];
}
