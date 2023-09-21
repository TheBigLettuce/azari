// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/directory_tags.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/favorite_booru.dart';
import 'package:gallery/src/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/pinned_directories.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/grid_state.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../schemas/favorite_media.dart';
import '../schemas/settings.dart';

import 'package:path/path.dart' as path;

class Dbs {
  final Isar main;
  final Isar? thumbnail;
  final Isar? blacklisted;

  final String directory;
  final String temporaryDbDir;
  final String temporaryImagesDir;

  String get appStorageDir => directory;

  void clearTemporaryImages() {
    io.Directory(temporaryImagesDir)
      ..createSync()
      ..deleteSync(recursive: true)
      ..createSync();
  }

  const Dbs._(
      {required this.blacklisted,
      required this.directory,
      required this.main,
      required this.temporaryDbDir,
      required this.temporaryImagesDir,
      required this.thumbnail});

  static Dbs get g => _dbs;
}

late final Dbs _dbs;
bool _initalized = false;

Future initalizeIsar(bool temporary) async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  final directoryPath = (await getApplicationSupportDirectory()).path;

  final d = io.Directory(path.joinAll([directoryPath, "temporary"]));
  d.createSync();
  if (!temporary) {
    d.deleteSync(recursive: true);
    d.createSync();
  }
  final temporaryDbPath = d.path;

  final dimages = io.Directory(path.joinAll([directoryPath, "temp_images"]));
  dimages.createSync();
  if (!temporary) {
    dimages.deleteSync(recursive: true);
    dimages.createSync();
  }

  final temporaryImagesPath = dimages.path;

  final main = Isar.openSync([
    SettingsSchema,
    FavoriteBooruSchema,
    LocalTagDictionarySchema,
    DownloadFileSchema
  ], directory: directoryPath, inspector: false);

  Isar? thumbnailIsar;
  Isar? blacklistedDirIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync([ThumbnailSchema],
        directory: directoryPath, inspector: false, name: "androidThumbnails");
    thumbnailIsar.writeTxnSync(() {
      thumbnailIsar!.thumbnails
          .where()
          .differenceHashEqualTo(0)
          .deleteAllSync();
    });
    blacklistedDirIsar = Isar.openSync([
      BlacklistedDirectorySchema,
      PinnedDirectoriesSchema,
      FavoriteMediaSchema
    ],
        directory: directoryPath,
        inspector: false,
        name: "androidBlacklistedDir");
  }

  _dbs = Dbs._(
      directory: directoryPath,
      main: main,
      temporaryDbDir: temporaryDbPath,
      temporaryImagesDir: temporaryImagesPath,
      blacklisted: blacklistedDirIsar,
      thumbnail: thumbnailIsar);
}

String _microsecSinceEpoch() =>
    DateTime.now().microsecondsSinceEpoch.toString();

class IsarDbsOpen {
  static Isar primaryGrid(Booru booru) {
    final instance = Isar.getInstance(booru.string);
    if (instance != null) {
      return instance;
    }

    return Isar.openSync([
      GridStateSchema,
      TagSchema,
      PostSchema,
    ], directory: _dbs.directory, inspector: false, name: booru.string);
  }

  static Isar secondaryGrid({bool temporary = true}) {
    return Isar.openSync([PostSchema],
        directory: temporary ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: _microsecSinceEpoch());
  }

  static Isar secondaryGridName(String name) {
    return Isar.openSync([PostSchema],
        directory: _dbs.directory, inspector: false, name: name);
  }

  static Isar localTags() => Isar.openSync(
        [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
        directory: _dbs.directory,
        inspector: false,
        name: "localTags",
      );

  static Isar androidGalleryDirectories({bool? temporary}) => Isar.openSync(
        [SystemGalleryDirectorySchema],
        directory: temporary == true ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: temporary == true
            ? _microsecSinceEpoch()
            : "systemGalleryDirectories",
      );

  static Isar androidGalleryFiles() => Isar.openSync(
        [SystemGalleryDirectoryFileSchema],
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static Isar temporarySchemas(List<CollectionSchema> schemas) => Isar.openSync(
        schemas,
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );
}

/// Pick an operating system directory.
/// Calls [onError] in case of any error and resolves to false.
Future<bool> chooseDirectory(void Function(String) onError) async {
  late final String resp;

  if (io.Platform.isAndroid) {
    try {
      resp = (await PlatformFunctions.chooseDirectory())!;
    } catch (e) {
      onError((e as PlatformException).code);
      return false;
    }
  } else {
    final r = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Pick a directory for downloads");
    if (r == null) {
      onError("Please choose a valid directory");
      return false;
    }
    resp = r;
  }

  Settings.fromDb().copy(path: resp).save();

  return Future.value(true);
}
