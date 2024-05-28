// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:logging/logging.dart";
import "package:path/path.dart";

/// Result of disassembling of the filename in the format.
/// All the files downloaded with the [Downloader] have a certain format
/// of the filenames, this class represents the format.
class DisassembleResult {
  const DisassembleResult({
    required this.booru,
    required this.ext,
    required this.hash,
    required this.id,
  });

  /// Extension of the file.
  final String ext;

  /// The booru enum from matching the prefix.
  final Booru booru;

  /// The MD5 hash.
  final String hash;

  /// The post number.
  final int id;

  static String makeFilename(Booru booru, String url, String md5, int id) {
    final ext = extension(url);

    return "${booru.prefix}_$id - $md5$ext";
  }

  /// Tries to disassemble the [filename] into the convenient class.
  /// Throws on error, with the reason string.
  static ErrorOr<DisassembleResult> fromFilename(
    String filename, {
    Booru? suppliedBooru,
  }) {
    final Booru booru;
    if (suppliedBooru == null) {
      final split = filename.split("_");
      if (split.isEmpty || split.length != 2) {
        return ErrorOr.error(DisassembleResultError.noPrefix.translatedString);
      }

      final newbooru = Booru.fromPrefix(split.first);
      if (newbooru == null) {
        return ErrorOr.error(
          DisassembleResultError.prefixNotRegistred.translatedString,
        );
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
      return ErrorOr.error(
        DisassembleResultError.numbersAndHash.translatedString,
      );
    }

    final id = int.tryParse(numbersAndHash.first);
    if (id == null) {
      return ErrorOr.error(
        DisassembleResultError.invalidPostNumber.translatedString,
      );
    }

    final hashAndExt = numbersAndHash.last.split(".");
    if (hashAndExt.isEmpty || hashAndExt.length != 2) {
      return ErrorOr.error(DisassembleResultError.noExtension.translatedString);
    }

    final numbersLetters = RegExp(r"^[a-z0-9]+$");
    if (!numbersLetters.hasMatch(hashAndExt.first)) {
      return ErrorOr.error(
        DisassembleResultError.hashIsInvalid.translatedString,
      );
    }

    if (hashAndExt.last.length > 6) {
      return ErrorOr.error(
        DisassembleResultError.extensionTooLong.translatedString,
      );
    }

    if (hashAndExt.first.length != 32) {
      return ErrorOr.error(DisassembleResultError.hashIsnt32.translatedString);
    }

    final lettersAndNumbers = RegExp(r"^[a-zA-Z0-9]+$");
    if (!lettersAndNumbers.hasMatch(hashAndExt.last)) {
      return ErrorOr.error(
        DisassembleResultError.extensionInvalid.translatedString,
      );
    }

    return ErrorOr.value(
      DisassembleResult(
        id: id,
        booru: booru,
        ext: hashAndExt.last,
        hash: hashAndExt.first,
      ),
    );
  }
}

class ErrorOr<T> {
  const ErrorOr.error(String Function(BuildContext context) error)
      : _error = error,
        _data = null;
  const ErrorOr.value(T result)
      : _data = result,
        _error = null;

  final T? _data;
  final String Function(BuildContext context)? _error;

  T asValue() => _data!;
  T? maybeValue() => _data;

  String? asError(BuildContext context) => _error!(context);

  bool get hasError => _error != null;
  bool get hasValue => _data != null;
}

/// Post tags saved locally.
/// This is used for offline tag viewing in the gallery.
class PostTags {
  PostTags(this._db, this._freq);

  factory PostTags.fromContext(BuildContext context) {
    final db = DatabaseConnectionNotifier.of(context);

    return PostTags(db.localTags, db.localTagDictionary);
  }

  final LocalTagDictionaryService _freq;
  final LocalTagsService _db;

  /// Connects to the booru and downloads the tags from it.
  /// Resolves to an empty list in case of any error.
  Future<List<String>> loadFromDissassemble(
    String filename,
    DisassembleResult dissassembled,
  ) async {
    final client = BooruAPI.defaultClientForBooru(dissassembled.booru);
    final api =
        BooruAPI.fromEnum(dissassembled.booru, client, EmptyPageSaver());

    try {
      final post = await api.singlePost(dissassembled.id);
      if (post.tags.isEmpty) {
        return [];
      }

      _db.add(filename, post.tags);

      return post.tags;
    } catch (e, trace) {
      log(
        "fetching post for tags",
        level: Level.SEVERE.value,
        error: e,
        stackTrace: trace,
      );
      return [];
    } finally {
      client.close();
    }
  }

  /// Adds tags to the db.
  /// If [noDisassemble] is true, the [filename] should be guranteed to be in the format.
  void addTagsPost(String filename, List<String> tags, bool noDisassemble) {
    if (!noDisassemble && DisassembleResult.fromFilename(filename).hasError) {
      return;
    }

    _freq.add(tags);
    _db.add(filename, tags);
  }

  /// Doesn't dissassemble.
  void addAllUnsafe(Iterable<(String, List<String>)> tags) {
    tags.map((e) => _freq.add(e.$2));
    _db.addAll(
      tags.map((e) => objFactory.makeLocalTagsData(e.$1, e.$2)).toList(),
    );
  }

  /// Returns true if tags for the [filename] includes [tag],
  /// or false if there are no tags for [filename].
  bool contains(String filename, String tag) {
    return _db.get(filename).contains(tag);
  }

  /// Returns true if tags for the [filename] includes all the [tags].
  /// [Tags] should be a string with tags separated by a space.
  /// Or false if there are no tags for the [filename].
  bool containsEvery(String filename, List<String> tags) {
    final localTags = _db.get(filename);
    if (localTags.isEmpty) {
      return false;
    }

    for (final t in tags) {
      if (!localTags.contains(t.trim())) {
        return false;
      }
    }

    return true;
  }

  /// Returns true if the tags for the [filename] have "original",
  /// or false if there are no tags for [filename].
  bool isOriginal(String filename) => _db.get(filename).contains("original");

  /// Disassembles the [filename] and load tags online from the booru.
  /// Resolves to an empty list in case of any error.
  Future<List<String>> getOnlineAndSaveTags(
    String filename,
  ) async {
    final dissassembled = DisassembleResult.fromFilename(filename);
    if (dissassembled.hasError) {
      return const [];
    }

    return loadFromDissassemble(filename, dissassembled.asValue());
  }
}

/// Restore local tags from the backup.
/// The backup is just an copy of the Isar DB.
/// In case of any error reverts back.
// Future<void> restore(void Function(String? error) onDone) async {
//   final tagsFile = joinAll([Dbs.g.appStorageDir, "localTags"]);
//   final tagsBakFile = joinAll([Dbs.g.appStorageDir, "localTags.bak"]);

//   try {
//     final outputFile =
//         await PlatformFunctions.pickFileAndCopy(Dbs.g.appStorageDir);
//     await Isar.openSync(
//       [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
//       directory: Dbs.g.appStorageDir,
//       inspector: false,
//       name: outputFile.split("/").last,
//     ).close();

//     await tagsDb.copyToFile(tagsBakFile);

//     await tagsDb.close();

//     io.File("$tagsFile.isar").deleteSync();
//     io.File(outputFile).renameSync("$tagsFile.isar");

//     tagsDb = DbsOpen.localTags();

//     io.File(tagsBakFile).deleteSync();

//     onDone(null);
//   } catch (e) {
//     try {
//       if (io.File(tagsBakFile).existsSync()) {
//         if (io.File("$tagsFile.isar").existsSync()) {
//           io.File("$tagsFile.isar").deleteSync();
//         }
//         io.File(tagsBakFile).renameSync("$tagsFile.isar");
//       }
//     } catch (_) {}
//     onDone(e.toString());
//   }
// }

// /// Make a copy of the tags DB.
// /// Calls [onDone] with null error when complete,
// /// or with non-null error when something went wrong.
// Future<void> copy(void Function(String? error) onDone) async {
//   try {
//     final plug = await chooseDownloadMoverPlug();

//     final output = joinAll([
//       Dbs.g.temporaryDbDir,
//       "${DateTime.now().microsecondsSinceEpoch}_savedtags.bin",
//     ]);

//     await tagsDb.copyToFile(output);

//     plug.move(
//       MoveOp(
//         source: output,
//         rootDir: SettingsService.currentData.path.path,
//         targetDir: "backup",
//       ),
//     );
//     onDone(null);
//   } catch (e) {
//     onDone(e.toString());
//   }
// }

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
