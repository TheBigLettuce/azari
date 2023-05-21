// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:logging/logging.dart';

import '../cell/booru.dart';
import '../db/isar.dart';
import '../schemas/post.dart';
import 'infinite_scroll.dart';

abstract class BooruAPI {
  String name();

  int? currentPage();

  String domain();

  Future<Post> singlePost(int id);

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

Future<List<String>> autoCompleteTag(
    String tagString, Future<List<String>> Function(String) complF) {
  if (tagString.isEmpty) {
    return Future.value([]);
  } else if (tagString.characters.last == " ") {
    return Future.value([]);
  }

  var tags = tagString.trim().split(" ");

  return complF(tags.isEmpty ? "" : tags.last);
}

Widget autocompleteWidget(TextEditingController controller,
    void Function(String) onSubmit, FocusNode focus,
    {ScrollController? scrollHack,
    bool noSticky = false,
    bool submitOnPress = false,
    bool roundBorders = false,
    bool showSearch = false}) {
  return RawAutocomplete<String>(
    textEditingController: controller,
    focusNode: focus,
    optionsViewBuilder: (context, onSelected, options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(25),
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
            child: ListView(
              children: ListTile.divideTiles(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  context: context,
                  tiles: options.map((elem) => ListTile(
                        onTap: () {
                          if (submitOnPress) {
                            focus.unfocus();
                            controller.text = "";
                            onSubmit(elem);
                            return;
                          }

                          if (noSticky) {
                            onSelected(elem);
                            return;
                          }

                          List<String> tags =
                              List.from(controller.text.split(" "));

                          if (tags.isNotEmpty) {
                            tags.removeLast();
                            tags.remove(elem);
                          }

                          tags.add(elem);

                          var tagsString = tags
                              .reduce((value, element) => "$value $element");

                          onSelected(tagsString);
                        },
                        title: Text(elem),
                      ))).toList(),
            ),
          ),
        ),
      );
    },
    fieldViewBuilder:
        (context, textEditingController, focusNode, onFieldSubmitted) {
      return TextField(
        scrollController: scrollHack,
        cursorOpacityAnimates: true,
        decoration: InputDecoration(
            prefixIcon: showSearch ? const Icon(Icons.search_rounded) : null,
            suffixIcon: IconButton(
              onPressed: () {
                textEditingController.clear();
                focus.unfocus();
              },
              icon: const Icon(Icons.close),
            ),
            hintText: "Search",
            border: roundBorders
                ? const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)))
                : InputBorder.none,
            isDense: false),
        controller: textEditingController,
        focusNode: focusNode,
        onSubmitted: (value) {
          onSubmit(value);
        },
      );
    },
    optionsBuilder: (textEditingValue) async {
      List<String> options = [];
      try {
        options = await autoCompleteTag(
            textEditingValue.text, getBooru().completeTag);
      } catch (e, trace) {
        log("autocomplete in search, excluded tags",
            level: Level.WARNING.value, error: e, stackTrace: trace);
      }

      return options;
    },
  );
}

int numberOfElementsPerRefresh() {
  var settings = isar().settings.getSync(0)!;
  if (settings.listViewBooru) {
    return 20;
  }

  return 10 * settings.picturesPerRow;
}

void tagOnPressed(BuildContext context, String t) {
  t = t.trim();
  if (t.isEmpty) {
    return;
  }

  BooruTags().addLatest(t);
  newSecondaryGrid().then((value) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return BooruScroll.secondary(
        isar: value,
        tags: t,
      );
    }));
  }).onError((error, stackTrace) {
    log("searching for tag $t",
        level: Level.WARNING.value, error: error, stackTrace: stackTrace);
  });
}
