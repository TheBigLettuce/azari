// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';

import '../callback_grid.dart';

class ListLayout<T extends Cell> implements GridLayouter<T> {
  final bool hideThumbnails;
  final bool unpressable;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return GridLayouts.list<T>(context, state.mutationInterface,
        state.selection, state.widget.systemNavigationInsets.bottom,
        hideThumbnails: hideThumbnails,
        onPressed: unpressable ? null : state.onPressed);
  }

  @override
  GridColumn? get columns => null;

  @override
  bool get isList => true;

  const ListLayout({this.hideThumbnails = false, this.unpressable = false});
}
