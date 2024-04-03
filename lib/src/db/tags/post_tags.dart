// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/db/schemas/gallery/directory_tags.dart';
import 'package:gallery/src/db/schemas/tags/local_tag_dictionary.dart';
import 'package:gallery/src/db/schemas/tags/local_tags.dart';
import 'package:gallery/src/db/schemas/booru/post.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

late final PostTags _global;
bool _isInitalized = false;

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

  const DisassembleResult({
    required this.booru,
    required this.ext,
    required this.hash,
    required this.id,
  });
}

/// Post tags saved locally.
/// This is used for offline tag viewing in the gallery.
class PostTags {
  Isar tagsDb;

  /// Connects to the booru and downloads the tags from it.
  /// Resolves to an empty list in case of any error.
  Future<List<String>> loadFromDissassemble(
      String filename, DisassembleResult dissassembled) async {
    final client = BooruAPI.defaultClientForBooru(dissassembled.booru);
    final api =
        BooruAPI.fromEnum(dissassembled.booru, client, EmptyPageSaver());

    try {
      final post = await api.singlePost(dissassembled.id);
      if (post.tags.isEmpty) {
        return [];
      }

      tagsDb.writeTxnSync(
          () => tagsDb.localTags.putSync(LocalTags(filename, post.tags)));

      return post.tags;
    } catch (e, trace) {
      log("fetching post for tags",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
      return [];
    } finally {
      client.close();
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
        throw DisassembleResultError.noPrefix;
      }

      final newbooru = Booru.fromPrefix(split.first);
      if (newbooru == null) {
        throw DisassembleResultError.prefixNotRegistred;
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
      throw DisassembleResultError.numbersAndHash;
    }

    final id = int.tryParse(numbersAndHash.first);
    if (id == null) {
      throw DisassembleResultError.invalidPostNumber;
    }

    final hashAndExt = numbersAndHash.last.split(".");
    if (hashAndExt.isEmpty || hashAndExt.length != 2) {
      throw DisassembleResultError.noExtension;
    }

    final numbersLetters = RegExp(r'^[a-z0-9]+$');
    if (!numbersLetters.hasMatch(hashAndExt.first)) {
      throw DisassembleResultError.hashIsInvalid;
    }

    if (hashAndExt.last.length > 6) {
      throw DisassembleResultError.extensionTooLong;
    }

    if (hashAndExt.first.length != 32) {
      throw DisassembleResultError.hashIsnt32;
    }

    final lettersAndNumbers = RegExp(r'^[a-zA-Z0-9]+$');
    if (!lettersAndNumbers.hasMatch(hashAndExt.last)) {
      throw DisassembleResultError.extensionInvalid;
    }

    return DisassembleResult(
      id: id,
      booru: booru,
      ext: hashAndExt.last,
      hash: hashAndExt.first,
    );
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

  /// Doesn't dissassemble.
  void addTagsPostAll(Iterable<(String, List<String>)> tags) {
    tagsDb.writeTxnSync(() {
      tagsDb.localTags.putAllSync(tags.map((e) {
        _putTagsAndIncreaseFreq(e.$2);

        return LocalTags(e.$1, e.$2);
      }).toList());
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
            e,
            (tagsDb.localTagDictionarys.getSync(fastHash(e))?.frequency ?? 0) +
                1))
        .toList());
  }

  /// Saves all the tags from the posts.
  void addAllPostTags(List<Post> p) {
    tagsDb.writeTxnSync(() {
      tagsDb.localTags.putAllSync(p.map((e) {
        final ret = LocalTags(e.filename(), e.tags);
        _putTagsAndIncreaseFreq(ret.tags);
        return ret;
      }).toList());
    });
  }

  /// Returns tags for the [filename], or empty list if there are none.
  List<String> getTagsPost(String filename) {
    return tagsDb.localTags.getSync(fastHash(filename))?.tags ?? [];
  }

  void removeTag(List<String> filenames, String tag) {
    final List<LocalTags> newTags = [];

    for (final e
        in tagsDb.localTags.getAllByFilenameSync(filenames).cast<LocalTags>()) {
      final idx = e.tags.indexWhere((element) => element == tag);
      if (idx.isNegative) {
        continue;
      }

      newTags.add(LocalTags(e.filename, e.tags.toList()..removeAt(idx)));
    }

    return tagsDb
        .writeTxnSync(() => tagsDb.localTags.putAllByFilenameSync(newTags));
  }

  List<String> _addAndSort(List<String> tags, String addTag) {
    final l = tags.toList() + [addTag];
    l.sort();

    return l;
  }

  void addTag(List<String> filenames, String tag) {
    if (filenames.isEmpty || tag.isEmpty) {
      return;
    }

    final newTags = tagsDb.localTags
        .getAllByFilenameSync(filenames)
        .where((element) => element != null && !element.tags.contains(tag))
        .cast<LocalTags>()
        .map((e) => LocalTags(e.filename, _addAndSort(e.tags, tag)))
        .toList();

    if (newTags.isEmpty) {
      return;
    }

    return tagsDb
        .writeTxnSync(() => tagsDb.localTags.putAllByFilenameSync(newTags));
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

  Future<List<BooruTag>> completeLocalTag(String string) async {
    final result = tagsDb.localTagDictionarys
        .filter()
        .tagContains(string)
        .sortByFrequencyDesc()
        .limit(10)
        .findAllSync();

    return result.map((e) => BooruTag(e.tag, e.frequency)).toList();
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

  /// Restore local tags from the backup.
  /// The backup is just an copy of the Isar DB.
  /// In case of any error reverts back.
  void restore(void Function(String? error) onDone) async {
    final tagsFile = joinAll([Dbs.g.appStorageDir, "localTags"]);
    final tagsBakFile = joinAll([Dbs.g.appStorageDir, "localTags.bak"]);

    try {
      final outputFile =
          await PlatformFunctions.pickFileAndCopy(Dbs.g.appStorageDir);
      await Isar.openSync(
              [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
              directory: Dbs.g.appStorageDir,
              inspector: false,
              name: outputFile.split("/").last)
          .close();

      await tagsDb.copyToFile(tagsBakFile);

      await tagsDb.close();

      io.File("$tagsFile.isar").deleteSync();
      io.File(outputFile).renameSync("$tagsFile.isar");

      tagsDb = DbsOpen.localTags();

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

  void setDirectoriesTag(Iterable<String> bucketIds, String tag) {
    tagsDb.writeTxnSync(() => tagsDb.directoryTags
        .putAllSync(bucketIds.map((e) => DirectoryTag(e, tag)).toList()));
  }

  void removeDirectoriesTag(Iterable<String> buckedIds) {
    tagsDb.writeTxnSync(() => tagsDb.directoryTags
        .deleteAllSync(buckedIds.map((e) => fastHash(e)).toList()));
  }

  /// Make a copy of the tags DB.
  /// Calls [onDone] with null error when complete,
  /// or with non-null error when something went wrong.
  void copy(void Function(String? error) onDone) async {
    try {
      final plug = await chooseDownloadMoverPlug();

      final output = joinAll([
        Dbs.g.temporaryDbDir,
        "${DateTime.now().microsecondsSinceEpoch.toString()}_savedtags.bin"
      ]);

      await tagsDb.copyToFile(output);

      plug.move(MoveOp(
          source: output,
          rootDir: Settings.fromDb().path.path,
          targetDir: "backup"));
      onDone(null);
    } catch (e) {
      onDone(e.toString());
    }
  }

  StreamSubscription<List<LocalTags>> watch(
      String filename, void Function(List<LocalTags>) f) {
    return tagsDb.localTags.where().filenameEqualTo(filename).watch().listen(f);
  }

  PostTags._new(this.tagsDb);

  static PostTags get g {
    if (_isInitalized) {
      return _global;
    }

    _isInitalized = true;
    _global = PostTags._new(DbsOpen.localTags());

    return _global;
  }
}

enum DisassembleResultError {
  extensionInvalid,
  noPrefix,
  numbersAndHash,
  prefixNotRegistred,
  invalidPostNumber,
  noExtension,
  hashIsInvalid,
  extensionTooLong,
  hashIsnt32;

  String translatedString(BuildContext context) => switch (this) {
        DisassembleResultError.extensionInvalid =>
          AppLocalizations.of(context)!.disassembleExtensionInvalid,
        DisassembleResultError.noPrefix =>
          AppLocalizations.of(context)!.disassembleNoPrefix,
        DisassembleResultError.numbersAndHash =>
          AppLocalizations.of(context)!.disassembleNumbersAndHash,
        DisassembleResultError.prefixNotRegistred =>
          AppLocalizations.of(context)!.disassemblePrefixNotRegistred,
        DisassembleResultError.invalidPostNumber =>
          AppLocalizations.of(context)!.disassembleInvalidPostNumber,
        DisassembleResultError.noExtension =>
          AppLocalizations.of(context)!.disassembleNoExtension,
        DisassembleResultError.hashIsInvalid =>
          AppLocalizations.of(context)!.disassembleHashIsInvalid,
        DisassembleResultError.extensionTooLong =>
          AppLocalizations.of(context)!.disassembleExtensionTooLong,
        DisassembleResultError.hashIsnt32 =>
          AppLocalizations.of(context)!.disassembleHashIsnt32,
      };
}
