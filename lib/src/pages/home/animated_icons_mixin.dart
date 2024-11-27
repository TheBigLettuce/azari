// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

mixin AnimatedIconsMixin {
  late final AnimationController controllerNavBar;

  late final AnimationController selectionBarController;

  late final AnimationController pageFadeAnimation;

  late final AnimationController homeIconController;
  late final AnimationController searchIconController;
  late final AnimationController discoverIconController;
  late final AnimationController galleryIconController;

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

    homeIconController = AnimationController(vsync: ticker);
    galleryIconController = AnimationController(vsync: ticker);
    searchIconController = AnimationController(vsync: ticker);
    discoverIconController = AnimationController(vsync: ticker);
  }

  void disposeIcons() {
    selectionBarController.dispose();
    controllerNavBar.dispose();
    pageFadeAnimation.dispose();

    homeIconController.dispose();
    galleryIconController.dispose();
    searchIconController.dispose();
    discoverIconController.dispose();
  }

  List<NavigationRailDestination> railIcons(
    AppLocalizations l10n,
    Booru selectedBooru,
  ) {
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

  List<Widget> icons(
    BuildContext context,
    Booru selectedBooru,
    void Function(BuildContext, CurrentRoute) onDestinationSelected,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return CurrentRoute.values
        .map(
          (e) => Builder(
            builder: (context) {
              return _NavigationDestination(
                icon: e.icon(this),
                label: e.label(context, l10n, selectedBooru),
                onSelected: () => onDestinationSelected(context, e),
              );
            },
          ),
        )
        .toList();
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    // super.key,
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final String label;
  final Widget icon;

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final currentRoute = CurrentRoute.of(context);

    return Center(
      child: SizedBox.square(
        dimension: 38,
        child: InkWell(
          onLongPress: currentRoute == CurrentRoute.home
              ? () {
                  Scaffold.maybeOf(context)?.openDrawer();
                }
              : null,
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          onTap: onSelected,
          child: icon,
        ),
      ),
    );
  }
}
