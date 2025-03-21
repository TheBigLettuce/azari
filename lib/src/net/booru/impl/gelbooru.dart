// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logging/logging.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/impl/conventers/gelbooru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/booru/strip_html.dart";
import "package:azari/src/services/services.dart";
import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:xml/xml.dart";

const Duration _defaultTimeout = Duration(seconds: 30);

class Gelbooru implements BooruAPI {
  const Gelbooru(
    this.client, {
    this.booru = Booru.gelbooru,
  });

  static final _log = Logger("Gelbooru API");

  final Dio client;

  @override
  final Booru booru;

  @override
  bool get wouldBecomeStale => true;

  @override
  Future<int> totalPosts(String tags, SafeMode safeMode) async {
    final res = await _commonPosts(
      tags,
      0,
      null,
      safeMode,
      limit: 1,
      order: BooruPostsOrder.latest,
    );

    return res.$1.firstOrNull?.id ?? 0;
  }

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUriLog<String>(
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "note",
        "q": "index",
        "post_id": postId.toString(),
      }),
      LogReq(LogReq.notes(postId), _log),
      options: Options(
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.plain,
      ),
    );

    final doc = XmlDocument.parse(resp.data!);

    return doc.children.first.children.map(
      (e) => stripHtml(e.getAttribute("body")!),
    );
  }

  @override
  Future<List<BooruTag>> searchTag(
    String t, [
    BooruTagSorting sorting = BooruTagSorting.count,
    int limit = 30,
  ]) async {
    final resp = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "tag",
        "q": "index",
        "limit": t.isEmpty && sorting == BooruTagSorting.count
            ? 100.toString()
            : limit.toString(),
        "json": "1",
        "name_pattern": "$t%",
        "orderby": sorting == BooruTagSorting.count ? "count" : "name",
      }),
      options: Options(
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.completeTag(t), _log),
    );

    final tags = GelbooruTagsRet.fromJson(
      resp.data!,
      t.isEmpty && sorting == BooruTagSorting.count,
    ).posts;

    return tags.length > 30 ? tags.take(limit).toList() : tags;
  }

  @override
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    BooruTagging<Excluded>? excludedTags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  }) {
    return _commonPosts(
      tags,
      p,
      excludedTags,
      safeMode,
      limit: limit,
      order: order,
    ).then((v) {
      pageSaver.page = p;

      return v;
    });
  }

  Future<(List<Post>, int?)> _commonPosts(
    String tags,
    int p,
    BooruTagging<Excluded>? excludedTags,
    SafeMode safeMode, {
    int? limit,
    required BooruPostsOrder order,
  }) async {
    final excluded = excludedTags?.get(-1).map((e) => "-${e.tag} ").toList();

    final String excludedTagsString = excluded == null
        ? ""
        : switch (excluded.isNotEmpty) {
            true => excluded.reduce((value, element) => value + element),
            false => "",
          };

    final String safeMode_ = switch (safeMode) {
      SafeMode.none => "",
      SafeMode.normal => "rating:general",
      SafeMode.relaxed => "-rating:explicit -rating:questionable",
      SafeMode.explicit => "rating:explicit",
    };

    final query = <String, dynamic>{
      "page": "dapi",
      "s": "post",
      "q": "index",
      "pid": p.toString(),
      "json": "1",
      "tags":
          "${order == BooruPostsOrder.score ? 'sort:score' : ''} $safeMode_ $excludedTagsString $tags",
      "limit": limit?.toString() ?? refreshPostCountLimit().toString(),
    };

    final resp = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(booru.url, "/index.php", query),
      options: Options(
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.page(p, tags: tags, safeMode: safeMode), _log),
    );

    return resp.data!["post"] == null
        ? (<Post>[], null)
        : (GelbooruPostRet.fromJson(resp.data!).posts, null);
  }

  @override
  Future<Post> singlePost(int id) async {
    final resp = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(
        booru.url,
        "/index.php",
        {
          "page": "dapi",
          "s": "post",
          "q": "index",
          "id": id.toString(),
          "json": "1",
        },
      ),
      options: Options(
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.singlePost(id, tags: "", safeMode: SafeMode.none), _log),
    );

    final ret = GelbooruPostRet.fromJson(resp.data!);

    return ret.posts.first;
  }

  @override
  Future<List<Post>> randomPosts(
    BooruTagging<Excluded>? excludedTags,
    SafeMode safeMode,
    bool videosOnly, {
    RandomPostsOrder order = RandomPostsOrder.random,
    String addTags = "",
    int page = 0,
  }) async {
    final p = await this.page(
      page,
      "${order == RandomPostsOrder.random ? 'sort:random' : ''}"
      "${videosOnly ? ' video' : ''}"
      " $addTags",
      excludedTags,
      safeMode,
      limit: 30,
      order: switch (order) {
        RandomPostsOrder.random ||
        RandomPostsOrder.latest =>
          BooruPostsOrder.latest,
        RandomPostsOrder.rating => BooruPostsOrder.score,
      },
      pageSaver: PageSaver.noPersist(),
    );

    return p.$1;
  }

  @override
  Future<(List<Post>, int?)> fromPostId(
    int _,
    String tags,
    BooruTagging<Excluded>? excludedTags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  }) {
    final f = _commonPosts(
      tags,
      pageSaver.page + 1,
      excludedTags,
      safeMode,
      limit: limit,
      order: order,
    );

    return f.then((value) {
      if (value.$1.isNotEmpty) {
        pageSaver.page += 1;
      }
      return Future.value(value);
    });
  }
}

class GelbooruCommunity implements BooruComunnityAPI {
  GelbooruCommunity({
    required this.booru,
    required this.client,
  })  : forum = _ForumAPI(client),
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

  // @override
  // final BooruWikiAPI wiki;
}

class _PoolsAPI implements BooruPoolsAPI {
  const _PoolsAPI(this.client);

  final Dio client;

  @override
  Future<List<BooruPool>> search({
    int? limit,
    String? name,
    BooruPoolCategory? category,
    BooruPoolsOrder order = BooruPoolsOrder.creationTime,
    required PageSaver pageSaver,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, String>> poolThumbnails(List<BooruPool> pools) {
    throw UnimplementedError();
  }
}

class _CommentsAPI implements BooruCommentsAPI {
  const _CommentsAPI(this.client);

  final Dio client;

  @override
  Future<List<BooruComments>> forPostId({
    required int postId,
    int? limit,
    required PageSaver pageSaver,
  }) {
    // TODO: implement when unlocked
    return Future.value(const []);
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
