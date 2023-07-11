// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';

import '../../widgets/search_filter_grid.dart';

part 'server_api_files.dart';

Map<String, dynamic> _deviceId() {
  final s = _settings();

  return {
    "deviceId": hex.encode(s.deviceId),
  };
}

ServerSettings _settings() {
  var settings = settingsIsar().serverSettings.getSync(0);

  if (settings == null) {
    throw "Server settings should be set";
  }

  return settings;
}

String _fromBaseToHex(String v) {
  return hex.encode(base64Decode(v));
}

class ServerApiExtra {
  final _ServerAPI _impl;

  FilterInterface<Directory, Directory> get filter => _impl.filter;

  const ServerApiExtra._(this._impl);
}

class ServerApiFilesExtra {
  final _ImagesImpl _impl;

  FilterInterface<DirectoryFile, DirectoryFileShrinked> get filter =>
      _impl.filter;

  const ServerApiFilesExtra._(this._impl);
}

GalleryAPIReadWrite<ServerApiExtra, ServerApiFilesExtra, Directory, Directory,
    DirectoryFile, DirectoryFileShrinked> getServerGalleryApi() {
  return _ServerAPI(openServerApiIsar());
}

class _ServerAPI
    implements
        GalleryAPIReadWrite<ServerApiExtra, ServerApiFilesExtra, Directory,
            Directory, DirectoryFile, DirectoryFileShrinked> {
  final Isar db;

  final IsarFilter<Directory, Directory> filter;

  @override
  ServerApiExtra getExtra() {
    return ServerApiExtra._(this);
  }

  @override
  Directory directCell(int i) {
    return db.directorys.getSync(i + 1)!;
  }

  final Dio client = Dio(BaseOptions(
      responseType: ResponseType.json,
      contentType: Headers.formUrlEncodedContentType))
    ..interceptors.add(LogInterceptor(responseBody: false, requestBody: true));

  @override
  Future<int> refresh() async {
    var settings = _settings();

    var resp = await client.getUri(
      Uri.parse(settings.host).replace(path: "/dirs"),
      options: Options(headers: _deviceId()),
    );
    if (resp.statusCode != 200) {
      throw resp.data;
    }

    var list = (resp.data as List)
        .map((e) => Directory(
            time: e["time"],
            dirName: e["alias"],
            count: e["count"],
            serverUrl: settings.host,
            imageHash: e["thumbhash"],
            dirPath: e["path"]))
        .toList();
    list.sort((v1, v2) {
      if (v1.time < v2.time) {
        return 1;
      } else if (v1.time > v2.time) {
        return -1;
      } else {
        return 0;
      }
    });

    db.writeTxnSync(() {
      db.clearSync();

      db.directorys.putAllSync(list);
    });

    return db.directorys.countSync();
  }

  @override
  void close() {
    db.close();
    client.close(force: true);
    filter.dispose();
  }

  _ServerAPI(this.db)
      : filter = IsarFilter<Directory, Directory>(
            db, openServerApiIsar(temporary: true), (offset, limit, s) {
          return db.directorys
              .filter()
              .dirNameContains(s, caseSensitive: false)
              .offset(offset)
              .limit(limit)
              .findAllSync();
        });

  @override
  GalleryAPIFilesRead<ServerApiFilesExtra, DirectoryFile, DirectoryFileShrinked>
      imagesRead(Directory d) {
    return _ImagesImpl(openServerApiInnerIsar(), client, d);
  }

  @override
  GalleryAPIFilesReadWrite<ServerApiFilesExtra, DirectoryFile,
      DirectoryFileShrinked> imagesReadWrite(Directory d) {
    return _ImagesImpl(openServerApiInnerIsar(), client, d);
  }

  @override
  Future newDirectory(String path, void Function() onDone) async {
    var res = await FilePicker.platform.pickFiles(
        type: FileType.image, allowCompression: false, withReadStream: true);
    if (res == null) {
      throw "no result";
    }

    var settings = _settings();

    Uploader().add(Uri.parse(settings.host),
        res.files.map((e) => FileAndDir(path, e)).toList(), onDone);

    return Future.value();
  }

  @override
  Future delete(Directory d) async {
    var resp = await client.postUri(
        Uri.parse(d.serverUrl).replace(path: "/delete/dir/${d.dirPath}"),
        options: Options(headers: _deviceId()));

    return Future.value();
  }

  @override
  Future modify(Directory old, Directory newd) async {
    var resp = await client
        .postUri(Uri.parse(old.serverUrl).replace(path: "/modify/dir"),
            options: Options(
              headers: _deviceId(),
            ),
            data: {
          "dir": old.dirPath,
          if (old.imageHash != newd.imageHash) "newhash": newd.imageHash,
          if (old.dirName != newd.dirName) "newalias": newd.dirName
        });

    return Future.value();
  }
}
