// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/more/settings/settings_label.dart';

class MenuWrapper extends StatefulWidget {
  final String title;
  final List<PopupMenuItem> items;
  final Widget child;

  static List<PopupMenuItem> menuItems(String title,
          [List<PopupMenuItem>? items]) =>
      [
        PopupMenuItem(
          padding: const EdgeInsets.only(left: 16, right: 16),
          enabled: false,
          child: MenuLabel(
            title: title,
          ),
        ),
        if (items != null) ...items,
        PopupMenuItem(
          onTap: () {
            Clipboard.setData(ClipboardData(text: title));
          },
          child: const Text("Copy"), // TODO: change
        )
      ];

  const MenuWrapper({
    super.key,
    // required this.excluded,
    this.items = const [],
    required this.title,
    required this.child,
  });

  @override
  State<MenuWrapper> createState() => _MenuWrapperState();
}

class _MenuWrapperState extends State<MenuWrapper> {
  final controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        final RenderBox overlay = Navigator.of(context)
            .overlay!
            .context
            .findRenderObject()! as RenderBox;

        HapticFeedback.mediumImpact();

        showMenu(
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          shape: const Border(),
          popUpAnimationStyle: AnimationStyle(
            curve: Easing.standardAccelerate,
            reverseCurve: Easing.standardDecelerate,
            duration: const Duration(milliseconds: 280),
          ),
          shadowColor: Theme.of(context).colorScheme.background,
          surfaceTintColor: Theme.of(context).colorScheme.primary,
          constraints:
              const BoxConstraints(minWidth: 56 * 2.5, maxWidth: 56 * 2.5),
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromPoints(
              details.globalPosition + const Offset(0, 8),
              details.globalPosition + const Offset(((56 * 2.5) / 2) + 8, 0),
            ),
            Offset.zero & overlay.size,
          ),
          items: MenuWrapper.menuItems(widget.title, widget.items),
        );
      },
      child: widget.child,
    );
  }
}
