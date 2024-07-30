// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:logging/logging.dart";
import "package:path/path.dart";

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
    LocalTagDictionaryService localTagDictionary,
  ) async {
    final client = BooruAPI.defaultClientForBooru(dissassembled.booru);
    final api =
        BooruAPI.fromEnum(dissassembled.booru, client, PageSaver.noPersist());

    try {
      final post = await api.singlePost(dissassembled.id);
      if (post.tags.isEmpty) {
        return [];
      }

      _db.add(filename, post.tags);
      localTagDictionary.add(post.tags);

      return post.tags;
    } catch (e, trace) {
      Logger.root.severe("loadFromDissassemble", e, trace);
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
      tags.map((e) => LocalTagsData(filename: e.$1, tags: e.$2)).toList(),
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
    LocalTagDictionaryService localTagDictionary,
  ) async {
    final dissassembled = DisassembleResult.fromFilename(filename);
    if (dissassembled.hasError) {
      return const [];
    }

    return loadFromDissassemble(
      filename,
      dissassembled.asValue(),
      localTagDictionary,
    );
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

  String translatedString(AppLocalizations l10n) => switch (this) {
        DisassembleResultError.extensionInvalid =>
          l10n.disassembleExtensionInvalid,
        DisassembleResultError.noPrefix => l10n.disassembleNoPrefix,
        DisassembleResultError.numbersAndHash => l10n.disassembleNumbersAndHash,
        DisassembleResultError.prefixNotRegistred =>
          l10n.disassemblePrefixNotRegistred,
        DisassembleResultError.invalidPostNumber =>
          l10n.disassembleInvalidPostNumber,
        DisassembleResultError.noExtension => l10n.disassembleNoExtension,
        DisassembleResultError.hashIsInvalid => l10n.disassembleHashIsInvalid,
        DisassembleResultError.extensionTooLong =>
          l10n.disassembleExtensionTooLong,
        DisassembleResultError.hashIsnt32 => l10n.disassembleHashIsnt32,
      };
}

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

  static final _numbersLetters = RegExp(r"^[a-zA-Z0-9]+$");
  static final _numbersLettersLowercase = RegExp(r"^[a-z0-9]+$");

  /// Tries to disassemble the [filename] into the convenient class.
  /// Throws on error, with the reason string.
  static ErrorOr<DisassembleResult> fromFilename(
    String filename_, {
    Booru? suppliedBooru,
  }) {
    var filename = filename_;

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

    if (!_numbersLettersLowercase.hasMatch(hashAndExt.first)) {
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

    if (!_numbersLetters.hasMatch(hashAndExt.last)) {
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
  const ErrorOr.error(String Function(AppLocalizations l10n) error)
      : _error = error,
        _data = null;
  const ErrorOr.value(T result)
      : _data = result,
        _error = null;

  final T? _data;
  final String Function(AppLocalizations l10n)? _error;

  T asValue() => _data!;
  T? maybeValue() => _data;

  String? asError(AppLocalizations l10n) => _error!(l10n);

  bool get hasError => _error != null;
  bool get hasValue => _data != null;
}

void openAddTagDialog(
  BuildContext context,
  void Function(String, bool) onSubmit,
  AppLocalizations l10n,
) {
  final regexp = RegExp(r"[^A-Za-z0-9_\(\)']");
  bool delete = false;

  Navigator.push(
    context,
    DialogRoute<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addTag),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                autovalidateMode: AutovalidateMode.always,
                child: TextFormField(
                  enabled: true,
                  validator: (value) {
                    if (value == null) {
                      return l10n.valueIsNull;
                    }

                    final v = value.trim();
                    if (v.isEmpty) {
                      return l10n.valueIsEmpty;
                    }

                    if (v.length <= 1) {
                      return l10n.valueIsEmpty;
                    }

                    if (regexp.hasMatch(v)) {
                      return l10n.tagValidationError;
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    final v = value.trim();
                    if (v.isEmpty || v.length <= 1 || regexp.hasMatch(v)) {
                      return;
                    }

                    onSubmit(v, delete);
                    Navigator.pop(context);
                  },
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text(l10n.delete),
                    value: delete,
                    onChanged: (v) {
                      delete = v;

                      setState(() {});
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
