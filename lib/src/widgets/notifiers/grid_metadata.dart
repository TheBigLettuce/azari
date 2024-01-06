// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';

import '../grid2/metadata/grid_action.dart';
import '../grid2/metadata/grid_metadata.dart';

enum GridMetadataAspect {
  hideAlias,
  tight,
  columns,
  aspectRatio,
  isList,
  gridActions,
  onPressed
}

class GridMetadataProvider<T extends Cell>
    extends InheritedModel<GridMetadataAspect> {
  final GridMetadata<T> metadata;

  static GridMetadataProvider<T> _of<T extends Cell>(
      BuildContext context, GridMetadataAspect aspect) {
    return InheritedModel.inheritFrom<GridMetadataProvider<T>>(context,
        aspect: aspect)!;
  }

  static bool hideAliasOf<T extends Cell>(BuildContext context) =>
      _of<T>(context, GridMetadataAspect.hideAlias).metadata.hideAlias;

  static GridColumn columnsOf<T extends Cell>(BuildContext context) =>
      _of<T>(context, GridMetadataAspect.columns).metadata.columns;

  static GridAspectRatio aspectRatioOf<T extends Cell>(BuildContext context) =>
      _of<T>(context, GridMetadataAspect.aspectRatio).metadata.aspectRatio;

  static bool isListOf<T extends Cell>(BuildContext context) =>
      _of<T>(context, GridMetadataAspect.isList).metadata.isList;

  static List<GridAction<T>> gridActionsOf<T extends Cell>(
          BuildContext context) =>
      _of<T>(context, GridMetadataAspect.gridActions).metadata.gridActions;

  static void Function(BuildContext, int)? onPressedOf<T extends Cell>(
          BuildContext context) =>
      _of<T>(context, GridMetadataAspect.onPressed).metadata.onPressed;

  static bool tightOf<T extends Cell>(BuildContext context) =>
      _of<T>(context, GridMetadataAspect.tight).metadata.tight;

  const GridMetadataProvider(
      {super.key, required this.metadata, required super.child});

  @override
  bool updateShouldNotify(GridMetadataProvider<T> oldWidget) {
    return metadata != oldWidget.metadata;
  }

  @override
  bool updateShouldNotifyDependent(
      GridMetadataProvider<T> oldWidget, Set<GridMetadataAspect> dependencies) {
    for (final e in dependencies) {
      switch (e) {
        case GridMetadataAspect.hideAlias:
          if (oldWidget.metadata.hideAlias != metadata.hideAlias) {
            return true;
          }
        case GridMetadataAspect.tight:
          if (oldWidget.metadata.tight != metadata.tight) {
            return true;
          }
        case GridMetadataAspect.columns:
          if (oldWidget.metadata.columns != metadata.columns) {
            return true;
          }
        case GridMetadataAspect.aspectRatio:
          if (oldWidget.metadata.aspectRatio != metadata.aspectRatio) {
            return true;
          }
        case GridMetadataAspect.isList:
          if (oldWidget.metadata.isList != oldWidget.metadata.isList) {
            return true;
          }
        case GridMetadataAspect.gridActions:
          if (oldWidget.metadata.gridActions != metadata.gridActions) {
            return true;
          }
        case GridMetadataAspect.onPressed:
          if (oldWidget.metadata.onPressed != metadata.onPressed) {
            return true;
          }
      }
    }

    return false;
  }
}
