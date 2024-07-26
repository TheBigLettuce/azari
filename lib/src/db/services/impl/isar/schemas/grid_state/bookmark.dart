// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl_table/io.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:isar/isar.dart";

part "bookmark.g.dart";

@collection
class IsarBookmark extends GridBookmarkImpl implements $GridBookmark {
  const IsarBookmark({
    required this.name,
    required this.time,
    required this.tags,
    required this.booru,
    required this.thumbnails,
    required this.isarId,
  });

  const IsarBookmark.noIdList({
    required this.name,
    required this.time,
    required this.tags,
    required this.booru,
  })  : isarId = null,
        thumbnails = const [];

  final Id? isarId;

  @override
  @enumerated
  final Booru booru;

  @override
  @Index(unique: true, replace: true)
  final String name;

  @override
  @Index()
  final String tags;

  @override
  @Index()
  final DateTime time;

  @override
  final List<IsarGridBookmarkThumbnail> thumbnails;

  @override
  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
    List<GridBookmarkThumbnail>? thumbnails,
  }) =>
      IsarBookmark(
        thumbnails: thumbnails?.cast() ?? this.thumbnails,
        tags: tags ?? this.tags,
        booru: booru ?? this.booru,
        time: time ?? this.time,
        name: name ?? this.name,
        isarId: isarId,
      );
}

@embedded
class IsarGridBookmarkThumbnail implements $GridBookmarkThumbnail {
  const IsarGridBookmarkThumbnail({
    this.url = "",
    this.rating = PostRating.general,
  });

  const IsarGridBookmarkThumbnail.required({
    required this.url,
    required this.rating,
  });

  @override
  final String url;

  @override
  @enumerated
  final PostRating rating;
}
