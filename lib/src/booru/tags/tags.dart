// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../../pages/booru_scroll.dart';

BooruTags? _global;
bool _isInitalized = false;

class BooruTagging<T extends Tags> {
  final T Function(String booru) _getTags;
  final void Function(List<String> v, String domain) _addTags;

  T get() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;

    return _getTags(currentBooru.string);
  }

  void add(String t) {
    var booruTags = get();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);

    _addTags([t, ...tagsCopy], booruTags.domain);
  }

  void delete(String t) {
    var booruTags = get();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(t);

    _addTags(tags, booruTags.domain);
  }

  List<String> getStrings() => get().tags;

  const BooruTagging(T Function(String s) getTags,
      void Function(List<String> v, String domain) addTags)
      : _addTags = addTags,
        _getTags = getTags;
}

class _DissolveResult {
  final String ext;
  final Booru booru;
  final String hash;
  final int id;

  const _DissolveResult(
      {required this.booru,
      required this.ext,
      required this.hash,
      required this.id});
}

class BooruTags {
  final Isar tagsDb;

  BooruTagging<ExcludedTags> excluded = BooruTagging((s) {
    var booruTags = isar().excludedTags.getSync(fastHash(s));
    if (booruTags == null) {
      booruTags = ExcludedTags(s, []);
      isar().writeTxnSync(() => isar().excludedTags.putSync(booruTags!));
    }

    return booruTags;
  }, (v, domain) {
    isar().writeTxnSync(
        () => isar().excludedTags.putSync(ExcludedTags(domain, v)));
  });

  BooruTagging<LastTags> latest = BooruTagging((s) {
    var booruTags = isar().lastTags.getSync(fastHash(s));
    if (booruTags == null) {
      booruTags = LastTags(s, []);
      isar().writeTxnSync(() => isar().lastTags.putSync(booruTags!));
    }

    return booruTags;
  }, (v, domain) {
    isar().writeTxnSync(() => isar().lastTags.putSync(LastTags(domain, v)));
  });

  void onPressed(BuildContext context, String t) {
    t = t.trim();
    if (t.isEmpty) {
      return;
    }

    latest.add(t);
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

  _DissolveResult? _dissassembleFilename(String filename) {
    var split = filename.split("_");
    if (split.isEmpty || split.length != 2) {
      return null;
    }

    var booru = chooseBooruPrefix(split.first);
    if (booru == null) {
      return null;
    }

    var numbersAndHash = split.last.split("-");
    if (numbersAndHash.isEmpty || numbersAndHash.length != 2) {
      return null;
    }

    var id = int.tryParse(numbersAndHash.first.trimRight());
    if (id == null) {
      return null;
    }

    var hashAndExt = numbersAndHash.last.trimLeft().split(".");
    if (hashAndExt.isEmpty || hashAndExt.length != 2) {
      return null;
    }

    final numbersLetters = RegExp(r'^[a-z0-9]+$');
    if (!numbersLetters.hasMatch(hashAndExt.first)) {
      return null;
    }

    if (hashAndExt.last.length > 6) {
      return null;
    }

    if (hashAndExt.first.length != 32) {
      return null;
    }

    final onlyLetters = RegExp(r'^[a-zA-Z]+$');
    if (!onlyLetters.hasMatch(hashAndExt.last)) {
      return null;
    }

    return _DissolveResult(
        id: id, booru: booru, ext: hashAndExt.last, hash: hashAndExt.first);
  }

  void addTagsPost(String filename, List<String> tags) {
    if (_dissassembleFilename(filename) == null) {
      return;
    }

    tagsDb.writeTxnSync(
        () => tagsDb.localTags.putSync(LocalTags(filename, tags)));
  }

  void addAllPostTags(List<Post> p) {
    tagsDb.writeTxnSync(() => tagsDb.localTags.putAllSync(
        p.map((e) => LocalTags(e.filename(), e.tags.split(" "))).toList()));
  }

  List<String> getTagsPost(String filename) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags ?? [];
  }

  int savedTagsCount() => tagsDb.localTags.countSync();

  Future<List<String>> getOnlineAndSaveTags(String filename) async {
    var dissassembled = _dissassembleFilename(filename);
    if (dissassembled == null) {
      return [];
    }

    BooruAPI api;

    Dio client = Dio(BaseOptions(
      headers: {
        "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
      },
      responseType: ResponseType.json,
    ));

    switch (dissassembled.booru) {
      case Booru.danbooru:
        api = Danbooru(client);
        break;
      case Booru.gelbooru:
        api = Gelbooru(0, client);
        break;
    }
    try {
      var post = await api.singlePost(dissassembled.id);
      if (post.tags.isEmpty) {
        return [];
      }

      var postTags = post.tags.split(" ");

      tagsDb.writeTxnSync(
          () => tagsDb.localTags.put(LocalTags(filename, postTags)));

      api.close();

      return postTags;
    } catch (e, trace) {
      log("fetching post for tags",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
      api.close();
      return [];
    }
  }

  BooruTags._new(this.tagsDb);

  factory BooruTags() {
    return _global!;
  }
}

void initalizeBooruTags() {
  if (_isInitalized) {
    return;
  }

  _isInitalized = true;

  _global = BooruTags._new(openTagsDbIsar());
}
