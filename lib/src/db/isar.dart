// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io' as io;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/schemas/upload_files_state.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../booru/tags/tags.dart';
import '../pages/booru_scroll.dart';
import '../schemas/settings.dart';

import 'package:path/path.dart' as path;

part 'grids.dart';

Isar? _isar;
late String _directoryPath;
late String _temporaryDbPath;
//Isar? _isarCopy;
bool _initalized = false;
const MethodChannel _channel = MethodChannel("lol.bruh19.azari.gallery");

/// [getBooru] returns a selected *booru API.
/// Some *booru have no way to retreive posts down
/// of a post number, in this case [page] comes in handy:
/// that is, it makes refreshes on restore few.
BooruAPI getBooru({int? page}) {
  Dio dio = Dio(BaseOptions(
    //headers: {"user-agent": kTorUserAgent},
    responseType: ResponseType.json,
  ));

  var settings = settingsIsar().settings.getSync(0);
  if (settings!.selectedBooru == Booru.danbooru) {
    var jar = UnsaveableCookieJar(CookieJarTab().get(Booru.danbooru));

    dio.interceptors.add(CookieManager(jar));
    return Danbooru(dio, jar);
  } else if (settings.selectedBooru == Booru.gelbooru) {
    var jar = UnsaveableCookieJar(CookieJarTab().get(Booru.gelbooru));

    dio.interceptors.add(CookieManager(jar));
    return Gelbooru(page ?? 0, dio, jar);
  } else {
    throw "invalid booru";
  }
}

Future initalizeIsar() async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  _directoryPath = (await getApplicationSupportDirectory()).path;

  var d = io.Directory(path.joinAll([_directoryPath, "temporary"]));
  d.createSync();
  d.deleteSync(recursive: true);
  d.createSync();

  _temporaryDbPath = d.path;

  await Isar.open([SettingsSchema, FileSchema, ServerSettingsSchema],
          directory: _directoryPath, inspector: false)
      .then((value) {
    _isar = value;
  });
}

Isar settingsIsar() => _isar!;

void _closePrimaryGridIsar(Booru booru) {
  Isar.getInstance(booru.string)?.close();
}

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

Isar openServerApiIsar() {
  /*var i = Isar.getInstance("serverApi");
  if (i != null) {
    return i;
  }*/

  return Isar.openSync([DirectorySchema],
      directory: _directoryPath, inspector: false, name: "serverApi");
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
      db.uploadFilesStacks.putAllSync(
          list.map((e) => e..status = UploadStatus.failed).toList());
    });
  }

  return db;
}

Isar openTagsDbIsar() {
  return Isar.openSync([LocalTagsSchema],
      directory: _directoryPath, inspector: false, name: "localTags");
}

void closeServerApiIsar() {
  var i = Isar.getInstance("serverApi");
  if (i != null) {
    i.close();
  }
}

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

Isar openAndroidGalleryIsar() {
  return Isar.openSync(
      [SystemGalleryDirectorySchema, GalleryLastModifiedSchema],
      directory: _directoryPath,
      inspector: false,
      name: "systemGalleryDirectories");
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
    resp = await _channel.invokeMethod("chooseDirectory");
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
