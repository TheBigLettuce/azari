// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

/// Action which can be taken upon a selected group of cells.
class GridBottomSheetAction<T> {
  /// Icon of the button.
  final IconData icon;

  /// [onPress] is called when the button gets pressed,
  /// if [showOnlyWhenSingle] is true then this is guranteed to be called
  /// with [selected] elements zero or one.
  final void Function(List<T> selected) onPress;

  /// If [closeOnPress] is true, then the bottom sheet will be closed immediately after this
  /// button has been pressed.
  final bool closeOnPress;

  /// If [showOnlyWhenSingle] is true, then this button will be only active if only a single
  /// element is currently selected.
  final bool showOnlyWhenSingle;

  /// The information about the action.
  /// Displayed in a dialog after long tapping.
  final GridBottomSheetActionExplanation explanation;

  final Color? backgroundColor;
  final Color? color;
  final bool animate;
  final bool play;

  const GridBottomSheetAction(
      this.icon, this.onPress, this.closeOnPress, this.explanation,
      {this.showOnlyWhenSingle = false,
      this.backgroundColor,
      this.color,
      this.animate = false,
      this.play = true});
}

class GridBottomSheetActionExplanation {
  final String label;
  final String body;

  const GridBottomSheetActionExplanation(
      {required this.label, required this.body});
}
