import 'package:gallery/src/schemas/settings.dart';

import '../cell/booru.dart';
import '../db/isar.dart';
import '../schemas/post.dart';

abstract class BooruAPI {
  String name();

  String domain();

  Future<List<Post>> page(int p, String tags);

  Future<List<Post>> fromPost(int postId, String tags);

  // Future<List<String>> completeTag(String tag);
}

List<BooruCell> postsToCells(
    List<Post> l, void Function(String tag) onTagPressed) {
  List<BooruCell> list = [];

  for (var element in l) {
    list.add(element.booruCell(onTagPressed));
  }

  return list;
}

int numberOfElementsPerRefresh() {
  var settings = isar().settings.getSync(0)!;
  if (settings.listViewBooru) {
    return 20;
  }

  return 10 * settings.picturesPerRow;
}
