// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

abstract class SegmentKey {
  const SegmentKey();

  String translatedString(BuildContext context);
}

/// Segments of the grid.
class Segments<T> {
  const Segments(
    this.unsegmentedLabel, {
    this.addToSticky,
    this.segment,
    this.limitLabelChildren,
    this.prebuiltSegments,
    this.onLabelPressed,
    this.displayFirstCellInSpecial = false,
    this.hidePinnedIcon = false,
    this.injectedSegments = const [],
    required this.injectedLabel,
  }) : assert(prebuiltSegments == null || segment == null);

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

  final Map<SegmentKey, int>? prebuiltSegments;
  final int? limitLabelChildren;

  /// If [addToSticky] is not null. then it will be possible to make
  /// segments sticky on the grid.
  /// If [unsticky] is true, then instead of stickying, unstickying should happen.
  /// If [addToSticky] returns true, calls [HapticFeedback.selectionClick].
  final bool Function(String seg, {bool? unsticky})? addToSticky;

  final void Function(String label, List<T> children)? onLabelPressed;

  final bool hidePinnedIcon;
  final bool displayFirstCellInSpecial;
}
