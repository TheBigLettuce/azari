// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../../../pages/home.dart';

class _BooruIcon extends StatelessWidget {
  final bool isSelected;
  final AnimationController controller;
  final MenuController menuController;

  const _BooruIcon({
    required this.controller,
    required this.isSelected,
    required this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: Animate(
        autoPlay: true,
        controller: controller,
        effects: const [ShakeEffect(curve: Easing.standardAccelerate)],
        child: MenuAnchor(
          consumeOutsideTap: true,
          alignmentOffset: const Offset(8, 8),
          controller: menuController,
          menuChildren: Booru.values
              .map((e) => ListTile(
                    title: Text(e.string),
                    onTap: () {
                      selectBooru(context, Settings.fromDb(), e);
                    },
                  ))
              .toList(),
          child: GestureDetector(
            onLongPress: () {
              menuController.open();
            },
            child: Icon(
              Icons.image,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ),
      label: Settings.fromDb().selectedBooru.string,
    );
  }
}
