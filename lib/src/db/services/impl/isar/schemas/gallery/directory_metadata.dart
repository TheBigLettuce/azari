// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";

part "directory_metadata.g.dart";

@collection
class IsarDirectoryMetadata extends DirectoryMetadataData {
  const IsarDirectoryMetadata(
    super.categoryName,
    super.time, {
    required super.blur,
    required super.sticky,
    required super.requireAuth,
  });

  Id get isarId => fastHash(categoryName);

  @override
  IsarDirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) {
    return IsarDirectoryMetadata(
      categoryName,
      time,
      blur: blur ?? this.blur,
      sticky: sticky ?? this.sticky,
      requireAuth: requireAuth ?? this.requireAuth,
    );
  }
}
