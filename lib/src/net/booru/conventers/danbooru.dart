// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/base/booru_post_functionality_mixin.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/net/booru/conventers/gelbooru.dart";
import "package:json_annotation/json_annotation.dart";
import "package:mime/mime.dart";

part "danbooru.g.dart";

List<Post> fromList(List<dynamic> l) {
  final ret = <Post>[];

  for (final e in l) {
    try {
      final post = _DanbooruPost.fromJson(e as Map<String, dynamic>);

      ret.add(post);
    } catch (_) {
      continue;
    }
  }

  return ret;
}

@JsonSerializable()
class _DanbooruPost with Post, DefaultPostPressable {
  const _DanbooruPost({
    required this.height,
    required this.id,
    required this.md5,
    required this.tags,
    required this.score,
    required this.sourceUrl,
    required this.createdAt,
    required this.width,
    required this.fileUrl,
    required this.previewUrl,
    required this.sampleUrl,
    required this.rating,
  });

  factory _DanbooruPost.fromJson(Map<String, dynamic> json) =>
      _$DanbooruPostFromJson(json);

  @override
  @JsonKey(name: "id")
  final int id;

  @override
  @JsonKey(name: "score")
  final int score;

  @override
  @JsonKey(name: "image_width")
  final int width;

  @override
  @JsonKey(name: "image_height")
  final int height;

  @override
  @JsonKey(name: "source")
  final String sourceUrl;

  @override
  @JsonKey(name: "file_url")
  final String fileUrl;

  @override
  @JsonKey(name: "preview_file_url")
  final String previewUrl;

  @override
  @JsonKey(name: "large_file_url")
  final String sampleUrl;

  @override
  @JsonKey(name: "md5")
  final String md5;

  @override
  @StringTagsConverter()
  @JsonKey(name: "tags_string")
  final List<String> tags;

  @override
  @DanbooruDateConventer()
  @JsonKey(name: "created_at")
  final DateTime createdAt;

  @override
  @DanbooruRatingConverter()
  @JsonKey(name: "rating")
  final PostRating rating;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Booru get booru => Booru.danbooru;

  @override
  PostContentType get type => Post.makeType(this);
}

class DanbooruRatingConverter implements JsonConverter<PostRating, String?> {
  const DanbooruRatingConverter();

  @override
  PostRating fromJson(String? json) => json == null
      ? PostRating.general
      : switch (json) {
          "g" => PostRating.general,
          "s" => PostRating.sensitive,
          "q" => PostRating.questionable,
          "e" => PostRating.explicit,
          String() => PostRating.general,
        };

  @override
  String toJson(PostRating object) => object.name[0];
}

class DanbooruDateConventer implements JsonConverter<DateTime, String> {
  const DanbooruDateConventer();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}
