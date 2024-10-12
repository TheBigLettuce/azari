// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

/// Metadata about the grid.
class GridDescription<T extends CellBase> {
  const GridDescription({
    this.pullToRefresh = true,
    required this.actions,
    required this.gridSeed,
    this.showAppBar = true,
    this.bottomWidget,
    this.asSliver = false,
    this.footer,
    this.pageName,
    this.overrideEmptyWidgetNotice,
    this.animationsOnSourceWatch = true,
    this.showLoadingIndicator = true,
  });

  /// If [pageName] is not null, and [GridFrame.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [GridFrame.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridAction<T>> actions;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  final bool showAppBar;
  final bool pullToRefresh;
  final bool animationsOnSourceWatch;
  final bool showLoadingIndicator;
  final bool asSliver;

  final int gridSeed;

  final String? overrideEmptyWidgetNotice;

  final PreferredSizeWidget? footer;
}
