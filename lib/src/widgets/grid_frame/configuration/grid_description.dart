// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

/// Metadata about the grid.
class GridDescription<T extends CellBase> {
  const GridDescription({
    required this.actions,
    required this.gridSeed,
    required this.keybindsDescription,
    this.showAppBar = true,
    this.ignoreEmptyWidgetOnNoContent = false,
    this.bottomWidget,
    this.asSliver = false,
    this.settingsButton,
    this.inlineMenuButtonItems = false,
    this.menuButtonItems,
    this.footer,
    this.pages,
    this.pageName,
    this.overrideEmptyWidgetNotice,
    this.showPageSwitcherAsHeader = false,
    this.appBarSnap = true,
  });

  /// Displayed in the keybinds info page name.
  final String keybindsDescription;

  /// If [pageName] is not null, and [GridFrame.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [GridFrame.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridAction<T>> actions;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  final bool showAppBar;

  final bool ignoreEmptyWidgetOnNoContent;

  /// Makes [menuButtonItems] appear as app bar items.
  final bool inlineMenuButtonItems;

  final bool asSliver;

  final bool appBarSnap;

  final bool showPageSwitcherAsHeader;

  final int gridSeed;

  final String? overrideEmptyWidgetNotice;

  final PageSwitcherInterface<T>? pages;

  final PreferredSizeWidget? footer;

  final GridFrameSettingsButton? settingsButton;

  /// Items added in the menu button's children, after the [searchWidget], or the page name
  /// if [searchWidget] is null. If [menuButtonItems] includes only one widget,
  /// it is displayed directly.
  final List<Widget>? menuButtonItems;
}
