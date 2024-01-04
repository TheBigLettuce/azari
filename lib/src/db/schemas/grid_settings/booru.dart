// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:isar/isar.dart';

import '../../base/grid_settings_base.dart';

part 'booru.g.dart';

@collection
class GridSettingsBooru extends GridSettingsBase {
  const GridSettingsBooru(
      {required super.aspectRatio,
      required super.columns,
      required super.listView,
      required super.hideName});

  final Id id = 0;

  GridSettingsBooru copy(
      {bool? hideName,
      GridAspectRatio? aspectRatio,
      GridColumn? columns,
      bool? listView}) {
    return GridSettingsBooru(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      hideName: hideName ?? this.hideName,
      columns: columns ?? this.columns,
      listView: listView ?? this.listView,
    );
  }

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridSettingsBoorus.putSync(this));
  }

  static StreamSubscription<GridSettingsBooru?> watch(
      void Function(GridSettingsBooru?) f) {
    return Dbs.g.main.gridSettingsBoorus.watchObject(0).listen(f);
  }

  static GridSettingsBooru get current =>
      Dbs.g.main.gridSettingsBoorus.getSync(0) ??
      GridSettingsBooru(
          aspectRatio: GridAspectRatio.one,
          columns: Platform.isAndroid ? GridColumn.two : GridColumn.six,
          listView: false,
          hideName: true);
}
