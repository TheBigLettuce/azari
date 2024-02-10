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

import '../grid_frame.dart';

class SegmentListLayout<T extends Cell> implements GridLayouter<T> {
  final Segments<T> segments;
  final bool tightMode;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    if (segments.prebuiltSegments != null) {
      return [
        GridLayouts.segmentsPrebuilt(
          context,
          segments,
          state.mutationInterface,
          state.selection,
          true,
          columns.number,
          state.makeGridCell,
          systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
          aspectRatio: 1,
          hideAlias: false,
          tightMode: tightMode,
        )
      ];
    }
    final (s, t) = GridLayouts.segmentsFnc<T>(
      context,
      segments,
      state.mutationInterface,
      state.selection,
      true,
      columns.number,
      state.makeGridCell,
      systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
      aspectRatio: 1,
      hideAlias: false,
      tightMode: tightMode,
    );

    state.segTranslation = t;

    return [s];
  }

  @override
  bool get isList => true;

  const SegmentListLayout(
    this.segments,
    this.columns, {
    this.tightMode = false,
  });
}
