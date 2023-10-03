// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../../db/schemas/post.dart';
import 'package:intl/intl.dart';

import '../../interfaces/tags.dart';

List<String> _fromGelbooruTags(List<dynamic> l) {
  return l.map((e) => HtmlUnescape().convert(e["name"] as String)).toList();
}

class Gelbooru implements BooruAPI {
  final UnsaveableCookieJar cookieJar;

  @override
  final Dio client;

  @override
  final Booru booru;

  @override
  int? get currentPage => _page;

  @override
  final bool wouldBecomeStale = true;

  int _page = 0;

  @override
  void setCookies(List<Cookie> cookies) {
    cookieJar.replaceDirectly(Uri.parse(booru.url), cookies);
  }

  @override
  Uri browserLink(int id) => Uri.https(booru.url, "/index.php", {
        "page": "post",
        "s": "view",
        "id": id.toString(),
      });

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUri(
        Uri.https(booru.url, "/index.php", {
          "page": "dapi",
          "s": "note",
          "q": "index",
          "post_id": postId.toString(),
        }),
        options: Options(
          responseType: ResponseType.plain,
        ));

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    final doc = XmlDocument.parse(resp.data);

    return doc.children.first.children
        .map((e) => stripHtml(e.getAttribute("body")!));
  }

  @override
  Future<List<String>> completeTag(String t) async {
    final resp = await client.getUri(Uri.https(booru.url, "/index.php", {
      "page": "dapi",
      "s": "tag",
      "q": "index",
      "limit": "10",
      "json": "1",
      "name_pattern": "$t%",
      "orderby": "count"
    }));

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return _fromGelbooruTags(resp.data["tag"]);
  }

  @override
  Future<(List<Post>, int?)> page(
      int p, String tags, BooruTagging excludedTags) {
    _page = p + 1;
    return _commonPosts(tags, p, excludedTags);
  }

  Future<(List<Post>, int?)> _commonPosts(
      String tags, int p, BooruTagging excludedTags) async {
    late final String excludedTagsString;

    final excluded = excludedTags.get().map((e) => "-${e.tag} ").toList();
    if (excluded.isNotEmpty) {
      excludedTagsString = excluded.reduce((value, element) => value + element);
    } else {
      excludedTagsString = "";
    }

    String safeModeS() => switch (Settings.fromDb().safeMode) {
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
      "tags": "${safeModeS()} $excludedTagsString $tags",
      "limit": BooruAPI.numberOfElementsPerRefresh().toString()
    };

    try {
      final resp =
          await client.getUri(Uri.https(booru.url, "/index.php", query));

      if (resp.statusCode != 200) {
        throw "status not 200";
      }

      final json = resp.data["post"];
      if (json == null) {
        return Future.value((<Post>[], null));
      }

      return _fromJson(json);
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
  Future<Post> singlePost(int id) async {
    try {
      final resp = await client.getUri(Uri.https(booru.url, "/index.php", {
        "page": "dapi",
        "s": "post",
        "q": "index",
        "id": id.toString(),
        "json": "1"
      }));

      if (resp.statusCode != 200) {
        throw "status is not 200";
      }

      final json = resp.data["post"];
      if (json == null) {
        throw "The post has been not found.";
      }

      return _fromJson([json[0]]).$1[0];
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
  Future<(List<Post>, int?)> fromPost(
          int _, String tags, BooruTagging excludedTags) =>
      _commonPosts(tags, _page, excludedTags).then((value) {
        if (value.$1.isNotEmpty) {
          _page++;
        }
        return Future.value(value);
      });

  (List<Post>, int?) _fromJson(List<dynamic> m) {
    final List<Post> list = [];

    final dateFormatter = DateFormat("EEE MMM dd HH:mm:ss");

    for (final post in m) {
      String createdAt = post["created_at"];
      DateTime date = dateFormatter.parse(createdAt).copyWith(
          year: int.tryParse(createdAt.substring(createdAt.length - 4)));

      list.add(Post(
          height: post["height"],
          prefix: booru.prefix,
          id: post["id"],
          md5: post["md5"],
          tags: post["tags"].split(" "),
          score: post["score"],
          sourceUrl: post["source"],
          createdAt: date,
          rating: post["rating"],
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

  @override
  void close() => client.close(force: true);

  Gelbooru(int page, this.client, this.cookieJar, {this.booru = Booru.gelbooru})
      : _page = page;
}
