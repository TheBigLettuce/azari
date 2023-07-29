// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/directory_tags.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/expensive_hash.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/pinned_directories.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/schemas/upload_files_state.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../booru/tags/tags.dart';
import '../pages/booru_scroll.dart';
import '../schemas/settings.dart';

import 'package:path/path.dart' as path;

part 'grids.dart';

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
Isar? _expensiveHashIsar;
Isar? _blacklistedDirIsar;
late String _directoryPath;
late String _temporaryDbPath;
late String _temporaryImagesPath;
//Isar? _isarCopy;
bool _initalized = false;

BooruAPI booruApiFromPrefix(Booru booru, {int? page}) {
  Dio dio = Dio(BaseOptions(
    //headers: {"user-agent": kTorUserAgent},
    responseType: ResponseType.json,
  ));

  final jar = UnsaveableCookieJar(CookieJarTab().get(booru));
  dio.interceptors.add(CookieManager(jar));

  return switch (booru) {
    Booru.danbooru => Danbooru(dio, jar),
    Booru.gelbooru => Gelbooru(page ?? 0, dio, jar)
  };
}

/// [getBooru] returns a selected *booru API.
/// Some *booru have no way to retreive posts down
/// of a post number, in this case [page] comes in handy:
/// that is, it makes refreshes on restore few.
BooruAPI getBooru({int? page}) {
  Dio dio = Dio(BaseOptions(
    //headers: {"user-agent": kTorUserAgent},
    responseType: ResponseType.json,
  ));

  final settings = settingsIsar().settings.getSync(0);
  if (settings!.selectedBooru == Booru.danbooru) {
    final jar = UnsaveableCookieJar(CookieJarTab().get(Booru.danbooru));

    dio.interceptors.add(CookieManager(jar));
    return Danbooru(dio, jar);
  } else if (settings.selectedBooru == Booru.gelbooru) {
    final jar = UnsaveableCookieJar(CookieJarTab().get(Booru.gelbooru));

    dio.interceptors.add(CookieManager(jar));
    return Gelbooru(page ?? 0, dio, jar);
  } else {
    throw "invalid booru";
  }
}

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

  await Isar.open([SettingsSchema, FileSchema, ServerSettingsSchema],
          directory: _directoryPath, inspector: false)
      .then((value) {
    _isar = value;
  });

  if (io.Platform.isAndroid) {
    _thumbnailIsar = Isar.openSync([ThumbnailSchema],
        directory: _directoryPath, inspector: false, name: "androidThumbnails");
    _thumbnailIsar!.writeTxnSync(() {
      _thumbnailIsar!.thumbnails.where().isEmptyEqualTo(true).deleteAllSync();
    });
    _expensiveHashIsar = Isar.openSync([PerceptionHashSchema],
        directory: _directoryPath,
        inspector: false,
        name: "androidExpensiveHash");
    _blacklistedDirIsar = Isar.openSync(
        [BlacklistedDirectorySchema, PinnedDirectoriesSchema],
        directory: _directoryPath,
        inspector: false,
        name: "androidBlacklistedDir");
  }
}

Isar thumbnailIsar() => _thumbnailIsar!;
Isar settingsIsar() => _isar!;
Isar expensiveHashIsar() => _expensiveHashIsar!;
Isar blacklistedDirIsar() => _blacklistedDirIsar!;

Isar _primaryGridIsar(Booru booru) {
  var instance = Isar.getInstance(booru.string);
  if (instance != null) {
    return instance;
  }

  return Isar.openSync([
    GridRestoreSchema,
    TagSchema,
    ScrollPositionPrimarySchema,
    PostSchema,
  ], directory: _directoryPath, inspector: false, name: booru.string);
}

Isar openServerApiIsar({bool? temporary}) {
  return Isar.openSync([DirectorySchema],
      directory: temporary == true ? _temporaryDbPath : _directoryPath,
      inspector: false,
      name: temporary == true
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : "serverApi");
}

Isar openUploadsDbIsar() {
  var db = Isar.openSync([UploadFilesStackSchema, UploadFilesStateSchema],
      directory: _directoryPath, inspector: false, name: "uploadsDb");

  var list = db.uploadFilesStacks
      .filter()
      .statusEqualTo(UploadStatus.inProgress)
      .findAllSync();

  if (list.isNotEmpty) {
    db.writeTxnSync(() {
      db.uploadFilesStacks.putAllSync(list.map((e) => e.failed()).toList());
    });
  }

  return db;
}

Isar openTagsDbIsar() {
  return Isar.openSync(
      [LocalTagsSchema, LocalTagDictionarySchema, DirectoryTagSchema],
      directory: _directoryPath, inspector: false, name: "localTags");
}

void closeServerApiIsar() {
  var i = Isar.getInstance("serverApi");
  if (i != null) {
    i.close();
  }
}

String _microsecNow() => DateTime.now().microsecondsSinceEpoch.toString();

Isar openServerApiInnerIsar() {
  var name = DateTime.now().microsecondsSinceEpoch.toString();

  return Isar.openSync(
    [DirectoryFileSchema],
    directory: _temporaryDbPath,
    inspector: false,
    name: name,
  );
}

void closeServerApiInnerIsar(String name) {
  var db = Isar.getInstance(name);
  if (db != null) {
    db.close(deleteFromDisk: true);
  }
}

Isar openAndroidGalleryIsar({bool? temporary}) {
  return Isar.openSync(
      [SystemGalleryDirectorySchema, GalleryLastModifiedSchema],
      directory: temporary == true ? _temporaryDbPath : _directoryPath,
      inspector: false,
      name: temporary == true
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : "systemGalleryDirectories");
}

Isar openAndroidGalleryInnerIsar() {
  return Isar.openSync([SystemGalleryDirectoryFileSchema],
      directory: _temporaryDbPath,
      inspector: false,
      name: DateTime.now().microsecondsSinceEpoch.toString());
}

Isar openDirectoryIsar() {
  return Isar.openSync([DirectorySchema],
      directory: _directoryPath, inspector: false, name: "directories");
}

void closeDirectoryIsar() {
  var instance = Isar.getInstance("directories");
  if (instance != null) {
    instance.close();
  }
}

Isar _restoreIsarGrid(String path) {
  return Isar.openSync([PostSchema, SecondaryGridSchema],
      directory: _directoryPath, inspector: false, name: path);
}

Future<bool> chooseDirectory(void Function(String) onError) async {
  String resp;

  if (io.Platform.isAndroid) {
    resp = (await PlatformFunctions.chooseDirectory())!;
  } else {
    var r = await FilePicker.platform
        .getDirectoryPath(dialogTitle: "Pick a directory for downloads");
    if (r == null) {
      onError("Please choose a valid directory");
      return false;
    }
    resp = r;
  }

  var settings = settingsIsar().settings.getSync(0) ?? Settings.empty();
  settingsIsar().writeTxnSync(
      () => settingsIsar().settings.putSync(settings.copy(path: resp)));

  return Future.value(true);
}
