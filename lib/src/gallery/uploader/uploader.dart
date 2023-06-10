import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/schemas/upload_files_state.dart';
import 'package:http_parser/http_parser.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

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
  var settings = isar().serverSettings.getSync(0);

  if (settings == null) {
    throw "Server settings should be set";
  }

  return settings;
}

class Uploader {
  final List<_HostFileAndDir> _stack = [];
  int id = 0;
  bool inProgress = false;
  var client = Dio();
  NotificationPlug notification = chooseNotificationPlug();
  Isar uploadsDb = openUploadsDbIsar();

  List<UploadFilesStack> getStack() {
    return uploadsDb.uploadFilesStacks.where().findAllSync();
  }

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

  int count() => _stack.length;

  void _start(_HostFileAndDir f) async {
    inProgress = true;
    id--;

    var formData = FormData();

    for (var element in f.f) {
      var mimt = lookupMimeType(element.res.name);
      var tags = BooruTags().getTagsPost(element.res.name);
      if (tags.isEmpty) {
        tags = await BooruTags().getOnlineAndSaveTags(element.res.name);
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

    var progress = await notification.newProgress(
        "${f.f.length.toString()} files", id, "Uploading");

    try {
      var settings = _settings();

      var req = await client.postUri(f.host.replace(path: "/add/files"),
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

      var failed = req.data["failed"];

      if (failed != null && (failed as List).isNotEmpty) {
        log('failed: ${req.data["failed"]}');
      }

      f.onSuccess();

      uploadsDb.writeTxnSync(() {
        var stack = uploadsDb.uploadFilesStacks.getSync(f.stackId);
        if (stack != null) {
          uploadsDb.uploadFilesStates.deleteSync(stack.stateId);
          uploadsDb.uploadFilesStacks.deleteSync(stack.isarId!);
        }
      });
    } catch (e, trace) {
      uploadsDb.writeTxnSync(() {
        var stack = uploadsDb.uploadFilesStacks.getSync(f.stackId);
        if (stack != null) {
          uploadsDb.uploadFilesStacks
              .putSync(stack..status = UploadStatus.failed);
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
