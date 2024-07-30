// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:isar/isar.dart";

part "directory_metadata.g.dart";

@collection
class IsarDirectoryMetadata implements DirectoryMetadata {
  IsarDirectoryMetadata({
    required this.isarId,
    required this.categoryName,
    required this.time,
    required this.blur,
    required this.sticky,
    required this.requireAuth,
  });

  final Id? isarId;

  @override
  final bool blur;

  @override
  @Index(unique: true, replace: true)
  final String categoryName;

  @override
  final bool requireAuth;

  @override
  final bool sticky;

  @override
  @Index()
  final DateTime time;

  @override
  IsarDirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) {
    return IsarDirectoryMetadata(
      isarId: isarId,
      categoryName: categoryName,
      time: time,
      blur: blur ?? this.blur,
      sticky: sticky ?? this.sticky,
      requireAuth: requireAuth ?? this.requireAuth,
    );
  }
}
