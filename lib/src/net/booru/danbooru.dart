// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/db/schemas/booru/post.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru/strip_html.dart';
import 'package:gallery/src/logging/logging.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../../db/schemas/settings/settings.dart';
import '../../interfaces/booru/booru_api_state.dart';
import '../../interfaces/booru_tagging.dart';
import '../cloudflare_exception.dart';
import '../unsaveable_cookie_jar.dart';

List<String> _fromDanbooruTags(List<dynamic> l) =>
    l.map((e) => e["name"] as String).toList();

class Danbooru implements BooruAPIState {
  static const _log = LogTarget.booru;

  final UnsaveableCookieJar cookieJar;

  @override
  void setCookies(List<Cookie> cookies) {
    cookieJar.replaceDirectly(Uri.parse(booru.url), cookies);
  }

  @override
  final Dio client;

  @override
  final Booru booru;

  @override
  final int? currentPage = null;

  @override
  final bool wouldBecomeStale = false;

  @override
  Uri browserLink(int id) => Uri.https(booru.url, "/posts/$id");

  @override
  Uri browserLinkSearch(String tags) =>
      Uri.https(booru.url, "/posts?tags=$tags");

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUriLog(
        Uri.https(booru.url, "/notes.json", {
          "search[post_id]": postId.toString(),
        }),
        LogReq(LogReq.notes(booru, postId), _log));

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return Future.value(
        (resp.data as List<dynamic>).map((e) => stripHtml(e["body"])));
  }

  @override
  Future<List<String>> completeTag(String tag) async {
    if (tag.isEmpty) {
      return const [];
    }

    final resp = await client.getUriLog(
        Uri.https(booru.url, "/tags.json", {
          "search[name_matches]": "$tag*",
          "search[order]": "count",
          "limit": "10",
        }),
        LogReq(LogReq.completeTag(booru, tag), _log));

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return _fromDanbooruTags(resp.data);
  }

  @override
  Future<Post> singlePost(int id) async {
    try {
      final resp = await client.getUriLog(
          Uri.https(booru.url, "/posts/$id.json"),
          LogReq(LogReq.singlePost(booru, id), _log));

      if (resp.statusCode != 200) {
        throw resp.data["message"];
      }

      if (resp.data == null) {
        throw "no post";
      }

      return (await _fromJson([resp.data], null)).$1[0];
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return Future.error(CloudflareException());
        }
      }
      return Future.error(e);
    }
  }

  @override
  Future<(List<Post>, int?)> page(int i, String tags, BooruTagging excludedTags,
          {SafeMode? overrideSafeMode}) =>
      _commonPosts(tags, excludedTags,
          page: i, overrideSafeMode: overrideSafeMode);

  @override
  Future<(List<Post>, int?)> fromPost(
          int postId, String tags, BooruTagging excludedTags,
          {SafeMode? overrideSafeMode}) =>
      _commonPosts(tags, excludedTags,
          postid: postId, overrideSafeMode: overrideSafeMode);

  Future<(List<Post>, int?)> _commonPosts(
      String tags, BooruTagging excludedTags,
      {int? postid, int? page, required SafeMode? overrideSafeMode}) async {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    // anonymous api calls to danbooru are limited by two tags per search req
    tags = tags.split(" ").take(2).join(" ");

    String safeModeS() =>
        switch (overrideSafeMode ?? Settings.fromDb().safeMode) {
          SafeMode.normal => "rating:g",
          SafeMode.none => '',
          SafeMode.relaxed => "rating:g,s",
        };

    final query = <String, dynamic>{
      "limit": BooruAPIState.numberOfElementsPerRefresh().toString(),
      "format": "json",
      "post[tags]": "${safeModeS()} $tags",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    try {
      final resp = await client.getUriLog(
          Uri.https(booru.url, "/posts.json", query),
          LogReq(
              postid != null
                  ? LogReq.singlePost(booru, postid)
                  : LogReq.page(booru, page!),
              _log));

      if (resp.statusCode != 200) {
        throw "status not ok";
      }

      return _fromJson(resp.data, excludedTags);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return Future.error(CloudflareException());
        }
      }

      return Future.error(e);
    }
  }

  Future<(List<Post>, int?)> _fromJson(
      List<dynamic> m, BooruTagging? excludedTags) async {
    final List<Post> list = [];
    int? currentSkipped;
    final exclude = excludedTags?.get();

    final escaper = HtmlUnescape();

    outer:
    for (final e in m) {
      try {
        final String tags = e["tag_string"];
        if (exclude != null) {
          for (final tag in exclude) {
            if (tags.contains(tag.tag)) {
              currentSkipped = e["id"];
              continue outer;
            }
          }
        }

        final post = Post(
            height: e["image_height"],
            id: e["id"],
            score: e["score"],
            sourceUrl: e["source"],
            rating: e["rating"] ?? "?",
            createdAt: DateTime.parse(e["created_at"]),
            md5: e["md5"],
            tags: tags.split(" ").map((e) => escaper.convert(e)).toList(),
            width: e["image_width"],
            fileUrl: e["file_url"],
            previewUrl: e["preview_file_url"],
            sampleUrl: e["large_file_url"],
            ext: ".${e["file_ext"]}",
            prefix: booru.prefix);

        list.add(post);
      } catch (_) {
        continue;
      }
    }

    return (list, currentSkipped);
  }

  @override
  void close() => client.close(force: true);

  Danbooru(this.client, this.cookieJar, {this.booru = Booru.danbooru});
}
