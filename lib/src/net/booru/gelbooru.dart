// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/schemas/booru/post.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/booru/strip_html.dart";
import "package:gallery/src/interfaces/booru_tagging.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:html_unescape/html_unescape_small.dart";
import "package:intl/intl.dart";
import "package:path/path.dart" as path;
import "package:xml/xml.dart";

const Duration _defaultTimeout = Duration(seconds: 30);

abstract class BooruRespDecoder {
  const BooruRespDecoder();

  (List<Post>, int?) posts(dynamic m, Booru booru);
  Iterable<String> notes(dynamic data);
  List<BooruTag> tags(dynamic l);
}

class GelbooruRespDecoder implements BooruRespDecoder {
  const GelbooruRespDecoder();

  @override
  List<BooruTag> tags(dynamic data) {
    final l =
        (data as Map<String, dynamic>)["tag"] as List<Map<String, dynamic>>?;
    if (l == null) {
      return const [];
    }

    return l
        .map(
          (e) => BooruTag(
            HtmlUnescape().convert(e["name"] as String),
            e["count"] as int,
          ),
        )
        .toList();
  }

  @override
  Iterable<String> notes(dynamic data) {
    final doc = XmlDocument.parse(data as String);

    return doc.children.first.children.map(
      (e) => stripHtml(e.getAttribute("body")!),
    );
  }

  @override
  (List<Post>, int?) posts(dynamic data, Booru booru) {
    final json = (data as Map<String, dynamic>)["post"];
    if (json == null) {
      return (<Post>[], null);
    }

    final List<Post> list = [];

    final dateFormatter = DateFormat("EEE MMM dd HH:mm:ss");

    final escaper = HtmlUnescape();

    for (final post in json as List<Map<String, dynamic>>) {
      final createdAt = post["created_at"] as String;
      final date = dateFormatter.parse(createdAt).copyWith(
            year: int.tryParse(createdAt.substring(createdAt.length - 4)),
          );

      final rating = post["rating"] as String?;

      list.add(
        Post(
          height: post["height"] as int,
          booru: booru,
          id: post["id"] as int,
          md5: post["md5"] as String,
          tags: (post["tags"] as String)
              .split(" ")
              .map((e) => escaper.convert(e))
              .toList(),
          score: post["score"] as int,
          sourceUrl: post["source"] as String,
          createdAt: date,
          rating: rating == null
              ? PostRating.general
              : switch (rating) {
                  "general" => PostRating.general,
                  "sensitive" => PostRating.sensitive,
                  "questionable" => PostRating.questionable,
                  "explicit" => PostRating.explicit,
                  String() => PostRating.general,
                },
          width: post["width"] as int,
          fileUrl: post["file_url"] as String,
          previewUrl: post["preview_url"] as String,
          ext: path.extension(post["image"] as String),
          sampleUrl: (post["sample_url"] as String) == ""
              ? post["file_url"] as String
              : post["sample_url"] as String,
        ),
      );
    }

    return (list, null);
  }
}

class Gelbooru implements BooruAPI {
  const Gelbooru(
    this.client,
    this.pageSaver, {
    this.booru = Booru.gelbooru,
  });

  static const _log = LogTarget.booru;
  static const _decoder = GelbooruRespDecoder();

  final Dio client;
  final PageSaver pageSaver;

  @override
  final Booru booru;

  @override
  bool get wouldBecomeStale => true;

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUriLog(
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "note",
        "q": "index",
        "post_id": postId.toString(),
      }),
      LogReq(LogReq.notes(booru, postId), _log),
      options: Options(
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.plain,
      ),
    );

    return _decoder.notes(resp.data);
  }

  @override
  Future<List<BooruTag>> completeTag(String t) async {
    if (t.isEmpty) {
      return const [];
    }

    final resp = await client.getUriLog(
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "tag",
        "q": "index",
        "limit": "30",
        "json": "1",
        "name_pattern": "$t%",
        "orderby": "count",
      }),
      options: Options(
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.completeTag(booru, t), _log),
    );

    return _decoder.tags(resp.data);
  }

  @override
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    BooruTagging excludedTags, {
    SafeMode? overrideSafeMode,
  }) {
    pageSaver.save(p);

    return _commonPosts(
      tags,
      p,
      excludedTags,
      overrideSafeMode: overrideSafeMode,
    );
  }

  Future<(List<Post>, int?)> _commonPosts(
    String tags,
    int p,
    BooruTagging excludedTags, {
    required SafeMode? overrideSafeMode,
  }) async {
    final excluded = excludedTags.get(-1).map((e) => "-${e.tag} ").toList();

    final String excludedTagsString = switch (excluded.isNotEmpty) {
      true => excluded.reduce((value, element) => value + element),
      false => "",
    };

    final String safeMode =
        switch (overrideSafeMode ?? SettingsService.currentData.safeMode) {
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
      "tags": "$safeMode $excludedTagsString $tags",
      "limit": BooruAPI.numberOfElementsPerRefresh().toString(),
    };

    final resp = await client.getUriLog(
      Uri.https(booru.url, "/index.php", query),
      options: Options(
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.page(booru, p), _log),
    );

    return _decoder.posts(resp.data, booru);
  }

  @override
  Future<Post> singlePost(int id) async {
    final resp = await client.getUriLog(
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
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
      LogReq(LogReq.singlePost(booru, id), _log),
    );

    return _decoder.posts(resp.data, booru).$1.first;
  }

  @override
  Future<(List<Post>, int?)> fromPost(
    int _,
    String tags,
    BooruTagging excludedTags, {
    SafeMode? overrideSafeMode,
  }) {
    final f = _commonPosts(
      tags,
      pageSaver.current + 1,
      excludedTags,
      overrideSafeMode: overrideSafeMode,
    );

    return f.then((value) {
      if (value.$1.isNotEmpty) {
        pageSaver.save(pageSaver.current + 1);
      }
      return Future.value(value);
    });
  }
}
