// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:isar/isar.dart";

part "blacklisted_directory.g.dart";

@collection
class IsarBlacklistedDirectory extends BlacklistedDirectoryData
    implements IsarEntryId {
  IsarBlacklistedDirectory(super.bucketId, super.name);

  @override
  Id? isarId;
}
