// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post.dart";
import "package:isar/isar.dart";

part "favorite_post.g.dart";

@collection
class IsarFavoritePost extends PostImpl
    with DefaultPostPressable<FavoritePost>
    implements $FavoritePost {
  const IsarFavoritePost({
    required this.size,
    required this.height,
    required this.id,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    required this.type,
    required this.isarId,
  });

  const IsarFavoritePost.noId({
    required this.size,
    required this.height,
    required this.id,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    required this.type,
  }) : isarId = null;

  final Id? isarId;

  @override
  @enumerated
  final Booru booru;

  @override
  final DateTime createdAt;

  @override
  @Index()
  final String fileUrl;

  @override
  final int height;

  @override
  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int id;

  @override
  final String md5;

  @override
  final String previewUrl;

  @override
  @Index()
  @enumerated
  final PostRating rating;

  @override
  final String sampleUrl;

  @override
  final int score;

  @override
  final int size;

  @override
  final String sourceUrl;

  @override
  @Index(caseSensitive: false, type: IndexType.hashElements)
  final List<String> tags;

  @override
  @enumerated
  final PostContentType type;

  @override
  final int width;
}
