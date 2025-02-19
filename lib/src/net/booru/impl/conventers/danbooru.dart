// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/impl/conventers/gelbooru.dart";
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

@JsonSerializable()
class _DanbooruPost extends PostImpl
    with DefaultPostPressable<Post>
    implements Post {
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
  Booru get booru => Booru.danbooru;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  PostContentType get type => Post.makeType(this);

  @_DanbooruMediaAsset720Converter()
  @JsonKey(name: "media_asset")
  final String? previewUrl720;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get previewUrl => previewUrl720 ?? smallPreviewUrl;
}

// @JsonSerializable()
// class _DanbooruMediaAsset {
//   const _DanbooruMediaAsset(this.variants);

//   factory _DanbooruMediaAsset.fromJson(Map<String, dynamic> json) =>
//       _$DanbooruMediaAssetFromJson(json);

//   String? find720() {
//     final idx = variants.indexWhere((e) => e.type == "720x720");
//     if (idx < 0) {
//       return null;
//     }

//     return variants[idx].url;
//   }

//   @JsonKey(name: "variants")
//   final List<_Variants> variants;
// }

// @JsonSerializable()
// class _Variants {
//   const _Variants(this.type, this.url);

//   factory _Variants.fromJson(Map<String, dynamic> json) =>
//       _$VariantsFromJson(json);

//   @JsonKey(name: "type")
//   final String type;

//   @JsonKey(name: "url")
//   final String url;
// }

class _DanbooruMediaAsset720Converter
    implements JsonConverter<String?, Map<dynamic, dynamic>?> {
  const _DanbooruMediaAsset720Converter();

  @override
  String? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final variants = json["variants"] as List<dynamic>;
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

// class DanbooruMediaAssetConverter implements JsonConverter<_DanbooruMediaAsset, Map<dynamic, dynamic>> {
//   const DanbooruMediaAssetConverter();

//   @override
//   PostRating fromJson(String? json) => json == null
//       ? PostRating.general
//       : switch (json) {
//           "g" => PostRating.general,
//           "s" => PostRating.sensitive,
//           "q" => PostRating.questionable,
//           "e" => PostRating.explicit,
//           String() => PostRating.general,
//         };

//   @override
//   String toJson(PostRating object) => object.name[0];
// }

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
class _DanbooruPool implements BooruPool {
  const _DanbooruPool({
    required this.category,
    required this.description,
    required this.id,
    required this.isDeleted,
    required this.name,
    required this.postIds,
    required this.updatedAt,
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
