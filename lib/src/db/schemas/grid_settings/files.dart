// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/widgets/grid/enums/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid/enums/grid_column.dart';
import 'package:isar/isar.dart';

import '../../base/grid_settings_base.dart';

part 'files.g.dart';

@collection
class GridSettingsFiles extends GridSettingsBase {
  const GridSettingsFiles(
      {required super.aspectRatio,
      required super.columns,
      required super.listView,
      required super.hideName});

  final Id id = 0;

  GridSettingsFiles copy(
      {bool? hideName,
      GridAspectRatio? aspectRatio,
      GridColumn? columns,
      bool? listView}) {
    return GridSettingsFiles(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        hideName: hideName ?? this.hideName,
        columns: columns ?? this.columns,
        listView: listView ?? this.listView);
  }

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridSettingsFiles.putSync(this));
  }

  static StreamSubscription<GridSettingsFiles?> watch(
      void Function(GridSettingsFiles?) f) {
    return Dbs.g.main.gridSettingsFiles.watchObject(0).listen(f);
  }

  static GridSettingsFiles get current =>
      Dbs.g.main.gridSettingsFiles.getSync(0) ??
      GridSettingsFiles(
        aspectRatio: GridAspectRatio.one,
        columns: Platform.isAndroid ? GridColumn.three : GridColumn.six,
        listView: false,
        hideName: true,
      );
}
