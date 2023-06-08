// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/local_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../pages/booru_scroll.dart';
import '../schemas/settings.dart';

import 'package:path/path.dart' as path;

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
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
    },
    responseType: ResponseType.json,
  ));

  var settings = isar().settings.getSync(0);
  if (settings!.selectedBooru == Booru.danbooru) {
    return Danbooru(dio);
  } else if (settings.selectedBooru == Booru.gelbooru) {
    return Gelbooru(page ?? 0, dio);
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

  await Isar.open([
    SettingsSchema,
    LastTagsSchema,
    FileSchema,
    PostSchema,
    ScrollPositionPrimarySchema,
    ExcludedTagsSchema,
    GridRestoreSchema,
    ServerSettingsSchema
  ], directory: _directoryPath, inspector: false)
      .then((value) {
    _isar = value;
  });
}

void restoreState(BuildContext context, bool pushBooru) {
  if (pushBooru) {
    Navigator.pushReplacementNamed(context, "/booru");
  }
  var toRestore = isar().gridRestores.where().sortByDateDesc().findAllSync();

  _restoreState(context, toRestore, true);
}

void _restoreState(
    BuildContext context, List<GridRestore> toRestore, bool push) {
  if (toRestore.isEmpty) {
    if (!push) {
      Navigator.pop(context);
    }
    return;
  }

  for (true;;) {
    var restore = toRestore.removeAt(0);

    var isarR = restoreIsarGrid(restore.path);

    var state = isarR.secondaryGrids.getSync(0);

    if (state == null) {
      removeSecondaryGrid(isarR.name);
      continue;
    }

    var page = MaterialPageRoute(
      builder: (context) {
        return BooruScroll.restore(
          isar: isarR,
          tags: state.tags,
          initalScroll: state.scrollPositionGrid,
          pageViewScrollingOffset: state.scrollPositionTags,
          initalPost: state.selectedPost,
          booruPage: state.page,
        );
      },
    );

    if (push) {
      Navigator.push(context, page);
    } else {
      Navigator.pushReplacement(
        context,
        page,
      );
    }

    break;
  }
}

void restoreStateNext(BuildContext context, String exclude) {
  var toRestore = isar()
      .gridRestores
      .where()
      .pathNotEqualTo(exclude)
      .sortByDateDesc()
      .findAllSync();

  _restoreState(context, toRestore, false);
}

Isar isar() => _isar!;

Isar openServerApiIsar() {
  /*var i = Isar.getInstance("serverApi");
  if (i != null) {
    return i;
  }*/

  return Isar.openSync([DirectorySchema],
      directory: _directoryPath, inspector: false, name: "serverApi");
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

Isar restoreIsarGrid(String path) {
  return Isar.openSync([PostSchema, SecondaryGridSchema],
      directory: _directoryPath, inspector: false, name: path);
}

Future<Isar> newSecondaryGrid() async {
  var p = DateTime.now().millisecondsSinceEpoch.toString();

  isar().writeTxnSync(() => isar().gridRestores.putSync(GridRestore(p)));

  return Isar.open([PostSchema, SecondaryGridSchema],
      directory: _directoryPath, inspector: false, name: p);
}

void removeSecondaryGrid(String name) {
  var grid = isar().gridRestores.filter().pathEqualTo(name).findFirstSync();
  if (grid != null) {
    var db = Isar.getInstance(grid.path);
    if (db != null) {
      db.close(deleteFromDisk: true);
    }
    isar().writeTxnSync(() => isar().gridRestores.deleteSync(grid.id!));
  }
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

  var settings = isar().settings.getSync(0) ?? Settings.empty();
  isar().writeTxnSync(() => isar().settings.putSync(settings.copy(path: resp)));

  return Future.value(true);
}
