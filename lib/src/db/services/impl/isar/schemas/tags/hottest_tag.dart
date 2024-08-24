// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post.dart";
import "package:isar/isar.dart";

part "hottest_tag.g.dart";

@collection
class IsarHottestTag implements $HottestTag {
  const IsarHottestTag({
    required this.tag,
    required this.thumbUrls,
    required this.count,
    required this.isarId,
    required this.booru,
  });

  const IsarHottestTag.noIdList({
    required this.tag,
    required this.count,
    required this.booru,
  })  : isarId = null,
        thumbUrls = const [];

  final Id? isarId;

  @override
  @enumerated
  @Index()
  final Booru booru;

  @override
  final int count;

  @override
  final String tag;

  @override
  final List<IsarThumbUrlRating> thumbUrls;

  @override
  HottestTag copy({
    String? tag,
    int? count,
    Booru? booru,
    List<ThumbUrlRating>? thumbUrls,
  }) =>
      IsarHottestTag(
        isarId: isarId,
        tag: tag ?? this.tag,
        count: count ?? this.count,
        booru: booru ?? this.booru,
        thumbUrls: thumbUrls is List<IsarThumbUrlRating>
            ? thumbUrls
            : thumbUrls?.cast() ?? this.thumbUrls,
      );
}

@embedded
class IsarThumbUrlRating implements $ThumbUrlRating {
  const IsarThumbUrlRating({
    this.url = "",
    this.rating = PostRating.general,
  });

  const IsarThumbUrlRating.required({
    required this.rating,
    required this.url,
  });

  @override
  @enumerated
  final PostRating rating;

  @override
  final String url;
}
