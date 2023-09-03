// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
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
import 'package:gallery/src/booru/downloader/downloader.dart';

late final PostTags _global;
bool _isInitalized = false;

/// Tag search history.
/// Used for both for the recent tags and the excluded.
abstract class BooruTagging {
  /// Get the current tags.
  /// Last added first.
  List<Tag> get();

  /// Add the [tag] to the DB.
  /// Updates the added time if already exist.
  void add(Tag tag);

  /// Delete the [tag] from the DB.
  void delete(Tag tag);

  /// Delete all the tags from the DB.
  void clear();

  const BooruTagging();
}

/// Result of disassembling of the filename in the format.
/// All the files downloaded with the [Downloader] have a certain format
/// of the filenames, this class represents the format.
class DisassembleResult {
  /// Extension of the file.
  final String ext;

  /// The booru enum from matching the prefix.
  final Booru booru;

  /// The MD5 hash.
  final String hash;

  /// The post number.
  final int id;

  const DisassembleResult(
      {required this.booru,
      required this.ext,
      required this.hash,
      required this.id});
}

/// Post tags saved locally.
/// This is used for offline tag viewing in the gallery.
class PostTags {
  Isar tagsDb;

  /// Connects to the booru and downloads the tags from it.
  /// Resolves to an empty list in case of any error.
  Future<List<String>> loadFromDissassemble(
      String filename, DisassembleResult dissassembled) async {
    final Dio client = Dio(BaseOptions(
      responseType: ResponseType.json,
    ));

    final api = switch (dissassembled.booru) {
      Booru.danbooru => Danbooru(
          client, UnsaveableCookieJar(CookieJarTab().get(Booru.danbooru))),
      Booru.gelbooru => Gelbooru(
          0, client, UnsaveableCookieJar(CookieJarTab().get(Booru.gelbooru))),
    };

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

  /// Tries to disassemble the [filename] into the convenient class.
  /// Throws on error, with the reason string.
  DisassembleResult dissassembleFilename(String filename,
      {Booru? suppliedBooru}) {
    final Booru booru;
    if (suppliedBooru == null) {
      final split = filename.split("_");
      if (split.isEmpty || split.length != 2) {
        throw "No prefix"; // TODO: change
      }

      final newbooru = Booru.fromPrefix(split.first);
      if (newbooru == null) {
        throw "Prefix not registred"; // TODO: change
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

    final numbersAndHash = filename.split(" - ");
    if (numbersAndHash.isEmpty || numbersAndHash.length != 2) {
      throw "Filename should include numbers and hash separated by a -,"
          " with one space to the left of the -, and one to the right of -"; // TODO: change
    }

    final id = int.tryParse(numbersAndHash.first);
    if (id == null) {
      throw "Invalid post number"; // TODO: change
    }

    final hashAndExt = numbersAndHash.last.split(".");
    if (hashAndExt.isEmpty || hashAndExt.length != 2) {
      throw "Filename doesn't include extension"; // TODO: change
    }

    final numbersLetters = RegExp(r'^[a-z0-9]+$');
    if (!numbersLetters.hasMatch(hashAndExt.first)) {
      throw "Hash is invalid"; // TODO: change
    }

    if (hashAndExt.last.length > 6) {
      throw "Extension is too long"; // TODO: change
    }

    if (hashAndExt.first.length != 32) {
      throw "Hash is not 32 characters"; // TODO: change
    }

    final lettersAndNumbers = RegExp(r'^[a-zA-Z0-9]+$');
    if (!lettersAndNumbers.hasMatch(hashAndExt.last)) {
      throw "Extension is invalid"; // TODO: change
    }

    return DisassembleResult(
        id: id, booru: booru, ext: hashAndExt.last, hash: hashAndExt.first);
  }

  /// Adds tags to the db.
  /// If [noDisassemble] is true, the [filename] should be guranteed to be in the format.
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

  /// Rebuilds the tag suggestions dictionary.
  /// [rebuildTagDictionary] shouldn't be frequently run, as it might take minutes to complete.
  void rebuildTagDictionary() {
    tagsDb.writeTxnSync(() => tagsDb.localTagDictionarys.clearSync());

    var offset = 0;
    for (;;) {
      final tags =
          tagsDb.localTags.where().offset(offset).limit(40).findAllSync();
      offset += tags.length;

      for (final e in tags) {
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

  /// Saves all the tags from the posts.
  void addAllPostTags(List<Post> p) {
    tagsDb.writeTxnSync(() {
      tagsDb.localTags.putAllSync(p.map((e) {
        final ret = LocalTags(e.filename(), e.tags.split(" "));
        _putTagsAndIncreaseFreq(ret.tags);
        return ret;
      }).toList());
    });
  }

  /// Returns tags for the [filename], or empty list if there are none.
  List<String> getTagsPost(String filename) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags ?? [];
  }

  /// Returns true if tags for the [filename] includes [tag],
  /// or false if there are no tags for [filename].
  bool containsTag(String filename, String tag) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags.contains(tag) ??
        false;
  }

  /// Returns true if tags for the [filename] includes all the [tags].
  /// [Tags] should be a string with tags separated by a space.
  /// Or false if there are no tags for the [filename].
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

  /// Returns true if the tags for the [filename] have "original",
  /// or false if there are no tags for [filename].
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

  /// Disassembles the [filename] and load tags online from the booru.
  /// Resolves to an empty list in case of any error.
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

  /// Restore local tags from the backup.
  /// The backup is just an copy of the Isar DB.
  /// In case of any error reverts back.
  void restore(void Function(String? error) onDone) async {
    final tagsFile = joinAll([appStorageDir(), "localTags"]);
    final tagsBakFile = joinAll([appStorageDir(), "localTags.bak"]);

    try {
      final outputFile =
          await PlatformFunctions.pickFileAndCopy(appStorageDir());
      await Isar.openSync(
              [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
              directory: appStorageDir(),
              inspector: false,
              name: outputFile.split("/").last)
          .close();

      await tagsDb.copyToFile(tagsBakFile);

      await tagsDb.close();

      io.File("$tagsFile.isar").deleteSync();
      io.File(outputFile).renameSync("$tagsFile.isar");

      tagsDb = IsarDbsOpen.localTags();

      io.File(tagsBakFile).deleteSync();

      onDone(null);
    } catch (e) {
      try {
        if (io.File(tagsBakFile).existsSync()) {
          if (io.File("$tagsFile.isar").existsSync()) {
            io.File("$tagsFile.isar").deleteSync();
          }
          io.File(tagsBakFile).renameSync("$tagsFile.isar");
        }
      } catch (_) {}
      onDone(e.toString());
    }
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

  /// Make a copy of the tags DB.
  /// Calls [onDone] with null error when complete,
  /// or with non-null error when something went wrong.
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
          rootDir: Settings.fromDb().path,
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

  _global = PostTags._new(IsarDbsOpen.localTags());
}
