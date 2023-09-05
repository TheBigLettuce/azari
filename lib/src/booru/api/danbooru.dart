// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/schemas/post.dart';

import '../interface.dart';
import '../tags/tags.dart';

List<String> _fromDanbooruTags(List<dynamic> l) =>
    l.map((e) => e["name"] as String).toList();

class Danbooru implements BooruAPI {
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
  Future<List<String>> completeTag(String tag) async {
    final resp = await client.getUri(
      Uri.https(booru.url, "/tags.json", {
        "search[name_matches]": "$tag*",
        "search[order]": "count",
        "limit": "10",
      }),
    );

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return _fromDanbooruTags(resp.data);
  }

  @override
  Future<Post> singlePost(int id) async {
    try {
      final resp = await client.getUri(Uri.https(booru.url, "/posts/$id.json"));

      if (resp.statusCode != 200) {
        throw resp.data["message"];
      }

      if (resp.data == null) {
        throw "no post";
      }

      return (await _fromJson([resp.data], null))[0];
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
  Future<List<Post>> page(int i, String tags, BooruTagging excludedTags) =>
      _commonPosts(tags, excludedTags, page: i);

  @override
  Future<List<Post>> fromPost(
          int postId, String tags, BooruTagging excludedTags) =>
      _commonPosts(tags, excludedTags, postid: postId);

  Future<List<Post>> _commonPosts(String tags, BooruTagging excludedTags,
      {int? postid, int? page}) async {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    // anonymous api calls to danbooru are limited by two tags per search req
    tags = tags.split(" ").take(2).join(" ");

    final query = <String, dynamic>{
      "limit": BooruAPI.numberOfElementsPerRefresh().toString(),
      "format": "json",
      "post[tags]": "${BooruAPI.isSafeModeEnabled() ? 'rating:g' : ''} $tags",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    try {
      final resp =
          await client.getUri(Uri.https(booru.url, "/posts.json", query));

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

  Future<List<Post>> _fromJson(
      List<dynamic> m, BooruTagging? excludedTags) async {
    final List<Post> list = [];
    final exclude = excludedTags?.get();

    for (final e in m) {
      try {
        final String tags = e["tag_string"];
        if (exclude != null) {
          for (final tag in exclude) {
            if (tags.contains(tag.tag)) {
              continue;
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
            tags: tags,
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

    return list;
  }

  @override
  void close() => client.close(force: true);

  Danbooru(this.client, this.cookieJar, {this.booru = Booru.danbooru});
}
