// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/schemas/upload_files_state.dart';
import 'package:http_parser/http_parser.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

import '../../db/isar.dart';
import '../../plugs/notifications.dart';
import '../../schemas/server_settings.dart';

Uploader? _global;
bool _isInitalized = false;

class _HostFileAndDir {
  final Uri host;
  final List<FileAndDir> f;
  final int stackId;
  final void Function() onSuccess;

  const _HostFileAndDir(this.host, this.f, this.onSuccess, this.stackId);
}

Map<String, dynamic> _deviceId(ServerSettings s) => {
      "deviceId": hex.encode(s.deviceId),
    };

ServerSettings _settings() {
  var settings = settingsIsar().serverSettings.getSync(0);

  if (settings == null) {
    throw "Server settings should be set";
  }

  return settings;
}

/// Upload files to the server.
class Uploader {
  final _stack = <_HostFileAndDir>[];
  final client = Dio();
  final NotificationPlug notification = chooseNotificationPlug();
  final Isar uploadsDb = openUploadsDbIsar();

  int id = 0;
  bool inProgress = false;

  int count() => _stack.length;

  List<UploadFilesStack> getStack() =>
      uploadsDb.uploadFilesStacks.where().findAllSync();

  void add(
    Uri host,
    List<FileAndDir> f,
    void Function() onDone,
  ) {
    var stackId = uploadsDb.writeTxnSync(() {
      var id = uploadsDb.uploadFilesStates.putSync(UploadFilesState(f
          .map((e) => Batch()
            ..name = e.res.name
            ..failReason = "")
          .toList()));
      return uploadsDb.uploadFilesStacks.putSync(UploadFilesStack(
          stateId: id, status: UploadStatus.inProgress, count: f.length));
    });

    if (inProgress) {
      _stack.add(_HostFileAndDir(host, f, onDone, stackId));
    } else {
      _start(_HostFileAndDir(host, f, onDone, stackId));
    }
  }

  void _start(_HostFileAndDir f) async {
    inProgress = true;
    id--;

    final formData = FormData();

    for (final element in f.f) {
      final mimt = lookupMimeType(element.res.name);
      var tags = PostTags().getTagsPost(element.res.name);
      if (tags.isEmpty) {
        tags = await PostTags().getOnlineAndSaveTags(element.res.name);
      }

      formData.files.add(MapEntry(
          element.res.name,
          MultipartFile(element.res.readStream!, element.res.size,
              filename: element.res.name,
              contentType: MediaType.parse(mimt!),
              headers: {
                "dir": [element.dir],
                "name": [element.res.name],
                if (tags.isNotEmpty) "tags": [tags.join(" ")],
              })));
    }

    final progress = await notification.newProgress(
        "${f.f.length.toString()} files", id, "Uploading", "Uploader");

    try {
      final settings = _settings();

      final req = await client.postUri(f.host.replace(path: "/add/files"),
          onSendProgress: (count, total) {
        if (count == total) {
          progress.done();
          return;
        }

        progress.setTotal(total);
        progress.update(count);
      },
          options: Options(
              headers: _deviceId(settings),
              contentType: Headers.multipartFormDataContentType),
          data: formData);

      if (req.statusCode != 200) {
        throw "not 200";
      }

      final failed = req.data["failed"];

      if (failed != null && (failed as List).isNotEmpty) {
        log('failed: ${req.data["failed"]}');
      }

      f.onSuccess();

      uploadsDb.writeTxnSync(() {
        final stack = uploadsDb.uploadFilesStacks.getSync(f.stackId);
        if (stack != null) {
          uploadsDb.uploadFilesStates.deleteSync(stack.stateId);
          uploadsDb.uploadFilesStacks.deleteSync(stack.isarId!);
        }
      });
    } catch (e, trace) {
      uploadsDb.writeTxnSync(() {
        final stack = uploadsDb.uploadFilesStacks.getSync(f.stackId);
        if (stack != null) {
          uploadsDb.uploadFilesStacks.putSync(stack.failed());
        }
      });
      progress.error(e.toString());
      log("uploading file",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    _done();
  }

  void _done() {
    inProgress = false;
    if (_stack.isNotEmpty) {
      _start(
        _stack.first,
      );
      _stack.removeAt(0);
    }
  }

  Uploader._new();

  factory Uploader() {
    return _global!;
  }
}

void initalizeUploader() {
  if (_isInitalized) {
    return;
  }
  _isInitalized = true;
  _global = Uploader._new();
}

class FileAndDir {
  final String dir;
  final PlatformFile res;

  const FileAndDir(this.dir, this.res);
}
