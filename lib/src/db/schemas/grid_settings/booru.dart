// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/grid_masonry_layout.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/grid_quilted.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/list_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';

import '../../base/grid_settings_base.dart';

part 'booru.g.dart';

enum GridLayoutType {
  grid(),
  list(),
  gridQuilted(),
  gridMasonry();

  const GridLayoutType();

  String translatedString(BuildContext context) => switch (this) {
        GridLayoutType.grid =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGrid,
        GridLayoutType.list =>
          AppLocalizations.of(context)!.enumGridLayoutTypeList,
        GridLayoutType.gridQuilted =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGridQuilted,
        GridLayoutType.gridMasonry =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGridMasonry,
      };

  GridLayouter<T> layout<T extends Cell>() => switch (this) {
        GridLayoutType.list => ListLayout<T>(),
        GridLayoutType.grid => GridLayout<T>(),
        GridLayoutType.gridQuilted => GridQuiltedLayout<T>(),
        GridLayoutType.gridMasonry => GridMasonryLayout<T>(),
      };
}

@collection
class GridSettingsBooru extends GridSettingsBase {
  const GridSettingsBooru({
    required super.aspectRatio,
    required super.columns,
    required super.layoutType,
    required super.hideName,
  });

  final Id id = 0;

  GridSettingsBooru copy(
      {bool? hideName,
      GridAspectRatio? aspectRatio,
      GridColumn? columns,
      GridLayoutType? layoutType}) {
    return GridSettingsBooru(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      hideName: hideName ?? this.hideName,
      columns: columns ?? this.columns,
      layoutType: layoutType ?? this.layoutType,
    );
  }

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridSettingsBoorus.putSync(this));
  }

  static StreamSubscription<GridSettingsBooru> watch(
      void Function(GridSettingsBooru) f) {
    return Dbs.g.main.gridSettingsBoorus
        .watchObject(0)
        .map((event) => event!)
        .listen(f);
  }

  static GridSettingsBooru current() =>
      Dbs.g.main.gridSettingsBoorus.getSync(0) ??
      GridSettingsBooru(
          aspectRatio: GridAspectRatio.one,
          columns: Platform.isAndroid ? GridColumn.two : GridColumn.six,
          layoutType: GridLayoutType.gridQuilted,
          hideName: true);
}
