// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";

class SegmentLabel extends StatelessWidget {
  const SegmentLabel(
    this.text, {
    super.key,
    required this.hidePinnedIcon,
    this.menuItems = const [],
    required this.onPress,
    required this.sticky,
    this.overridePinnedIcon,
  });

  final String text;
  final List<PopupMenuItem<void>> menuItems;
  final void Function()? onPress;
  final bool sticky;
  final bool hidePinnedIcon;
  final Widget? overridePinnedIcon;

  @override
  Widget build(BuildContext context) {
    final rightGesture = MediaQuery.systemGestureInsetsOf(context).right;
    final theme = Theme.of(context);

    final row = Row(
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: overridePinnedIcon == null && hidePinnedIcon
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        _MenuAnchor(
          onPress: onPress,
          menuItems: menuItems,
          child: Container(
            clipBehavior: onPress == null ? Clip.none : Clip.antiAlias,
            padding: onPress == null
                ? const EdgeInsets.all(8)
                : const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            decoration: onPress == null
                ? null
                : ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.4),
                  ),
            child: Text(
              text,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
        if ((sticky && !hidePinnedIcon) || overridePinnedIcon != null)
          overridePinnedIcon ??
              const IconButton.filled(
                onPressed: null,
                icon: Icon(Icons.push_pin_outlined),
              ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        top: 16,
        right: rightGesture == 0 ? 8 : rightGesture / 2,
      ),
      child: hidePinnedIcon && overridePinnedIcon == null
          ? row
          : SizedBox.fromSize(
              size: Size.fromHeight(
                (theme.textTheme.headlineMedium?.fontSize ?? 24) + 8 + 16,
              ),
              child: row,
            ),
    );
  }
}

class _MenuAnchor extends StatelessWidget {
  const _MenuAnchor({
    // super.key,
    required this.menuItems,
    required this.onPress,
    required this.child,
  });

  final void Function()? onPress;
  final List<PopupMenuItem<void>> menuItems;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      onLongPress: () {
        final RenderBox button = context.findRenderObject()! as RenderBox;
        final RenderBox overlay = Navigator.of(context)
            .overlay!
            .context
            .findRenderObject()! as RenderBox;

        final offset = Offset(0, button.size.height) + const Offset(0, 2);

        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(offset, ancestor: overlay),
            button.localToGlobal(
              button.size.bottomRight(Offset.zero) + offset,
              ancestor: overlay,
            ),
          ),
          Offset.zero & overlay.size,
        );

        HapticFeedback.mediumImpact();

        showMenu(
          context: context,
          position: position,
          constraints: BoxConstraints(
            minWidth: button.size.width,
            maxWidth: button.size.width,
          ),
          items: menuItems,
        );
      },
      child: child,
    );
  }
}

class MediumSegmentLabel extends StatelessWidget {
  const MediumSegmentLabel(
    this.text, {
    super.key,
    this.trailingWidget,
  });
  final String text;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final rightGesture = MediaQuery.systemGestureInsetsOf(context).right;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        top: 8,
        right: rightGesture == 0 ? 8 : rightGesture / 2,
      ),
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: trailingWidget == null
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(
            text,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}
