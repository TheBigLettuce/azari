// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class SegmentLabel extends StatelessWidget {
  final String text;
  final void Function()? onLongPress;
  final void Function()? onPress;
  final bool sticky;
  final bool hidePinnedIcon;
  final Widget? overridePinnedIcon;

  const SegmentLabel(
    this.text, {
    super.key,
    required this.hidePinnedIcon,
    this.onLongPress,
    required this.onPress,
    required this.sticky,
    this.overridePinnedIcon,
  });

  @override
  Widget build(BuildContext context) {
    final rightGesture = MediaQuery.systemGestureInsetsOf(context).right;

    final row = Row(
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: overridePinnedIcon == null && hidePinnedIcon
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        Container(
          clipBehavior: onPress == null ? Clip.none : Clip.antiAlias,
          padding: onPress == null
              ? const EdgeInsets.all(8)
              : const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
          decoration: onPress == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.4),
                ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
        ),
        if ((sticky && !hidePinnedIcon) || overridePinnedIcon != null)
          overridePinnedIcon ??
              const IconButton.filled(
                  onPressed: null, icon: Icon(Icons.push_pin_outlined)),
      ],
    );

    return Padding(
        padding: EdgeInsets.only(
            bottom: 8,
            top: 16,
            right: rightGesture == 0 ? 8 : rightGesture / 2),
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onPress,
          child: hidePinnedIcon && overridePinnedIcon == null
              ? row
              : SizedBox.fromSize(
                  size: Size.fromHeight(
                      (Theme.of(context).textTheme.headlineMedium?.fontSize ??
                              24) +
                          8 +
                          16),
                  child: row,
                ),
        ));
  }
}

class MediumSegmentLabel extends StatelessWidget {
  final String text;
  final Widget? trailingWidget;

  const MediumSegmentLabel(
    this.text, {
    super.key,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final rightGesture = MediaQuery.systemGestureInsetsOf(context).right;

    return Padding(
      padding: EdgeInsets.only(
          bottom: 8, top: 8, right: rightGesture == 0 ? 8 : rightGesture / 2),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}
