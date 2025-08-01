// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/logging/logging.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/net/booru/impl/conventers/danbooru.dart";
import "package:azari/src/logic/net/booru/strip_html.dart";
import "package:azari/src/logic/net/cloudflare_exception.dart";
import "package:azari/src/services/services.dart";
import "package:dio/dio.dart";
import "package:logging/logging.dart";

class Danbooru implements BooruAPI {
  const Danbooru(this.client, {this.booru = Booru.danbooru});

  static final _log = Logger("Danbooru API");

  final Dio client;

  @override
  final Booru booru;

  @override
  bool get wouldBecomeStale => false;

  Map<String, String> get loginApiKey {
    final data = const AccountsService().current;

    if (data.danbooruApiKey.isEmpty && data.danbooruUsername.isEmpty) {
      return const {};
    }

    return {"login": data.danbooruUsername, "api_key": data.danbooruApiKey};
  }

  @override
  Future<int> totalPosts(String tags, SafeMode safeMode) async {
    final resp = await _commonPosts(
      "",
      safeMode: SafeMode.none,
      page: 0,
      limit: 1,
      order: BooruPostsOrder.latest,
      ignoreExcludedTags: true,
    );

    return resp.$1.firstOrNull?.id ?? 0;
  }

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(booru.url, "/notes.json", {
        ...loginApiKey,
        "search[post_id]": postId.toString(),
      }),
      LogReq(LogReq.notes(postId), _log),
    );

    return (resp.data!).map((e) => stripHtml((e as Map)["body"] as String));
  }

  @override
  Future<List<TagData>> searchTag(
    String tag, [
    BooruTagSorting sorting = BooruTagSorting.count,
    int limit = 30,
  ]) async {
    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(booru.url, "/tags.json", {
        ...loginApiKey,
        "search[name_matches]": "$tag*",
        "search[order]": sorting == BooruTagSorting.count ? "count" : "name",
        "limit": limit.toString(),
      }),
      LogReq(LogReq.completeTag(tag), _log),
    );

    return resp.data!
        .map(
          (e) => TagData(
            tag: (e as Map<String, dynamic>)["name"] as String,
            count: e["post_count"] as int,
            type: TagType.normal,
            time: null,
          ),
        )
        .toList();
  }

  @override
  Future<Post> singlePost(int id) async {
    final resp = await client.getUriLog<dynamic>(
      Uri.https(booru.url, "/posts/$id.json", loginApiKey),
      LogReq(LogReq.singlePost(id, tags: "", safeMode: SafeMode.none), _log),
    );

    if (resp.data == null) {
      throw "no post";
    }

    return fromList([resp.data])[0];
  }

  @override
  Future<List<Post>> randomPosts(
    SafeMode safeMode,
    bool videosOnly, {
    RandomPostsOrder order = RandomPostsOrder.random,
    String addTags = "",
    int page = 0,
  }) async {
    // Danbooru limits anon users to 2 tags per search
    // this maakes impossible to make random videos with tags on Danbooru
    // instead, show only latest videos if addTags is not empty
    //
    // free metatags don't even include order...

    final p = await this.page(
      order == RandomPostsOrder.random ? 0 : page,
      addTags.isNotEmpty && videosOnly
          ? "video $addTags"
          : "${order == RandomPostsOrder.random ? 'random:30' : ''}"
                    "${videosOnly ? ' video' : ''}"
                    " $addTags"
                .trim(),
      safeMode,
      limit: 30,
      order: addTags.isNotEmpty && videosOnly
          ? BooruPostsOrder.latest
          : switch (order) {
              RandomPostsOrder.random ||
              RandomPostsOrder.latest => BooruPostsOrder.latest,
              RandomPostsOrder.rating => BooruPostsOrder.score,
            },
      pageSaver: PageSaver.noPersist(),
    );

    return p.$1;
  }

  @override
  Future<(List<Post>, int?)> page(
    int i,
    String tags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  }) =>
      _commonPosts(
        tags,
        page: i,
        safeMode: safeMode,
        limit: limit,
        order: order,
        ignoreExcludedTags: false,
      ).then((v) {
        pageSaver.page = i;

        return v;
      });

  @override
  Future<(List<Post>, int?)> fromPostId(
    int postId,
    String tags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  }) => _commonPosts(
    tags,
    postid: postId,
    safeMode: safeMode,
    limit: limit,
    order: order,
    ignoreExcludedTags: false,
  );

  Future<(List<Post>, int?)> _commonPosts(
    String tags, {
    int? postid,
    int? page,
    required SafeMode safeMode,
    int? limit,
    required BooruPostsOrder order,
    required bool ignoreExcludedTags,
  }) async {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    final excludedTags = ignoreExcludedTags
        ? null
        : TagManagerService.safe()?.excluded;

    String safeModeS() => switch (safeMode) {
      SafeMode.normal => "rating:g",
      SafeMode.none => "",
      SafeMode.relaxed => "rating:g,s",
      SafeMode.explicit => "rating:q,e",
    };

    final query = <String, dynamic>{
      ...loginApiKey,
      "limit": limit?.toString() ?? refreshPostCountLimit().toString(),
      "format": "json",

      /// anonymous api calls to danbooru are limited by two tags per search req
      "post[tags]":
          "${order == BooruPostsOrder.score ? 'order:score' : ''} ${safeModeS()} ${tags.split(" ").take(2).join(" ")}",

      if (postid != null) "page": "b$postid",
      if (page != null) "page": (page + 1).toString(),

      "only":
          "id,tag_string,md5,image_width,image_height,file_url,preview_file_url,large_file_url,source,rating,score,file_size,created_at,media_asset[variants[type,url]]",
    };

    try {
      final resp = await client.getUriLog<List<dynamic>>(
        Uri.https(booru.url, "/posts.json", query),
        LogReq(
          postid != null
              ? LogReq.singlePost(postid, tags: tags, safeMode: safeMode)
              : LogReq.page(page!, tags: tags, safeMode: safeMode),
          _log,
        ),
      );

      return excludedTags == null
          ? (fromList(resp.data!), null)
          : _skipExcluded(fromList(resp.data!), excludedTags);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return Future.error(CloudflareException());
        }
      }

      return Future.error(e);
    }
  }
}

(List<Post>, int?) _skipExcluded(
  List<Post> posts,
  BooruTagging<Excluded> excludedTags,
) {
  final exclude = excludedTags.get(-1);

  if (exclude.isEmpty) {
    return (posts, null);
  }

  int? currentSkipped;

  posts.removeWhere((e) {
    for (final tag in exclude) {
      if (e.tags.contains(tag.tag)) {
        currentSkipped = e.id;
        return true;
      }
    }

    return false;
  });

  return (posts, currentSkipped);
}

class DanbooruCommunity implements BooruCommunityAPI {
  DanbooruCommunity({required this.booru, required this.client})
    : forum = _ForumAPI(client),
      comments = _CommentsAPI(client),
      pools = _PoolsAPI(client);

  @override
  final Booru booru;

  final Dio client;

  @override
  final BooruCommentsAPI comments;

  @override
  final BooruForumAPI forum;

  @override
  final BooruPoolsAPI pools;
}

class _PoolsAPI implements BooruPoolsAPI {
  const _PoolsAPI(this.client);

  static final _log = Logger("Danbooru Pools API");

  final Dio client;

  @override
  Future<List<BooruPool>> search({
    int? limit,
    String? name,
    BooruPoolCategory? category,
    BooruPoolsOrder order = BooruPoolsOrder.creationTime,
    required PageSaver pageSaver,
  }) async {
    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(Booru.danbooru.url, "/pools.json", {
        "search[order]": switch (order) {
          BooruPoolsOrder.name => "name",
          BooruPoolsOrder.latest => "updated_at",
          BooruPoolsOrder.creationTime => "created_at",
          BooruPoolsOrder.postCount => "post_count",
        },
        if (category != null)
          "search[category]": switch (category) {
            BooruPoolCategory.series => "series",
            BooruPoolCategory.collection => "collection",
          },
        if (name != null) "search[name_matches]": "$name*",
        "page": pageSaver.page.toString(),
        if (limit != null) "limit": limit.toString(),
      }),
      LogReq("search, name: $name", _log),
    );

    return fromListPools(resp.data!);
  }

  @override
  Future<Map<int, String>> poolThumbnails(List<BooruPool> pools) async {
    if (pools.isEmpty) {
      return const {};
    }

    final idToPoolMap = <int, int>{};
    for (final e in pools) {
      if (e.postIds.isNotEmpty) {
        idToPoolMap[e.postIds.first] = e.id;
      }
    }

    final stringBuffer = StringBuffer("id:")
      ..writeAll(
        pools
            .where((e) => e.postIds.isNotEmpty)
            .map((e) => e.postIds.first.toString()),
        ",",
      );

    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(Booru.danbooru.url, "/posts.json", {
        "post[tags]": stringBuffer.toString(),
        "only": "id,preview_file_url,large_file_url",
      }),
      LogReq("poolThumbnails", _log),
    );

    return resp.data!.fold<Map<int, String>>({}, (map, e) {
      final preview = (e as Map)["preview_file_url"] as String?;
      // final large = e["large_file_url"] as String?;

      final id = idToPoolMap[e["id"] as int];

      if (preview != null && id != null) {
        map[id] = preview;
      }
      return map;
    });
  }
}

class _CommentsAPI implements BooruCommentsAPI {
  const _CommentsAPI(this.client);

  final Dio client;

  static final _log = Logger("Danbooru Comments API");

  @override
  Future<List<BooruComments>> forPostId({
    required int postId,
    int? limit,
    required PageSaver pageSaver,
  }) async {
    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(Booru.danbooru.url, "/comments.json", {
        "post_id": postId.toString(),
        "group_by": "comment",
        "only": "is_sticky,id,post_id,updated_at,score,body",
      }),
      LogReq("forPostId, id: $postId", _log),
    );

    return fromListComments(resp.data!);
  }

  @override
  Future<List<BooruComments>> search({
    int? limit,
    BooruCommentsOrder order = BooruCommentsOrder.latest,
    required PageSaver pageSaver,
  }) {
    throw UnimplementedError();
  }
}

class _ForumAPI implements BooruForumAPI {
  const _ForumAPI(this.client);

  final Dio client;

  @override
  Future<List<BooruForumPost>> postsForId({
    required int id,
    int? limit,
    BooruForumCategory? category,
    required PageSaver pageSaver,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<BooruForumTopic>> searchTopic({
    int? limit,
    String? title,
    BooruForumCategory? category,
    BooruForumTopicsOrder order = BooruForumTopicsOrder.postCount,
    required PageSaver pageSaver,
  }) {
    throw UnimplementedError();
  }
}
