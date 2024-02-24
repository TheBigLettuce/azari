// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../../widgets/grid/grid_frame.dart';

/// Metadata about the grid.
class GridDescription<T extends Cell> {
  /// Displayed in the keybinds info page name.
  final String keybindsDescription;

  /// If [pageName] is not null, and [GridFrame.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [GridFrame.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridAction<T>> actions;

  final GridLayouter<T> layout;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  final int titleLines;

  final bool showAppBar;

  final bool ignoreSwipeSelectGesture;

  final bool ignoreEmptyWidgetOnNoContent;

  final bool cellTitleAtBottom;

  /// Makes [menuButtonItems] appear as app bar items.
  final bool inlineMenuButtonItems;

  final bool showCount;

  final bool asSliver;

  final bool hideTitle;

  final bool tightMode;

  final PageSwitcher? pages;

  final PreferredSizeWidget? footer;

  /// Items added in the menu button's children, after the [searchWidget], or the page name
  /// if [searchWidget] is null. If [menuButtonItems] includes only one widget,
  /// it is displayed directly.
  final List<Widget>? menuButtonItems;

  const GridDescription(
    this.actions, {
    required this.keybindsDescription,
    required this.layout,
    this.showAppBar = true,
    this.ignoreEmptyWidgetOnNoContent = false,
    this.bottomWidget,
    this.ignoreSwipeSelectGesture = false,
    this.cellTitleAtBottom = false,
    // this.ignoreImageViewEndDrawer = false,
    this.asSliver = false,
    this.inlineMenuButtonItems = false,
    this.tightMode = false,
    this.showCount = false,
    this.titleLines = 1,
    this.hideTitle = false,
    this.menuButtonItems,
    this.footer,
    this.pages,
    this.pageName,
  });
}
