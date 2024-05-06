// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:isar/isar.dart";

part "pinned_tag.g.dart";

@collection
class PinnedTag {
  const PinnedTag(this.tag);

  Id get isarId => fastHash(tag);

  @Index(unique: true, replace: true)
  final String tag;

  static void add(String tag) {
    PostTags.g.tagsDb.writeTxnSync(
      () => PostTags.g.tagsDb.pinnedTags.putSync(PinnedTag(tag)),
    );
  }

  static bool isPinned(String tag) {
    return PostTags.g.tagsDb.pinnedTags.getSync(fastHash(tag)) != null;
  }

  static void remove(String tag) {
    PostTags.g.tagsDb.writeTxnSync(
      () => PostTags.g.tagsDb.pinnedTags.deleteSync(fastHash(tag)),
    );
  }
}
