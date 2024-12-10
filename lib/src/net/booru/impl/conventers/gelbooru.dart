// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:html_unescape/html_unescape_small.dart";
import "package:intl/intl.dart";
import "package:json_annotation/json_annotation.dart";

part "gelbooru.g.dart";

@JsonSerializable()
class GelbooruTagsRet {
  const GelbooruTagsRet({
    required this.attributes,
    required this.posts,
  });

  factory GelbooruTagsRet.fromJson(
    Map<String, dynamic> json,
    bool onlyTypeZero,
  ) {
    var ret = _$GelbooruTagsRetFromJson(json);

    if (onlyTypeZero) {
      ret = GelbooruTagsRet(
        attributes: ret.attributes,
        posts: ret.posts.where((e) => e.type == 0).toList(),
      );
    }

    return ret;
  }

  @JsonKey(name: "@attributes")
  final Map<String, dynamic> attributes;

  @JsonKey(name: "tag")
  final List<_GelbooruTag> posts;
}

@JsonSerializable()
class _GelbooruTag implements BooruTag {
  const _GelbooruTag({
    required this.type,
    required this.count,
    required this.tag,
  });

  factory _GelbooruTag.fromJson(Map<String, dynamic> json) =>
      _$GelbooruTagFromJson(json);

  @override
  @JsonKey(name: "count")
  final int count;

  @override
  @TagEscaper()
  @JsonKey(name: "name")
  final String tag;

  @JsonKey(name: "type")
  final int type;
}

@JsonSerializable()
class GelbooruPostRet {
  const GelbooruPostRet({
    required this.attributes,
    required this.posts,
  });

  factory GelbooruPostRet.fromJson(Map<String, dynamic> json) =>
      _$GelbooruPostRetFromJson(json);

  @JsonKey(name: "@attributes")
  final Map<String, dynamic> attributes;
  @JsonKey(name: "post")
  final List<_GelbooruPost> posts;
}

@JsonSerializable()
class _GelbooruPost extends PostImpl
    with DefaultPostPressable<Post>
    implements Post {
  const _GelbooruPost({
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

  factory _GelbooruPost.fromJson(Map<String, dynamic> json) =>
      _$GelbooruPostFromJson(json);

  @override
  @JsonKey(name: "id")
  final int id;

  @override
  @JsonKey(name: "score")
  final int score;

  @override
  @JsonKey(name: "width")
  final int width;

  @override
  @JsonKey(name: "height")
  final int height;

  @override
  @JsonKey(name: "source")
  final String sourceUrl;

  @override
  @JsonKey(name: "file_url")
  final String fileUrl;

  @override
  @JsonKey(name: "preview_url")
  final String previewUrl;

  @override
  @JsonKey(name: "sample_url")
  final String sampleUrl;

  @override
  @JsonKey(name: "md5")
  final String md5;

  @override
  @StringTagsConverter()
  @JsonKey(name: "tags")
  final List<String> tags;

  @override
  @GelbooruDateConventer()
  @JsonKey(name: "created_at")
  final DateTime createdAt;

  @override
  @GelbooruRatingConverter()
  @JsonKey(name: "rating")
  final PostRating rating;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get size => 0;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Booru get booru => Booru.gelbooru;

  static final _dateFormatter = DateFormat("EEE MMM dd HH:mm:ss");

  @override
  PostContentType get type => Post.makeType(this);
}

class GelbooruRatingConverter implements JsonConverter<PostRating, String?> {
  const GelbooruRatingConverter();

  @override
  PostRating fromJson(String? json) {
    return json == null
        ? PostRating.general
        : switch (json) {
            "general" => PostRating.general,
            "sensitive" => PostRating.sensitive,
            "questionable" => PostRating.questionable,
            "explicit" => PostRating.explicit,
            String() => PostRating.general,
          };
  }

  @override
  String? toJson(PostRating object) => object.name;
}

class GelbooruDateConventer implements JsonConverter<DateTime, String> {
  const GelbooruDateConventer();

  @override
  DateTime fromJson(String json) =>
      _GelbooruPost._dateFormatter.parse(json).copyWith(
            year: int.tryParse(json.substring(json.length - 4)),
          );

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

class TagEscaper implements JsonConverter<String, String> {
  const TagEscaper();

  @override
  String fromJson(String json) => _escaper.convert(json);

  @override
  String toJson(String object) => object;

  static final _escaper = HtmlUnescape();
}

class StringTagsConverter implements JsonConverter<List<String>, String> {
  const StringTagsConverter();

  @override
  List<String> fromJson(String json) {
    return json.split(" ").map(_escaper.convert).toList();
  }

  @override
  String toJson(List<String> object) => object.join(" ");

  static final _escaper = HtmlUnescape();
}
