// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

import 'grid_back_button_behaviour.dart';
import 'grid_fab_type.dart';
import 'grid_refresh_behaviour.dart';
import 'grid_search_widget.dart';

class GridFunctionality<T extends Cell> {
  const GridFunctionality({
    required this.selectionGlue,
    required this.refresh,
    this.pageChangeImage,
    this.onError,
    this.loadNext,
    this.registerNotifiers,
    this.addIconsImage,
    this.updateScrollPosition,
    this.download,
    this.progressTicker,
    this.onPressed = const DefaultGridOnCellPressBehaviour(),
    this.fab = const DefaultGridFab(),
    this.backButton = const DefaultGridBackButton(),
    this.refreshBehaviour = const DefaultGridRefreshBehaviour(),
    this.search = const EmptyGridSearchWidget(),
  });

  /// [loadNext] gets called when the grid is scrolled around the end of the viewport.
  /// If this is null, then the grid is assumed to be not able to incrementally add posts
  /// by scrolling at the near end of the viewport.
  final Future<int> Function()? loadNext;

  /// In case if the cell represents an online resource which can be downloaded,
  /// setting [download] enables buttons to download the resource.
  final Future<void> Function(int indx)? download;

  /// Refresh the grid.
  final Future<int> Function() refresh;

  /// [updateScrollPosition] gets called when grid first builds and then when scrolling stops,
  ///  if not null. Useful when it is desirable to persist the scroll position of the grid.
  /// [infoPos] represents the scroll position in the "Info" of the image view,
  ///  and [selectedCell] represents the inital page of the image view.
  /// State restoration takes this info into the account.
  final void Function(double pos, {double? infoPos, int? selectedCell})?
      updateScrollPosition;

  /// Overrides the default behaviour of launching the image view on cell pressed.
  /// [overrideOnPress] can, for example, include calls to [Navigator.push] of routes.
  // final void Function(BuildContext context, T cell)? overrideOnPress;

  /// Supplied to [ImageView.addIcons].
  final List<GridAction<T>> Function(T)? addIconsImage;

  /// Supplied to [ImageView.pageChange].
  final void Function(ImageViewState<T> state)? pageChangeImage;

  /// If the elemnts of the grid arrive in batches [progressTicker] can be set to not null,
  /// grid will subscribe to it and set the cell count from this ticker's events.
  final Stream<int>? progressTicker;

  final Widget Function(Object error)? onError;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final GridFabType fab;
  final SelectionGlue<T> selectionGlue;
  final GridBackButtonBehaviour backButton;
  final GridRefreshBehaviour refreshBehaviour;
  final GridSearchWidget search;
  final GridOnCellPressedBehaviour onPressed;
}
