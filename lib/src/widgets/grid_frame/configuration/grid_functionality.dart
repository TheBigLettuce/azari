// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:flutter/material.dart";

class GridFunctionality<T extends CellBase> {
  const GridFunctionality({
    this.playAnimationOn = const [],
    required this.source,
    required this.selectionGlue,
    this.registerNotifiers,
    this.updateScrollPosition,
    this.download,
    this.updatesAvailable,
    this.settingsButton,
    this.fab = const DefaultGridFab(),
    this.backButton = const EmptyGridBackButton(inherit: true),
    this.search = const PageNameSearchWidget(),
  });

  final ResourceSource<int, T> source;

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

  final List<WatchFire<dynamic>> playAnimationOn;

  final GridSettingsButton? settingsButton;

  final GridFabType fab;
  final SelectionGlue selectionGlue;
  final GridBackButtonBehaviour backButton;
  final GridSearchWidget search;
  final UpdatesAvailable? updatesAvailable;
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
