// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";

part "tags.g.dart";

// static void add(String tag) {
//   PostTags.g.tagsDb.writeTxnSync(
//     () => PostTags.g.tagsDb.pinnedTags.putSync(PinnedTag(tag)),
//   );
// }

// static bool isPinned(String tag) {
//   return PostTags.g.tagsDb.pinnedTags.getSync(fastHash(tag)) != null;
// }

// static void remove(String tag) {
//   PostTags.g.tagsDb.writeTxnSync(
//     () => PostTags.g.tagsDb.pinnedTags.deleteSync(fastHash(tag)),
//   );
// }

@collection
class IsarTag extends TagData {
  IsarTag({
    required this.time,
    required super.tag,
    required super.type,
  });

  Id? isarId;

  @Index()
  final DateTime time;

  @override
  IsarTag copy({String? tag, TagType? type}) => IsarTag(
        type: type ?? this.type,
        tag: tag ?? this.tag,
        time: DateTime.now(),
      );
}
