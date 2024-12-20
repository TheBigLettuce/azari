// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/typedefs.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class MenuWrapper extends StatefulWidget {
  const MenuWrapper({
    super.key,
    this.items = const [],
    required this.title,
    this.includeCopy = true,
    required this.child,
  });

  final bool includeCopy;

  final String title;
  final List<PopupMenuItem<void>> items;

  final Widget child;

  static List<PopupMenuItem<void>> menuItems(
    BuildContext context,
    String title,
    bool includeCopy, [
    List<PopupMenuItem<void>>? items,
  ]) =>
      [
        PopupMenuItem(
          padding: const EdgeInsets.only(left: 16, right: 16),
          enabled: false,
          child: MenuLabel(
            title: title,
          ),
        ),
        if (items != null) ...items,
        if (includeCopy)
          PopupMenuItem(
            onTap: () {
              Clipboard.setData(ClipboardData(text: title));
            },
            child: Text(context.l10n().copyLabel),
          ),
      ];

  @override
  State<MenuWrapper> createState() => _MenuWrapperState();
}

class _MenuWrapperState extends State<MenuWrapper> {
  final controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          shadowColor: colorScheme.surface,
          surfaceTintColor: colorScheme.primary,
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
          items: MenuWrapper.menuItems(
            context,
            widget.title,
            widget.includeCopy,
            widget.items,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class MenuLabel extends StatefulWidget {
  const MenuLabel({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MenuLabel> createState() => _MenuLabelState();
}

class _MenuLabelState extends State<MenuLabel> {
  bool expandTitle = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        expandTitle = !expandTitle;

        setState(() {});
      },
      child: Text(
        widget.title,
        style: theme.textTheme.titleSmall!.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.6,
        ),
        maxLines: expandTitle ? null : 1,
        overflow: expandTitle ? null : TextOverflow.ellipsis,
      ),
    );
  }
}
