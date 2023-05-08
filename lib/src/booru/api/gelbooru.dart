import 'dart:convert';

import 'package:gallery/src/booru/interface.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../schemas/post.dart';
import '../tags/tags.dart';

class Gelbooru implements BooruAPI {
  int _page = 0;

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

        return _fromJson(jsonDecode(r.body));
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
        _page++;
        return Future.value(value);
      });

  List<Post> _fromJson(Map<String, dynamic> m) {
    List<Post> list = [];

    for (var post in m["post"] as List) {
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

/* 


*/