// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

mixin AnimatedIconsMixin on State<Home> {
  late final AnimationController controllerNavBar;

  late final AnimationController selectionBarController;

  late final AnimationController pageFadeAnimation;

  late final AnimationController booruIconController;
  late final AnimationController galleryIconController;
  late final AnimationController animeIconController;
  late final AnimationController settingsIconController;

  void hideNavBar(bool hide) {
    if (hide) {
      controllerNavBar.forward();
    } else {
      if (selectionBarController.value == 0) {
        controllerNavBar.reverse();
      }
    }
  }

  Future<void> driveAnimation({required bool forward, required bool rail}) {
    if (forward) {
      return controllerNavBar.forward().then((_) {
        final Future<void> f_ = selectionBarController.animateTo(1);

        if (rail) {
          return f_;
        }
      });
    } else {
      return selectionBarController.animateBack(0).then((_) {
        final Future<void> f_ = controllerNavBar.reverse();

        if (rail) {
          return f_;
        }
      });
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

    booruIconController = AnimationController(vsync: ticker);
    galleryIconController = AnimationController(vsync: ticker);
    animeIconController = AnimationController(vsync: ticker);
    settingsIconController = AnimationController(vsync: ticker);
  }

  void disposeIcons() {
    selectionBarController.dispose();
    controllerNavBar.dispose();
    pageFadeAnimation.dispose();

    booruIconController.dispose();
    galleryIconController.dispose();
    animeIconController.dispose();
    settingsIconController.dispose();
  }

  List<NavigationRailDestination> railIcons(Booru selectedBooru) {
    final l10n = AppLocalizations.of(context)!;

    NavigationRailDestination item(CurrentRoute e) => NavigationRailDestination(
          icon: e.icon(this),
          label: Builder(
            builder: (context) {
              return Text(e.label(context, l10n, selectedBooru));
            },
          ),
        );

    return CurrentRoute.values.map(item).toList();
  }

  List<Widget> icons(BuildContext context, Booru selectedBooru) {
    final l10n = AppLocalizations.of(context)!;

    return CurrentRoute.values
        .map(
          (e) => Builder(
            builder: (context) {
              return NavigationDestination(
                icon: e.icon(this),
                label: e.label(context, l10n, selectedBooru),
              );
            },
          ),
        )
        .toList();
  }
}
