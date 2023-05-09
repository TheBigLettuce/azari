import 'dart:convert';

import 'package:gallery/src/schemas/post.dart';
import 'package:http/http.dart' as http;

import '../interface.dart';
import '../tags/tags.dart';

List<String> _fromDanbooruTags(List<dynamic> l) =>
    l.map((e) => e["name"] as String).toList();

class Danbooru implements BooruAPI {
  @override
  Future<List<String>> completeTag(String tag) async {
    var req = http.get(
      Uri.https("danbooru.donmai.us", " /tags.json", {
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

        var tags = _fromDanbooruTags(jsonDecode(resp.body));

        return tags;
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

    var excludedTags = BooruTags().getExcluded().map((e) => "-$e").toList();
    if (excludedTags.isNotEmpty) {
      excludedTagsString =
          excludedTags.reduce((value, element) => value + element);
    } else {
      excludedTagsString = "";
    }

    Map<String, dynamic> query = {
      "limit": numberOfElementsPerRefresh().toString(),
      "format": "json",
      "tags": "$excludedTagsString $tags",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    var req = http.get(Uri.https("danbooru.donmai.us", "/posts.json", query));

    return Future(() async {
      try {
        var resp = await req;
        if (resp.statusCode != 200) {
          throw "status not ok";
        }

        return _fromJson(jsonDecode(resp.body));
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
