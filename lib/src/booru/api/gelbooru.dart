// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:path/path.dart' as path;

import '../../schemas/post.dart';
import '../tags/tags.dart';
import 'package:intl/intl.dart';

List<String> _fromGelbooruTags(List<dynamic> l) {
  return l.map((e) => HtmlUnescape().convert(e["name"] as String)).toList();
}

class Gelbooru implements BooruAPI {
  @override
  Dio client;

  @override
  void close() => client.close(force: true);

  int _page = 0;

  Gelbooru(int page, this.client) : _page = page;

  @override
  Uri browserLink(int id) => Uri.https("gelbooru.com", "/index.php", {
        "page": "post",
        "s": "view",
        "id": id.toString(),
      });

  @override
  int? currentPage() => _page;

  @override
  Future<List<String>> completeTag(String t) async {
    var req = client.getUri(
      Uri.https("gelbooru.com", "/index.php", {
        "page": "dapi",
        "s": "tag",
        "q": "index",
        "limit": "10",
        "json": "1",
        "name_pattern": "$t%",
        "orderby": "count"
      }),
    );

    return Future(() async {
      try {
        var resp = await req;
        if (resp.statusCode != 200) {
          throw "status code not 200";
        }

        var tags = _fromGelbooruTags(resp.data["tag"]);
        return tags;
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  @override
  Future<List<Post>> page(int p, String tags) {
    _page = p + 1;
    return _commonPosts(tags, p);
  }

  Future<List<Post>> _commonPosts(String tags, int p) async {
    String excludedTagsString;

    var excludedTags =
        BooruTags().excluded.getStrings().map((e) => "-$e ").toList();
    if (excludedTags.isNotEmpty) {
      excludedTagsString =
          excludedTags.reduce((value, element) => value + element);
    } else {
      excludedTagsString = "";
    }

    var query = {
      "page": "dapi",
      "s": "post",
      "q": "index",
      "pid": p.toString(),
      "json": "1",
      "tags":
          "${isSafeModeEnabled() ? 'rating:general' : ''} $excludedTagsString $tags",
      "limit": numberOfElementsPerRefresh().toString()
    };

    var req = client.getUri(Uri.https("gelbooru.com", "/index.php", query));

    return Future(() async {
      try {
        var r = await req;

        if (r.statusCode != 200) {
          throw "status not 200";
        }

        var json = r.data["post"];
        if (json == null) {
          return Future.value([]);
        }

        return _fromJson(json);
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  @override
  Future<Post> singlePost(int id) {
    var req = client.getUri(Uri.https("gelbooru.com", "/index.php", {
      "page": "dapi",
      "s": "post",
      "q": "index",
      "id": id.toString(),
      "json": "1"
    }));

    return Future(() async {
      try {
        var resp = await req;

        if (resp.statusCode != 200) {
          throw "status is not 200";
        }

        var json = resp.data["post"];
        if (json == null) {
          throw "The post has been not found.";
        }

        return _fromJson([json[0]])[0];
      } catch (e) {
        return Future.error(e);
      }
    });
  }

  @override
  String name() => "Gelbooru";

  @override
  String domain() => "gelbooru.com";

  @override
  Future<List<Post>> fromPost(int _, String tags) =>
      _commonPosts(tags, _page).then((value) {
        if (value.isNotEmpty) {
          _page++;
        }
        return Future.value(value);
      });

  List<Post> _fromJson(List<dynamic> m) {
    List<Post> list = [];

    var dateFormatter = DateFormat("EEE MMM dd HH:mm:ss -0500 yyyy");

    for (var post in m) {
      list.add(Post(
          height: post["height"],
          id: post["id"],
          md5: post["md5"],
          tags: post["tags"],
          score: post["score"],
          sourceUrl: post["source"],
          createdAt: dateFormatter.parse(post["created_at"]),
          rating: post["rating"],
          width: post["width"],
          fileUrl: post["file_url"],
          previewUrl: post["preview_url"],
          ext: path.extension(post["image"]),
          sampleUrl: post["sample_url"] == ""
              ? post["file_url"]
              : post["sample_url"]));
    }

    return list;
  }
}
