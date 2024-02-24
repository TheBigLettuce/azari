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

    return Padding(
        padding: EdgeInsets.only(
            bottom: 8,
            top: 16,
            left: 8,
            right: rightGesture == 0 ? 8 : rightGesture / 2),
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onPress,
          child: SizedBox.fromSize(
            size: Size.fromHeight(
                (Theme.of(context).textTheme.headlineLarge?.fontSize ?? 24) +
                    8),
            child: Row(
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                if ((sticky && !hidePinnedIcon) || overridePinnedIcon != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: overridePinnedIcon ??
                        const Icon(Icons.push_pin_outlined),
                  ),
              ],
            ),
          ),
        ));
  }
}
