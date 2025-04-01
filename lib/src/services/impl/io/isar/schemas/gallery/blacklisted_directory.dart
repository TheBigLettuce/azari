// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/impl/obj/blacklisted_directory_data_impl.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:isar/isar.dart";

part "blacklisted_directory.g.dart";

@collection
class IsarBlacklistedDirectory
    with
        DefaultBlacklistedDirectoryDataOnPress,
        BlacklistedDirectoryDataImpl,
        DefaultBuildCellImpl
    implements $BlacklistedDirectoryData {
  const IsarBlacklistedDirectory({
    required this.isarId,
    required this.bucketId,
    required this.name,
  });

  const IsarBlacklistedDirectory.noId({
    required this.bucketId,
    required this.name,
  }) : isarId = null;

  final Id? isarId;

  @override
  @Index(unique: true, replace: true)
  final String bucketId;

  @override
  @Index()
  final String name;
}
