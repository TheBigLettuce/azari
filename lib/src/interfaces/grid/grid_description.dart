// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../../widgets/grid/callback_grid.dart';

/// Metadata about the grid.
class GridDescription<T extends Cell> {
  /// Displayed in the keybinds info page name.
  final String keybindsDescription;

  /// If [pageName] is not null, and [CallbackGrid.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [CallbackGrid.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridAction<T>> actions;

  final GridLayouter<T> layout;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  final bool showAppBar;

  final bool ignoreSwipeSelectGesture;

  final bool ignoreEmptyWidgetOnNoContent;

  final bool cellTitleAtBottom;

  final int titleLines;

  const GridDescription(
    this.actions, {
    this.showAppBar = true,
    this.ignoreEmptyWidgetOnNoContent = false,
    required this.keybindsDescription,
    this.bottomWidget,
    this.ignoreSwipeSelectGesture = false,
    this.cellTitleAtBottom = false,
    this.titleLines = 1,
    this.pageName,
    required this.layout,
  });
}
