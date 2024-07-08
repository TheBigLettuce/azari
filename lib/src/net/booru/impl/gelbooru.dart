// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/logging/logging.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/net/booru/impl/conventers/gelbooru.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/booru/strip_html.dart";
import "package:logging/logging.dart";
import "package:xml/xml.dart";

const Duration _defaultTimeout = Duration(seconds: 30);

class Gelbooru implements BooruAPI {
  const Gelbooru(
    this.client,
    this.pageSaver, {
    this.booru = Booru.gelbooru,
  });

  static final _log = Logger("Gelbooru API");

  final Dio client;
  final PageSaver pageSaver;

  @override
  final Booru booru;

  @override
  bool get wouldBecomeStale => true;

  @override
  Future<int> totalPosts(String tags, SafeMode safeMode) async {
    final res = await _commonPosts(tags, 0, null, safeMode, limit: 1);

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
    // if (t.isEmpty) {
    //   return const [];
    // }

    final resp = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "tag",
        "q": "index",
        "limit": limit.toString(),
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

    return GelbooruTagsRet.fromJson(resp.data!).posts;
  }

  @override
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode, [
    int? limit,
  ]) {
    pageSaver.page = p;

    return _commonPosts(
      tags,
      p,
      excludedTags,
      safeMode,
      limit: limit,
    );
  }

  Future<(List<Post>, int?)> _commonPosts(
    String tags,
    int p,
    BooruTagging? excludedTags,
    SafeMode safeMode, {
    int? limit,
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
    };

    final query = <String, dynamic>{
      "page": "dapi",
      "s": "post",
      "q": "index",
      "pid": p.toString(),
      "json": "1",
      "tags": "$safeMode_ $excludedTagsString $tags",
      "limit": limit?.toString() ?? numberOfElementsPerRefresh().toString(),
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
  Future<(List<Post>, int?)> fromPost(
    int _,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode, [
    int? limit,
  ]) {
    final f = _commonPosts(
      tags,
      pageSaver.page + 1,
      excludedTags,
      safeMode,
      limit: limit,
    );

    return f.then((value) {
      if (value.$1.isNotEmpty) {
        pageSaver.page += 1;
      }
      return Future.value(value);
    });
  }
}
