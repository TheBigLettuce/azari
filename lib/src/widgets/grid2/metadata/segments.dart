// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class _SegSticky {
  final String seg;
  final bool sticky;
  final void Function()? onLabelPressed;
  final bool unstickable;

  const _SegSticky(this.seg, this.sticky, this.onLabelPressed,
      {this.unstickable = true});
}

/// Segments of the grid.
class Segments<T> {
  /// Under [unsegmentedLabel] appear cells on which [segment] returns null,
  /// or are single standing.
  final String unsegmentedLabel;

  /// Under [injectedLabel] appear [injectedSegments].
  /// All pinned.
  final String injectedLabel;

  /// [injectedSegments] make it possible to add foreign cell on the segmented grid.
  /// [segment] is not called on [injectedSegments].
  final List<T> injectedSegments;

  /// Segmentation function.
  /// If [sticky] is true, then even if the cell is single standing it will appear
  /// as a single element segment on the grid.
  final (String? segment, bool sticky) Function(T cell)? segment;

  final Map<String, int>? prebuiltSegments;
  final int? limitLabelChildren;

  /// If [addToSticky] is not null. then it will be possible to make
  /// segments sticky on the grid.
  /// If [unsticky] is true, then instead of stickying, unstickying should happen.
  /// If [addToSticky] returns true, calls [HapticFeedback.selectionClick].
  final bool Function(String seg, {bool? unsticky})? addToSticky;

  final void Function(String label, List<T> children)? onLabelPressed;

  final bool hidePinnedIcon;

  const Segments(this.unsegmentedLabel,
      {this.addToSticky,
      this.segment,
      this.limitLabelChildren,
      this.prebuiltSegments,
      this.onLabelPressed,
      this.hidePinnedIcon = false,
      this.injectedSegments = const [],
      this.injectedLabel = "Special"})
      : assert(prebuiltSegments == null || segment == null);
}

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
