// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:isar/isar.dart";

part "booru.g.dart";

@collection
class IsarGridSettingsBooru extends IsarGridSettingsData {
  const IsarGridSettingsBooru({
    required super.aspectRatio,
    required super.columns,
    required super.layoutType,
    required super.hideName,
  });

  Id get id => 0;

  @override
  IsarGridSettingsBooru copy({
    bool? hideName,
    GridAspectRatio? aspectRatio,
    GridColumn? columns,
    GridLayoutType? layoutType,
  }) =>
      IsarGridSettingsBooru(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        hideName: hideName ?? this.hideName,
        columns: columns ?? this.columns,
        layoutType: layoutType ?? this.layoutType,
      );
}
