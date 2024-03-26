// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru/strip_html.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../../db/schemas/booru/post.dart';
import 'package:intl/intl.dart';

import '../../interfaces/booru_tagging.dart';

const Duration _defaultTimeout = Duration(seconds: 30);

abstract class BooruRespDecoder {
  const BooruRespDecoder();

  (List<Post>, int?) posts(dynamic m, Booru booru);
  Iterable<String> notes(dynamic data);
  List<String> tags(dynamic l);
}

class GelbooruRespDecoder implements BooruRespDecoder {
  const GelbooruRespDecoder();

  @override
  List<String> tags(dynamic data) {
    final l = data["tag"];
    if (l == null) {
      return const [];
    }

    return (l as List<dynamic>)
        .map((e) => HtmlUnescape().convert(e["name"] as String))
        .toList();
  }

  @override
  Iterable<String> notes(dynamic data) {
    final doc = XmlDocument.parse(data);

    return doc.children.first.children.map(
      (e) => stripHtml(e.getAttribute("body")!),
    );
  }

  @override
  (List<Post>, int?) posts(dynamic data, Booru booru) {
    final json = data["post"];
    if (json == null) {
      return (<Post>[], null);
    }

    final List<Post> list = [];

    final dateFormatter = DateFormat("EEE MMM dd HH:mm:ss");

    final escaper = HtmlUnescape();

    for (final post in json as List<dynamic>) {
      String createdAt = post["created_at"];
      DateTime date = dateFormatter.parse(createdAt).copyWith(
          year: int.tryParse(createdAt.substring(createdAt.length - 4)));

      final rating = post["rating"];

      list.add(Post(
          height: post["height"],
          booru: booru,
          id: post["id"],
          md5: post["md5"],
          tags: (post["tags"].split(" ") as List<String>)
              .map((e) => escaper.convert(e))
              .toList(),
          score: post["score"],
          sourceUrl: post["source"],
          createdAt: date,
          rating: rating == null
              ? PostRating.general
              : switch (rating as String) {
                  "general" => PostRating.general,
                  "sensitive" => PostRating.sensitive,
                  "questionable" => PostRating.questionable,
                  "explicit" => PostRating.explicit,
                  String() => PostRating.general,
                },
          width: post["width"],
          fileUrl: post["file_url"],
          previewUrl: post["preview_url"],
          ext: path.extension(post["image"]),
          sampleUrl: post["sample_url"] == ""
              ? post["file_url"]
              : post["sample_url"]));
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
  final bool wouldBecomeStale = true;

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
  Future<List<String>> completeTag(String t) async {
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
        "orderby": "count"
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
        switch (overrideSafeMode ?? Settings.fromDb().safeMode) {
      SafeMode.none => "",
      SafeMode.normal => 'rating:general',
      SafeMode.relaxed => '-rating:explicit -rating:questionable',
    };

    final query = <String, dynamic>{
      "page": "dapi",
      "s": "post",
      "q": "index",
      "pid": p.toString(),
      "json": "1",
      "tags": "$safeMode $excludedTagsString $tags",
      "limit": BooruAPI.numberOfElementsPerRefresh().toString()
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
      Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "post",
        "q": "index",
        "id": id.toString(),
        "json": "1"
      }),
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
