// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "home.dart";

mixin AnimatedIconsMixin on State<Home>, TickerProviderStateMixin<Home> {
  late final AnimationController pageFadeAnimation;

  late final AnimationController homeIconController;
  late final AnimationController searchIconController;
  late final AnimationController discoverIconController;
  late final AnimationController galleryIconController;

  @override
  void initState() {
    super.initState();

    pageFadeAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    homeIconController = AnimationController(vsync: this);
    galleryIconController = AnimationController(vsync: this);
    searchIconController = AnimationController(vsync: this);
    discoverIconController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    pageFadeAnimation.dispose();

    homeIconController.dispose();
    galleryIconController.dispose();
    searchIconController.dispose();
    discoverIconController.dispose();

    super.dispose();
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
