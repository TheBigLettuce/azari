// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:isar/isar.dart";

part "bookmark.g.dart";

@collection
class IsarBookmark extends GridBookmark {
  IsarBookmark({
    required super.name,
    required super.time,
    required super.tags,
    required super.booru,
    required this.thumbnails,
  });

  Id? isarId;

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
      );
}

@embedded
class IsarGridBookmarkThumbnail implements GridBookmarkThumbnail {
  const IsarGridBookmarkThumbnail({
    this.url = "",
    this.rating = PostRating.general,
  });

  @override
  final String url;
  @override
  @enumerated
  final PostRating rating;
}
