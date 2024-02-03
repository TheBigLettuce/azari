// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../../home.dart';

class _FavoritesIcon extends StatelessWidget {
  final bool isSelected;
  final AnimationController controller;
  final int count;

  const _FavoritesIcon({
    required this.controller,
    required this.isSelected,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: Badge.count(
        alignment: Alignment.topRight,
        count: count,
        child: Animate(
          controller: controller,
          autoPlay: false,
          target: 1,
          effects: [
            ShimmerEffect(angle: pi / -5, duration: 440.ms, colors: [
              Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(isSelected ? 1 : 0),
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
              Colors.red
              // Theme.of(context).colorScheme.primary,
            ])
          ],
          child: Icon(
            Icons.favorite,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
      label: AppLocalizations.of(context)!.favoritesLabel,
    );
  }
}
