// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

class SearchDestinationIcon extends StatelessWidget {
  const SearchDestinationIcon({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isSelected = CurrentRoute.of(context) == CurrentRoute.search;

    return Animate(
      autoPlay: true,
      controller: controller,
      effects: const [ShakeEffect(curve: Easing.standardAccelerate)],
      child: Icon(
        isSelected ? Icons.search_rounded : Icons.search_outlined,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
    );
  }
}
