import 'package:flutter/material.dart';
import 'package:gallery/src/schemas/settings.dart';

import '../cell/booru.dart';
import '../db/isar.dart';
import '../schemas/post.dart';

abstract class BooruAPI {
  String name();

  int? currentPage();

  String domain();

  Future<List<Post>> page(int p, String tags);

  Future<List<Post>> fromPost(int postId, String tags);

  Future<List<String>> completeTag(String tag);
}

List<BooruCell> postsToCells(
    List<Post> l, void Function(String tag) onTagPressed) {
  List<BooruCell> list = [];

  for (var element in l) {
    list.add(element.booruCell(onTagPressed));
  }

  return list;
}

MenuStyle tagCompleteMenuStyle() => MenuStyle(
    shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))));

Future<List<Widget>> autoCompleteTag(
    String tagString,
    MenuController menuController,
    TextEditingController textController,
    Future<List<String>> Function(String) complF) {
  if (tagString.isEmpty) {
    return Future.value([]);
  } else if (tagString.characters.last == " ") {
    menuController.close();
    return Future.value([]);
  }

  var tags = tagString.trim().split(" ");

  return complF(tags.isEmpty ? "" : tags.last).then((value) => value
      .map((e) => ListTile(
            title: Text(e),
            onTap: () {
              menuController.close();
              List<String> tags = List.from(textController.text.split(" "));

              if (tags.isNotEmpty) {
                tags.removeLast();
                tags.remove(e);
              }

              tags.add(e);

              var tagsString =
                  tags.reduce((value, element) => "$value $element");

              textController.value = TextEditingValue(
                  text: tagsString,
                  selection: TextSelection(
                      baseOffset: tagsString.length,
                      extentOffset: tagsString.length));
            },
          ))
      .toList());
}

int numberOfElementsPerRefresh() {
  var settings = isar().settings.getSync(0)!;
  if (settings.listViewBooru) {
    return 20;
  }

  return 10 * settings.picturesPerRow;
}
