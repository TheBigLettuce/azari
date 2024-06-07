// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../../home.dart";

class _BooruIcon extends StatelessWidget {
  const _BooruIcon({
    required this.controller,
    required this.isSelected,
    required this.label,
  });
  final bool isSelected;
  final AnimationController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedBooruPage = BooruSubPage.of(context);

    return NavigationDestination(
      icon: Animate(
        autoPlay: true,
        controller: controller,
        effects: const [ShakeEffect(curve: Easing.standardAccelerate)],
        child: Icon(
          isSelected ? selectedBooruPage.selectedIcon : selectedBooruPage.icon,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      label: selectedBooruPage == BooruSubPage.booru
          ? label
          : selectedBooruPage.translatedString(l10n),
    );
  }
}
