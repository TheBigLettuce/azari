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
  const SegmentLabel(this.text,
      {super.key,
      required this.hidePinnedIcon,
      this.onLongPress,
      required this.onPress,
      required this.sticky});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16, left: 8, right: 8),
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onPress,
          child: SizedBox.fromSize(
            size: Size.fromHeight(
                (Theme.of(context).textTheme.headlineLarge?.fontSize ?? 24) +
                    8),
            child: Stack(
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                if (sticky && !hidePinnedIcon)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.push_pin_outlined),
                  ),
              ],
            ),
          ),
        ));
  }
}
