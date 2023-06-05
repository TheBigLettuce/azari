// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/schemas/download_file.dart' as dw_file;
import 'package:gallery/src/schemas/settings.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import '../../db/isar.dart';

Downloader? _global;

mixin CancelTokens {
  final Map<int, CancelToken> _tokens = {};

  void _addToken(int key, CancelToken t) => _tokens[key] = t;
  void _removeToken(int key) => _tokens.remove(key);
  bool _hasCancelKey(int id) => _tokens[id] != null;
}

class Downloader with CancelTokens {
  int _inWork = 0;
  final Dio dio = Dio();
  final int maximum;

  NotificationPlug notificationPlug = chooseNotificationPlug();
  DownloadMoverPlug moverPlug;

  void retry(dw_file.File f) {
    if (f.isOnHold()) {
      isar().writeTxnSync(() => isar().files.putSync(f.failed()));
    } else if (_hasCancelKey(f.id!)) {
      cancelAndRemoveToken(f.id!);
    } else {
      add(f);
    }
  }

  String downloadAction(dw_file.File f) {
    if (f.isOnHold() || _hasCancelKey(f.id!)) {
      return "Cancel the download?";
    } else {
      return "Retry?";
    }
  }

  String downloadDescription(dw_file.File f) {
    if (f.isOnHold()) {
      return "On hold";
    }

    if (_hasCancelKey(f.id!)) {
      return "In progress";
    }

    return "Failed";
  }

  void cancelAndRemoveToken(int key) {
    var t = _tokens[key];
    if (t == null) {
      return;
    }

    t.cancel();
    _tokens.remove(key);
  }

  void _done() {
    if (_inWork <= maximum) {
      var f = isar()
          .files
          .filter()
          .inProgressEqualTo(false)
          .isFailedEqualTo(false)
          .findFirstSync();
      if (f != null) {
        isar().writeTxnSync(
          () => isar().files.putSync(f.inprogress()),
        );
        _addToken(f.id!, CancelToken());
        _download(f);
      } else {
        _inWork--;
      }
    } else {
      _inWork--;
    }
  }

  void restart() async {
    var f = isar()
        .files
        .filter()
        .isFailedEqualTo(true)
        .sortByDateDesc()
        .findAllSync();

    if (f.length < 6) {
      f.addAll(isar()
          .files
          .where()
          .sortByDateDesc()
          .limit(6 - f.length)
          .findAllSync());
    }
    for (var element in f) {
      add(element);
    }
  }

  void add(dw_file.File download) async {
    if (download.id != null && _hasCancelKey(download.id!)) {
      return;
    }

    isar().writeTxnSync(() => isar().files.putSync(download.onHold()));

    if (_inWork <= maximum) {
      _inWork++;
      var d = download.inprogress();
      var id = isar().writeTxnSync(() => isar().files.putSync(d));
      _download(d);
      _addToken(id, CancelToken());
    }
  }

  void removeFailed() {
    isar().writeTxnSync(() {
      var failed = isar()
          .files
          .filter()
          .isFailedEqualTo(true)
          .findAllSync()
          .map((e) => e.id!)
          .toList();
      if (failed.isNotEmpty) {
        isar().files.deleteAllSync(failed);
      }
    });
  }

  void markStale() {
    isar().writeTxnSync(() {
      List<dw_file.File> toUpdate = [];

      var inProgress =
          isar().files.filter().inProgressEqualTo(true).findAllSync();
      for (var element in inProgress) {
        if (_tokens[element.id!] == null) {
          toUpdate.add(element.failed());
        }
      }

      if (toUpdate.isNotEmpty) {
        isar().files.putAllSync(toUpdate);
      }
    });
  }

  void _download(dw_file.File d) async {
    var downloadtd = Directory(
        path.joinAll([(await getTemporaryDirectory()).path, "downloads"]));

    var dirpath = path.joinAll([downloadtd.path, d.site]);
    try {
      if (!downloadtd.existsSync()) {
        downloadtd.createSync();
      }
      await Directory(dirpath).create();
    } catch (e, trace) {
      log("while creating directory $dirpath",
          level: Level.SEVERE.value, error: e, stackTrace: trace);

      return;
    }

    var filePath = path.joinAll([downloadtd.path, d.site, d.name]);

    // can it throw 🤔
    if (File(filePath).existsSync()) {
      _done();
      return;
    }

    var progress = await notificationPlug.newProgress(d.name, d.id!, d.site);

    dio.download(d.url, filePath,
        cancelToken: _tokens[d.id],
        options: Options(headers: {
          "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
        }),
        deleteOnError: true, onReceiveProgress: ((count, total) {
      if (count == total || !_hasCancelKey(d.id!)) {
        progress.done();
        return;
      }

      progress.setTotal(total);
      progress.update(count);
    })).then((value) async {
      try {
        var settings = isar().settings.getSync(0)!;

        moverPlug.move(MoveOp(
            source: filePath, rootDir: settings.path, targetDir: d.site));

        isar().writeTxnSync(
          () {
            _removeToken(d.id!);
            isar().files.deleteSync(d.id!);
          },
        );
      } catch (e, trace) {
        log("writting downloaded file ${d.name} to uri",
            level: Level.SEVERE.value, error: e, stackTrace: trace);
        isar().writeTxnSync(
          () {
            _removeToken(d.id!);
            isar().files.putSync(d.failed());
          },
        );
      }
    }).onError((DioError error, stackTrace) {
      // print("d: ${error.message}, ${error.response!.data}");
      isar().writeTxnSync(
        () {
          _removeToken(d.id!);
          isar().files.putSync(d.failed());
        },
      );

      progress.error(error.toString());
    }).whenComplete(() => _done());
  }

  void _removeTempContentsDownloads() async {
    try {
      var tempd = await getTemporaryDirectory();
      var downld = Directory(path.join(tempd.path, "downloads"));
      if (!downld.existsSync()) {
        return;
      }

      downld.list().map((event) {
        event.deleteSync(recursive: true);
      }).drain();
    } catch (e, trace) {
      log("deleting temp directories",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }
  }

  Downloader._new(this.maximum, this.moverPlug);

  factory Downloader() {
    if (_global != null) {
      return _global!;
    } else {
      throw "downloader isnt initalized";
    }
  }
}

Future<Downloader> initalizeDownloader() async {
  if (_global != null) {
    return _global!;
  }

  _global = Downloader._new(6, await chooseDownloadMoverPlug());
  _global!._removeTempContentsDownloads();
  return _global!;
}
