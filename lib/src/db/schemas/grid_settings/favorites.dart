// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:isar/isar.dart';

import '../../base/grid_settings_base.dart';

part 'favorites.g.dart';

@collection
class GridSettingsFavorites extends GridSettingsBase {
  const GridSettingsFavorites({
    required super.aspectRatio,
    required super.columns,
    required super.layoutType,
    required super.hideName,
  });

  final Id id = 0;

  GridSettingsFavorites copy({
    bool? hideName,
    GridAspectRatio? aspectRatio,
    GridColumn? columns,
    GridLayoutType? layoutType,
  }) {
    return GridSettingsFavorites(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        hideName: hideName ?? this.hideName,
        columns: columns ?? this.columns,
        layoutType: layoutType ?? this.layoutType);
  }

  void save() {
    Dbs.g.main
        .writeTxnSync(() => Dbs.g.main.gridSettingsFavorites.putSync(this));
  }

  static StreamSubscription<GridSettingsFavorites?> watch(
      void Function(GridSettingsFavorites?) f) {
    return Dbs.g.main.gridSettingsFavorites.watchObject(0).listen(f);
  }

  static GridSettingsFavorites get current =>
      Dbs.g.main.gridSettingsFavorites.getSync(0) ??
      GridSettingsFavorites(
        aspectRatio: GridAspectRatio.one,
        columns: Platform.isAndroid ? GridColumn.two : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: true,
      );
}
