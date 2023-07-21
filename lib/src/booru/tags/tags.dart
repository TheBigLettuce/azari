// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/schemas/directory_tags.dart';
import 'package:gallery/src/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

late final PostTags _global;
bool _isInitalized = false;

abstract class BooruTagging {
  List<Tag> get();
  void add(Tag tag);
  void delete(Tag tag);
  void clear();
}

class DissolveResult {
  final String ext;
  final Booru booru;
  final String hash;
  final int id;

  const DissolveResult(
      {required this.booru,
      required this.ext,
      required this.hash,
      required this.id});
}

class PostTags {
  Isar tagsDb;

  Future<List<String>> loadFromDissassemble(
      String filename, DissolveResult dissassembled) async {
    BooruAPI api;

    Dio client = Dio(BaseOptions(
      responseType: ResponseType.json,
    ));

    switch (dissassembled.booru) {
      case Booru.danbooru:
        api = Danbooru(
            client, UnsaveableCookieJar(CookieJarTab().get(Booru.danbooru)));
        break;
      case Booru.gelbooru:
        api = Gelbooru(
            0, client, UnsaveableCookieJar(CookieJarTab().get(Booru.gelbooru)));
        break;
    }
    try {
      final post = await api.singlePost(dissassembled.id);
      if (post.tags.isEmpty) {
        return [];
      }

      final postTags = post.tags.split(" ");

      tagsDb.writeTxnSync(
          () => tagsDb.localTags.putSync(LocalTags(filename, postTags)));

      api.close();

      return postTags;
    } catch (e, trace) {
      log("fetching post for tags",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
      api.close();
      return [];
    }
  }

  DissolveResult dissassembleFilename(String filename, {Booru? suppliedBooru}) {
    final Booru booru;
    if (suppliedBooru == null) {
      final split = filename.split("_");
      if (split.isEmpty || split.length != 2) {
        throw "no prefix";
      }

      final newbooru = chooseBooruPrefix(split.first);
      if (newbooru == null) {
        throw "prefix not registred";
      }

      booru = newbooru;
      filename = split.last;
    } else {
      booru = suppliedBooru;
    }

    final prefix = filename.split("_");
    if (prefix.length == 2) {
      filename = prefix.last;
    }

    final numbersAndHash = filename.split("-");
    if (numbersAndHash.isEmpty || numbersAndHash.length != 2) {
      throw "filename doesn't include numbers and hash";
    }

    final id = int.tryParse(numbersAndHash.first.trimRight());
    if (id == null) {
      throw "invalid post number";
    }

    final hashAndExt = numbersAndHash.last.trimLeft().split(".");
    if (hashAndExt.isEmpty || hashAndExt.length != 2) {
      throw "filename doesn't include extension";
    }

    final numbersLetters = RegExp(r'^[a-z0-9]+$');
    if (!numbersLetters.hasMatch(hashAndExt.first)) {
      throw "hash is invalid";
    }

    if (hashAndExt.last.length > 6) {
      throw "extension is too long";
    }

    if (hashAndExt.first.length != 32) {
      throw "hash is not 32 characters";
    }

    final onlyLetters = RegExp(r'^[a-zA-Z]+$');
    if (!onlyLetters.hasMatch(hashAndExt.last)) {
      throw "extension is invalid";
    }

    return DissolveResult(
        id: id, booru: booru, ext: hashAndExt.last, hash: hashAndExt.first);
  }

  void addTagsPost(String filename, List<String> tags, bool noDisassemble) {
    if (!noDisassemble) {
      try {
        dissassembleFilename(filename);
      } catch (_) {
        return;
      }
    }

    tagsDb.writeTxnSync(() {
      _putTagsAndIncreaseFreq(tags);
      tagsDb.localTags.putSync(LocalTags(filename, tags));
    });
  }

  void rebuildTagDictionary() {
    tagsDb.writeTxnSync(() => tagsDb.localTagDictionarys.clearSync());

    var offset = 0;
    for (;;) {
      final tags =
          tagsDb.localTags.where().offset(offset).limit(40).findAllSync();
      offset += tags.length;

      for (var e in tags) {
        tagsDb.writeTxnSync(() => _putTagsAndIncreaseFreq(e.tags));
      }

      if (tags.length != 40) {
        return;
      }
    }
  }

  void _putTagsAndIncreaseFreq(List<String> tags) {
    tagsDb.localTagDictionarys.putAllSync(tags
        .map((e) => LocalTagDictionary(
            HtmlUnescape().convert(e),
            (tagsDb.localTagDictionarys.getSync(fastHash(e))?.frequency ?? 0) +
                1))
        .toList());
  }

  void addAllPostTags(List<Post> p) {
    tagsDb.writeTxnSync(() {
      List<LocalTags> list = [];
      for (var e in p) {
        final elem = LocalTags(e.filename(), e.tags.split(" "));
        list.add(elem);
        _putTagsAndIncreaseFreq(elem.tags);
      }

      tagsDb.localTags.putAllSync(list);
    });
  }

  List<String> getTagsPost(String filename) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags ?? [];
  }

  bool containsTag(String filename, String tag) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags.contains(tag) ??
        false;
  }

  bool containsTagMultiple(String filename, String tags) {
    final localTags = tagsDb.localTags.getSync(fastHash(filename))?.tags;
    if (localTags == null || localTags.isEmpty) {
      return false;
    }
    for (final t in tags.split(" ")) {
      if (!localTags.contains(t.trim())) {
        return false;
      }
    }

    return true;
  }

  bool isOriginal(String filename) {
    return tagsDb.localTags
            .getSync(fastHash(filename))
            ?.tags
            .contains("original") ??
        false;
  }

  int savedTagsCount() => tagsDb.localTags.countSync();

  Future<List<String>> completeLocalTag(String string) async {
    final result = tagsDb.localTagDictionarys
        .filter()
        .tagContains(string)
        .sortByFrequencyDesc()
        .limit(10)
        .findAllSync();

    return result.map((e) => e.tag).toList();
  }

  Future<List<String>> getOnlineAndSaveTags(
    String filename,
  ) async {
    try {
      final dissassembled = dissassembleFilename(filename);

      return loadFromDissassemble(filename, dissassembled);
    } catch (_) {
      return [];
    }
  }

  void deletePostTags(String filename) {
    tagsDb.writeTxnSync(() => tagsDb.localTags.deleteSync(fastHash(filename)));
  }

  PostTags._new(this.tagsDb);

  void restore(void Function(String? error) onDone) async {
    // try {
    //   const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
    //   String resp = await channel.invokeMethod("pickFile");
    //   onDone(null);
    // } catch (e) {
    //   onDone(e.toString());
    // }
  }

  String? directoryTag(String bucketId) {
    return tagsDb.directoryTags.getSync(fastHash(bucketId))?.tag;
  }

  void setDirectoryTag(String bucketId, String tag) {
    tagsDb.writeTxnSync(
        () => tagsDb.directoryTags.putSync(DirectoryTag(bucketId, tag)));
  }

  void removeDirectoryTag(String buckedId) {
    tagsDb.writeTxnSync(
        () => tagsDb.directoryTags.deleteSync(fastHash(buckedId)));
  }

  void copy(void Function(String? error) onDone) async {
    try {
      final plug = await chooseDownloadMoverPlug();

      final dir = temporaryDbDir();

      final output = joinAll([
        dir,
        "${DateTime.now().microsecondsSinceEpoch.toString()}_savedtags.bin"
      ]);

      await tagsDb.copyToFile(output);

      plug.move(MoveOp(
          source: output,
          rootDir: settingsIsar().settings.getSync(0)!.path,
          targetDir: "backup"));
      onDone(null);
    } catch (e) {
      onDone(e.toString());
    }
  }

  factory PostTags() {
    return _global;
  }
}

void initPostTags() {
  if (_isInitalized) {
    return;
  }

  _global = PostTags._new(openTagsDbIsar());
}
