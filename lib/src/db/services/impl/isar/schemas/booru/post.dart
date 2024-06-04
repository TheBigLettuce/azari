// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/base/booru_post_functionality_mixin.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:isar/isar.dart";

part "post.g.dart";

@collection
class PostIsar extends PostBase
    with Post<Post>, DefaultPostPressable<Post>
    implements IsarEntryId {
  PostIsar({
    required super.height,
    required super.id,
    required super.md5,
    required super.tags,
    required super.width,
    required super.fileUrl,
    required super.booru,
    required super.previewUrl,
    required super.sampleUrl,
    required super.sourceUrl,
    required super.rating,
    required super.score,
    required super.createdAt,
    required super.type,
  });

  @override
  Id? isarId;

  static List<PostIsar> copyTo(Iterable<Post> post) => post
      .map(
        (e) => PostIsar(
          height: e.height,
          id: e.id,
          md5: e.md5,
          tags: e.tags,
          width: e.width,
          fileUrl: e.fileUrl,
          booru: e.booru,
          previewUrl: e.previewUrl,
          sampleUrl: e.sampleUrl,
          sourceUrl: e.sourceUrl,
          rating: e.rating,
          score: e.score,
          createdAt: e.createdAt,
          type: e.type,
        ),
      )
      .toList();
}
