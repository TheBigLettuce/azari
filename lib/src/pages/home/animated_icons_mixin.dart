// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

mixin _AnimatedIconsMixin on State<Home> {
  late final AnimationController controllerNavBar;
  late final AnimationController pageFadeAnimation;
  late final AnimationController pageRiseAnimation;
  late final AnimationController booruIconController;
  late final AnimationController galleryIconController;
  late final AnimationController favoritesIconController;
  late final AnimationController animeIconController;

  void hide(bool hide) {
    if (hide) {
      controllerNavBar.animateTo(1);
    } else {
      controllerNavBar.animateBack(0);
    }
  }

  void initIcons(TickerProviderStateMixin ticker) {
    controllerNavBar = AnimationController(vsync: ticker);
    pageFadeAnimation = AnimationController(
      vsync: ticker,
      duration: const Duration(milliseconds: 200),
    );
    pageRiseAnimation = AnimationController(vsync: ticker);

    booruIconController = AnimationController(vsync: ticker);
    galleryIconController = AnimationController(vsync: ticker);
    favoritesIconController = AnimationController(vsync: ticker);
    animeIconController = AnimationController(vsync: ticker);
  }

  void disposeIcons() {
    controllerNavBar.dispose();
    pageFadeAnimation.dispose();
    pageRiseAnimation.dispose();

    booruIconController.dispose();
    galleryIconController.dispose();
    favoritesIconController.dispose();
    animeIconController.dispose();
  }

  List<Widget> icons(
    BuildContext context,
    int currentRoute,
    SettingsData settings,
    bool showAnimeMangaPages,
  ) =>
      [
        _BooruIcon(
          isSelected: currentRoute == _ChangePageMixin.kBooruPageRoute,
          controller: booruIconController,
          label: settings.selectedBooru.string,
        ),
        _GalleryIcon(
          isSelected: currentRoute == _ChangePageMixin.kGalleryPageRoute,
          controller: galleryIconController,
        ),
        if (showAnimeMangaPages)
          _MangaIcon(
            isSelected: currentRoute == _ChangePageMixin.kMangaPageRoute,
            controller: favoritesIconController,
          ),
        if (showAnimeMangaPages)
          _AnimeIcon(
            isSelected: currentRoute == _ChangePageMixin.kAnimePageRoute,
            controller: animeIconController,
          ),
        _MoreIcon(
          isSelected: showAnimeMangaPages
              ? currentRoute == _ChangePageMixin.kMorePageRoute
              : currentRoute == _ChangePageMixin.kMangaPageRoute,
        ),
      ];
}

class _MoreIcon extends StatelessWidget {
  const _MoreIcon({
    // super.key,
    required this.isSelected,
  });

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedMorePage = MoreSubPage.of(context);

    return NavigationDestination(
      icon: Icon(
        isSelected ? selectedMorePage.selectedIcon : selectedMorePage.icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      label: selectedMorePage.translatedString(l10n),
    );
  }
}
