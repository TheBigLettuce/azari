import 'dart:convert';
import 'dart:developer';

import 'package:gallery/src/booru/interface.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../schemas/post.dart';
import '../tags/tags.dart';

List<String> _fromGelbooruTags(List<dynamic> l) {
  return l.map((e) => HtmlUnescape().convert(e["name"] as String)).toList();
}

class Gelbooru implements BooruAPI {
  int _page = 0;

  Gelbooru(int page) : _page = page;

  @override
  int? currentPage() => _page;

  @override
  Future<List<String>> completeTag(String t) async {
    var req = http.get(
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

        var tags = _fromGelbooruTags(jsonDecode(resp.body)["tag"]);
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

    var excludedTags = BooruTags().getExcluded().map((e) => "-$e").toList();
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
      "tags": "$excludedTagsString $tags",
      "limit": numberOfElementsPerRefresh().toString()
    };

    var req = http.get(Uri.https("gelbooru.com", "/index.php", query));

    return Future(() async {
      try {
        var r = await req;

        if (r.statusCode != 200) {
          throw "status not 200";
        }

        var json = jsonDecode(r.body)["post"];
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

    for (var post in m) {
      list.add(Post(
          height: post["height"],
          id: post["id"],
          md5: post["md5"],
          tags: post["tags"],
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
