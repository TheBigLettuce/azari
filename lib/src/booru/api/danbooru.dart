// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:gallery/src/schemas/post.dart';

import '../interface.dart';
import '../tags/tags.dart';

List<String> _fromDanbooruTags(List<dynamic> l) =>
    l.map((e) => e["name"] as String).toList();

class Danbooru implements BooruAPI {
  @override
  Dio client;

  @override
  void close() => client.close(force: true);

  @override
  int? currentPage() => null;

  Danbooru(this.client);

  @override
  Uri browserLink(int id) => Uri.https("danbooru.donmai.us", "/posts/$id");

  @override
  Future<List<String>> completeTag(String tag) async {
    var req = client.getUri(
      Uri.https("danbooru.donmai.us", "/tags.json", {
        "search[name_matches]": "$tag*",
        "order": "count",
        "limit": "10",
      }),
    );

    return Future(() async {
      try {
        var resp = await req;
        if (resp.statusCode != 200) {
          throw "status code not 200";
        }

        var tags = _fromDanbooruTags(resp.data);

        return tags;
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  @override
  Future<Post> singlePost(int id) {
    var req = client.getUri(Uri.https("danbooru.donmai.us", "/posts/$id.json"));

    return Future(() async {
      try {
        var resp = await req;

        if (resp.statusCode != 200) {
          throw resp.data["message"];
        }

        if (resp.data == null) {
          throw "no post";
        }

        return _fromJson(resp.data)[0];
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  @override
  Future<List<Post>> page(int i, String tags) => _commonPosts(tags, page: i);

  @override
  String name() => "Danbooru";

  @override
  String domain() => "danbooru.donmai.us";

  @override
  Future<List<Post>> fromPost(int postId, String tags) =>
      _commonPosts(tags, postid: postId);

  Future<List<Post>> _commonPosts(String tags, {int? postid, int? page}) {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    String excludedTagsString;

    var excludedTags =
        BooruTags().excluded.getStrings().map((e) => "-$e ").toList();
    if (excludedTags.isNotEmpty) {
      excludedTagsString =
          excludedTags.reduce((value, element) => value + element);
    } else {
      excludedTagsString = "";
    }

    Map<String, dynamic> query = {
      "limit": numberOfElementsPerRefresh().toString(),
      "format": "json",
      "post[tags]":
          "${isSafeModeEnabled() ? 'rating:g' : ''} $excludedTagsString $tags",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    var req =
        client.getUri(Uri.https("danbooru.donmai.us", "/posts.json", query));

    return Future(() async {
      try {
        var resp = await req;
        if (resp.statusCode != 200) {
          throw "status not ok";
        }

        return _fromJson(resp.data);
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  List<Post> _fromJson(List<dynamic> m) {
    List<Post> list = [];

    for (var e in m) {
      try {
        var post = Post(
            height: e["image_height"],
            id: e["id"],
            score: e["score"],
            sourceUrl: e["source"],
            rating: e["rating"] ?? "?",
            createdAt: DateTime.parse(e["created_at"]),
            md5: e["md5"],
            tags: e["tag_string"],
            width: e["image_width"],
            fileUrl: e["file_url"],
            previewUrl: e["preview_file_url"],
            sampleUrl: e["large_file_url"],
            ext: ".${e["file_ext"]}");

        list.add(post);
      } catch (e) {
        continue;
      }
    }

    return list;
  }
}
