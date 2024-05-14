// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";

class GridFunctionality<T extends CellBase> {
  const GridFunctionality({
    required this.source,
    required this.selectionGlue,
    this.registerNotifiers,
    this.updateScrollPosition,
    this.download,
    this.settingsButton,
    this.fab = const DefaultGridFab(),
    this.backButton = const EmptyGridBackButton(inherit: true),
    this.search = const EmptyGridSearchWidget(),
  });

  final ResourceSource<T> source;

  /// In case if the cell represents an online resource which can be downloaded,
  /// setting [download] enables buttons to download the resource.
  final void Function(int indx)? download;

  /// [updateScrollPosition] gets called when grid first builds and then when scrolling stops,
  ///  if not null. Useful when it is desirable to persist the scroll position of the grid.
  /// [infoPos] represents the scroll position in the "Info" of the image view,
  ///  and [selectedCell] represents the inital page of the image view.
  /// State restoration takes this info into the account.
  final void Function(double pos)? updateScrollPosition;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final GridSettingsButton? settingsButton;

  final GridFabType fab;
  final SelectionGlue selectionGlue;
  final GridBackButtonBehaviour backButton;
  final GridSearchWidget search;
}

sealed class GridRefreshType {
  const GridRefreshType();

  bool get pullToRefresh;
}

class SynchronousGridRefresh implements GridRefreshType {
  const SynchronousGridRefresh(
    this.refresh, {
    this.pullToRefresh = false,
  });

  @override
  final bool pullToRefresh;

  final int Function() refresh;
}

class AsyncGridRefresh implements GridRefreshType {
  const AsyncGridRefresh(
    this.refresh, {
    this.pullToRefresh = true,
  });

  @override
  final bool pullToRefresh;

  final Future<int> Function() refresh;
}

class RetainedGridRefresh implements GridRefreshType {
  const RetainedGridRefresh(
    this.refresh, {
    this.pullToRefresh = true,
  });

  @override
  final bool pullToRefresh;

  final void Function() refresh;
}
