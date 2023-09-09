// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/directory_tags.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/favorite_booru.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
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

String appStorageDir() => _directoryPath;
String temporaryDbDir() => _temporaryDbPath;
String temporaryImagesDir() => _temporaryImagesPath;
void clearTemporaryImagesDir() {
  io.Directory(_temporaryImagesPath)
    ..createSync()
    ..deleteSync(recursive: true)
    ..createSync();
}

Isar? _isar;
Isar? _thumbnailIsar;
Isar? _blacklistedDirIsar;
late String _directoryPath;
late String _temporaryDbPath;
late String _temporaryImagesPath;
bool _initalized = false;

Future initalizeIsar(bool temporary) async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  _directoryPath = (await getApplicationSupportDirectory()).path;

  final d = io.Directory(path.joinAll([_directoryPath, "temporary"]));
  d.createSync();
  if (!temporary) {
    d.deleteSync(recursive: true);
    d.createSync();
  }
  _temporaryDbPath = d.path;

  final dimages = io.Directory(path.joinAll([_directoryPath, "temp_images"]));
  dimages.createSync();
  if (!temporary) {
    dimages.deleteSync(recursive: true);
    dimages.createSync();
  }

  _temporaryImagesPath = dimages.path;

  _isar = Isar.openSync([
    SettingsSchema,
    FavoriteBooruSchema,
    LocalTagDictionarySchema,
    FileSchema
  ], directory: _directoryPath, inspector: false);

  if (io.Platform.isAndroid) {
    _thumbnailIsar = Isar.openSync([ThumbnailSchema],
        directory: _directoryPath, inspector: false, name: "androidThumbnails");
    _thumbnailIsar!.writeTxnSync(() {
      _thumbnailIsar!.thumbnails
          .where()
          .differenceHashEqualTo(0)
          .deleteAllSync();
    });
    _blacklistedDirIsar = Isar.openSync([
      BlacklistedDirectorySchema,
      PinnedDirectoriesSchema,
      FavoriteMediaSchema
    ],
        directory: _directoryPath,
        inspector: false,
        name: "androidBlacklistedDir");
  }
}

Isar thumbnailIsar() => _thumbnailIsar!;
Isar settingsIsar() => _isar!;
Isar blacklistedDirIsar() => _blacklistedDirIsar!;

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
    ], directory: _directoryPath, inspector: false, name: booru.string);
  }

  static Isar secondaryGrid({bool temporary = true}) {
    return Isar.openSync([PostSchema],
        directory: temporary ? _temporaryDbPath : _directoryPath,
        inspector: false,
        name: _microsecSinceEpoch());
  }

  static Isar secondaryGridName(String name) {
    return Isar.openSync([PostSchema],
        directory: _directoryPath, inspector: false, name: name);
  }

  static Isar localTags() => Isar.openSync(
        [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
        directory: _directoryPath,
        inspector: false,
        name: "localTags",
      );

  static Isar androidGalleryDirectories({bool? temporary}) => Isar.openSync(
        [SystemGalleryDirectorySchema, GalleryLastModifiedSchema],
        directory: temporary == true ? _temporaryDbPath : _directoryPath,
        inspector: false,
        name: temporary == true
            ? _microsecSinceEpoch()
            : "systemGalleryDirectories",
      );

  static Isar androidGalleryFiles() => Isar.openSync(
        [SystemGalleryDirectoryFileSchema],
        directory: _temporaryDbPath,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static Isar temporarySchemas(List<CollectionSchema> schemas) => Isar.openSync(
        schemas,
        directory: _temporaryDbPath,
        inspector: false,
        name: _microsecSinceEpoch(),
      );
}

/// Pick an operating system directory.
/// Calls [onError] in case of any error and resolves to false.
Future<bool> chooseDirectory(void Function(String) onError) async {
  late final String resp;

  if (io.Platform.isAndroid) {
    resp = (await PlatformFunctions.chooseDirectory())!;
  } else {
    final r = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Pick a directory for downloads");
    if (r == null) {
      onError("Please choose a valid directory");
      return false;
    }
    resp = r;
  }

  Settings.saveToDb(Settings.fromDb().copy(path: resp));

  return Future.value(true);
}
