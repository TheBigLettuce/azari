// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/net/booru/impl/conventers/gelbooru.dart";
import "package:azari/src/services/impl/obj/booru_pool_impl.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:json_annotation/json_annotation.dart";
import "package:logging/logging.dart";

part "danbooru.g.dart";

List<Post> fromList(List<dynamic> l) {
  final ret = <Post>[];

  for (final e in l) {
    try {
      final post = _DanbooruPost.fromJson(e as Map<String, dynamic>);

      ret.add(post);
    } catch (e, trace) {
      Logger.root.warning("fromList", e, trace);
      continue;
    }
  }

  return ret;
}

List<BooruPool> fromListPools(List<dynamic> l) {
  final ret = <BooruPool>[];

  for (final e in l) {
    ret.add(_DanbooruPool.fromJson(e as Map<String, dynamic>));
  }

  return ret;
}

List<BooruComments> fromListComments(List<dynamic> l) {
  final ret = <BooruComments>[];

  for (final e in l) {
    ret.add(_DanbooruComments.fromJson(e as Map<String, dynamic>));
  }

  return ret;
}

List<BooruArtist> fromListArtists(List<dynamic> l) {
  final ret = <BooruArtist>[];

  for (final e in l) {
    ret.add(_DanbooruArtist.fromJson(e as Map<String, dynamic>));
  }

  return ret;
}

@JsonSerializable()
class _DanbooruPost extends PostImpl implements Post {
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
    required this.smallPreviewUrl,
    required this.sampleUrl,
    required this.rating,
    required this.size,
    required this.previewUrl720,
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

  @JsonKey(name: "preview_file_url")
  final String smallPreviewUrl;

  @override
  @JsonKey(name: "large_file_url")
  final String sampleUrl;

  @override
  @JsonKey(name: "md5")
  final String md5;

  @override
  @StringTagsConverter()
  @JsonKey(name: "tag_string")
  final List<String> tags;

  @override
  @DanbooruDateConventer()
  @JsonKey(name: "created_at")
  final DateTime createdAt;

  @override
  @JsonKey(name: "file_size")
  final int size;

  @override
  @DanbooruRatingConverter()
  @JsonKey(name: "rating")
  final PostRating rating;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Booru get booru => Booru.danbooru; // TODO: replace with value from API

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  PostContentType get type => Post.makeType(this);

  @DanbooruMediaAsset720Converter()
  @JsonKey(name: "media_asset")
  final String? previewUrl720;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get previewUrl => previewUrl720 ?? smallPreviewUrl;
}

class DanbooruMediaAsset720Converter
    implements JsonConverter<String?, Map<dynamic, dynamic>?> {
  const DanbooruMediaAsset720Converter();

  @override
  String? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final variants = json["variants"];
    if (variants is! List<dynamic>) {
      return null;
    }

    for (final e in variants) {
      final type = (e as Map)["type"];
      if (type == "720x720") {
        return e["url"] as String;
      }
    }

    return null;
  }

  @override
  Map<dynamic, dynamic>? toJson(String? object) => null;
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

class DanbooruPoolCategoryConventer
    implements JsonConverter<BooruPoolCategory, String> {
  const DanbooruPoolCategoryConventer();

  @override
  BooruPoolCategory fromJson(String json) => switch (json) {
    "series" => BooruPoolCategory.series,
    "collection" => BooruPoolCategory.collection,
    String() => BooruPoolCategory.collection,
  };

  @override
  String toJson(BooruPoolCategory object) => switch (object) {
    BooruPoolCategory.series => "series",
    BooruPoolCategory.collection => "collection",
  };
}

@JsonSerializable()
class _DanbooruPool extends BooruPoolImpl implements BooruPool {
  const _DanbooruPool({
    required this.category,
    required this.description,
    required this.id,
    required this.isDeleted,
    required this.name,
    required this.postIds,
    required this.updatedAt,
    this.thumbUrl = "",
    this.booru = Booru.danbooru,
  });

  factory _DanbooruPool.fromJson(Map<String, dynamic> json) =>
      _$DanbooruPoolFromJson(json);

  @override
  @DanbooruPoolCategoryConventer()
  @JsonKey(name: "category")
  final BooruPoolCategory category;

  @override
  @JsonKey(name: "description")
  final String description;

  @override
  @JsonKey(name: "id")
  final int id;

  @override
  @JsonKey(name: "is_deleted")
  final bool isDeleted;

  @override
  @JsonKey(name: "name")
  final String name;

  @override
  @JsonKey(name: "post_ids")
  final List<int> postIds;

  @override
  @DanbooruDateConventer()
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String thumbUrl;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Booru booru;

  @override
  BooruPool copy({
    bool? isDeleted,
    int? id,
    Booru? booru,
    String? name,
    String? description,
    String? thumbUrl,
    List<int>? postIds,
    BooruPoolCategory? category,
    DateTime? updatedAt,
  }) => _DanbooruPool(
    category: category ?? this.category,
    description: description ?? this.description,
    id: id ?? this.id,
    booru: booru ?? this.booru,
    isDeleted: isDeleted ?? this.isDeleted,
    name: name ?? this.name,
    postIds: postIds ?? this.postIds,
    updatedAt: updatedAt ?? this.updatedAt,
    thumbUrl: thumbUrl ?? this.thumbUrl,
  );
}

@JsonSerializable()
class _DanbooruArtist extends BooruArtistImpl implements BooruArtist {
  const _DanbooruArtist({
    required this.id,
    required this.name,
    required this.groupName,
    required this.otherNames,
    required this.isBanned,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory _DanbooruArtist.fromJson(Map<String, dynamic> json) =>
      _$DanbooruArtistFromJson(json);

  @override
  @JsonKey(name: "id")
  final int id;

  @override
  @JsonKey(name: "name")
  final String name;

  @override
  @JsonKey(name: "group_name")
  final String groupName;

  @override
  @JsonKey(name: "other_names")
  final List<String> otherNames;

  @override
  @JsonKey(name: "is_banned")
  final bool isBanned;

  @override
  @JsonKey(name: "is_deleted")
  final bool isDeleted;

  @override
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
}

@JsonSerializable()
class _DanbooruComments implements BooruComments {
  const _DanbooruComments({
    required this.body,
    required this.id,
    required this.isSticky,
    required this.postId,
    required this.score,
    required this.updatedAt,
  });

  factory _DanbooruComments.fromJson(Map<String, dynamic> json) =>
      _$DanbooruCommentsFromJson(json);

  @override
  @JsonKey(name: "is_sticky")
  final bool isSticky;

  @override
  @JsonKey(name: "id")
  final int id;

  @override
  @JsonKey(name: "post_id")
  final int postId;

  @override
  @JsonKey(name: "score")
  final int score;

  @override
  @JsonKey(name: "body")
  final String body;

  @override
  @DanbooruDateConventer()
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
}
