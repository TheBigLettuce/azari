// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

enum NavigationDestinations {
  booru,
  gallery,
  manga,
  anime,
  more;

  Widget icon(
    bool showAnimeMangaPages,
    int currentRoute,
    AnimatedIconsMixin mixin,
  ) =>
      switch (this) {
        NavigationDestinations.booru => BooruDestinationIcon(
            isSelected: currentRoute == ChangePageMixin.kBooruPageRoute,
            controller: mixin.booruIconController,
          ),
        NavigationDestinations.gallery => GalleryDestinationIcon(
            isSelected: currentRoute == ChangePageMixin.kGalleryPageRoute,
            controller: mixin.galleryIconController,
          ),
        NavigationDestinations.manga => MangaDestinationIcon(
            isSelected: currentRoute == ChangePageMixin.kMangaPageRoute,
            controller: mixin.favoritesIconController,
          ),
        NavigationDestinations.anime => AnimeDestinationIcon(
            isSelected: currentRoute == ChangePageMixin.kAnimePageRoute,
            controller: mixin.animeIconController,
          ),
        NavigationDestinations.more => MoreDestinationIcon(
            isSelected: currentRoute ==
                (showAnimeMangaPages
                    ? ChangePageMixin.kMorePageRoute
                    : ChangePageMixin.kMangaPageRoute),
          ),
      };

  String label(BuildContext context, AppLocalizations l10n, Booru booru) =>
      switch (this) {
        NavigationDestinations.booru =>
          _booruDestinationLabel(context, l10n, booru.string),
        NavigationDestinations.gallery =>
          GallerySubPage.of(context).translatedString(l10n),
        NavigationDestinations.manga => l10n.mangaPage,
        NavigationDestinations.anime => l10n.animePage,
        NavigationDestinations.more =>
          MoreSubPage.of(context).translatedString(l10n),
      };
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

mixin AnimatedIconsMixin on State<Home> {
  late final AnimationController controllerNavBar;
  late final AnimationController selectionBarController;
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
    controllerNavBar = AnimationController(
      vsync: ticker,
      duration: const Duration(milliseconds: 200),
    );
    selectionBarController = AnimationController(vsync: ticker);
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
    selectionBarController.dispose();
    controllerNavBar.dispose();
    pageFadeAnimation.dispose();
    pageRiseAnimation.dispose();

    booruIconController.dispose();
    galleryIconController.dispose();
    favoritesIconController.dispose();
    animeIconController.dispose();
  }

  List<NavigationRailDestination> railIcons(
    int currentRoute,
    Booru selectedBooru,
    bool showAnimeMangaPages,
  ) {
    final l10n = AppLocalizations.of(context)!;

    NavigationRailDestination item(NavigationDestinations e) =>
        NavigationRailDestination(
          icon: e.icon(showAnimeMangaPages, currentRoute, this),
          label: Builder(
            builder: (context) {
              return Text(e.label(context, l10n, selectedBooru));
            },
          ),
        );

    return (!showAnimeMangaPages
            ? const [
                NavigationDestinations.booru,
                NavigationDestinations.gallery,
                NavigationDestinations.more,
              ]
            : NavigationDestinations.values)
        .map(item)
        .toList();
  }

  List<Widget> icons(
    BuildContext context,
    int currentRoute,
    Booru selectedBooru,
    bool showAnimeMangaPages,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return (!showAnimeMangaPages
            ? const [
                NavigationDestinations.booru,
                NavigationDestinations.gallery,
                NavigationDestinations.more,
              ]
            : NavigationDestinations.values)
        .map(
          (e) => Builder(
            builder: (context) {
              return NavigationDestination(
                icon: e.icon(showAnimeMangaPages, currentRoute, this),
                label: e.label(context, l10n, selectedBooru),
              );
            },
          ),
        )
        .toList();
  }
}

class MoreDestinationIcon extends StatelessWidget {
  const MoreDestinationIcon({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final selectedMorePage = MoreSubPage.of(context);
    final theme = Theme.of(context);

    return Icon(
      isSelected ? selectedMorePage.selectedIcon : selectedMorePage.icon,
      color: isSelected ? theme.colorScheme.primary : null,
    );
  }
}
