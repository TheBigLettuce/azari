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
import '../pages/booru_scroll.dart';

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

Future<bool> popUntilSenitel(BuildContext context) {
  Navigator.of(context).popUntil(ModalRoute.withName("/senitel"));
  Navigator.pop(context);
  return Future.value(true);
}
