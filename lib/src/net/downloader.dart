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
import 'package:gallery/src/db/schemas/download_file.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import '../db/initalize_db.dart';

Downloader? _global;

const kDownloadOnHold = "On hold"; // TODO: change
const kDownloadFailed = "Failed"; // TODO: change
const kDownloadInProgress = "In progress"; // TODO: change

mixin _CancelTokens {
  final Map<String, CancelToken> _tokens = {};

  void _addToken(String url, CancelToken t) => _tokens[url] = t;
  void _removeToken(String url) => _tokens.remove(url);
  bool _hasCancelKey(String url) => _tokens[url] != null;

  void cancelAndRemoveToken(String url) {
    final t = _tokens[url];
    if (t == null) {
      return;
    }

    t.cancel();
    _tokens.remove(url);
  }
}

class Downloader with _CancelTokens {
  int _inWork = 0;
  final dio = Dio();
  final int maximum;

  final NotificationPlug notificationPlug = chooseNotificationPlug();
  final DownloadMoverPlug moverPlug;

  void retry(DownloadFile f, Settings settings) {
    if (f.isOnHold()) {
      f.failed().save();
    } else if (_hasCancelKey(f.url)) {
      cancelAndRemoveToken(f.url);
    } else {
      add(f, settings);
    }
  }

  String downloadAction(DownloadFile f) {
    if (f.isOnHold() || _hasCancelKey(f.url)) {
      return "Cancel the download?"; // TODO: change
    } else {
      return "Retry?"; // TODO: change
    }
  }

  String downloadDescription(DownloadFile f) {
    if (_hasCancelKey(f.url)) {
      return kDownloadInProgress;
    }

    if (f.isOnHold()) {
      return kDownloadOnHold;
    }

    return kDownloadFailed;
  }

  void _done() {
    if (_inWork <= maximum) {
      final f = Dbs.g.main.downloadFiles
          .filter()
          .inProgressEqualTo(false)
          .isFailedEqualTo(false)
          .findFirstSync();
      if (f != null) {
        f.inprogress().save();

        _addToken(f.url, CancelToken());
        _download(f);
      } else {
        _inWork--;
      }
    } else {
      _inWork--;
    }
  }

  void restart(Settings settings) async {
    final f = Dbs.g.main.downloadFiles
        .filter()
        .isFailedEqualTo(true)
        .sortByDateDesc()
        .findAllSync();

    if (f.length < 6) {
      f.addAll(Dbs.g.main.downloadFiles
          .where()
          .sortByDateDesc()
          .limit(6 - f.length)
          .findAllSync());
    }

    for (final element in f) {
      add(element, settings);
    }
  }

  void add(DownloadFile download, Settings settings) async {
    if (settings.path == "") {
      download.failed().save();

      return;
    }
    if (download.isarId != null && _hasCancelKey(download.url)) {
      return;
    }

    download.onHold().save();

    if (_inWork <= maximum) {
      _inWork++;
      final d = download.inprogress()..save();

      _addToken(d.url, CancelToken());
      _download(d);
    }
  }

  void removeAll() {
    Dbs.g.main.writeTxnSync(() {
      Dbs.g.main.downloadFiles.clearSync();
    });
  }

  void markStale() {
    final toUpdate = <DownloadFile>[];

    final inProgress =
        Dbs.g.main.downloadFiles.filter().inProgressEqualTo(true).findAllSync();
    for (final element in inProgress) {
      if (_tokens[element.isarId!] == null) {
        toUpdate.add(element.failed());
      }
    }

    if (toUpdate.isEmpty) {
      return;
    }

    Dbs.g.main.writeTxnSync(() {
      Dbs.g.main.downloadFiles.putAllSync(toUpdate);
    });
  }

  void _download(DownloadFile d) async {
    final downloadtd = Directory(
        path.joinAll([(await getTemporaryDirectory()).path, "downloads"]));

    final dirpath = path.joinAll([downloadtd.path, d.site]);
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

    final filePath = path.joinAll([downloadtd.path, d.site, d.name]);
    if (File(filePath).existsSync()) {
      _done();
      return;
    }

    final progress = await notificationPlug.newProgress(
        d.name, d.isarId!, d.site, "Downloader");

    dio.download(d.url, filePath,
        cancelToken: _tokens[d.isarId],
        deleteOnError: true, onReceiveProgress: ((count, total) {
      if (count == total || !_hasCancelKey(d.url)) {
        progress.done();
        return;
      }

      progress.setTotal(total);
      progress.update(count);
    })).then((value) async {
      try {
        final settings = Settings.fromDb();

        moverPlug.move(MoveOp(
            source: filePath, rootDir: settings.path, targetDir: d.site));

        Dbs.g.main.writeTxnSync(
          () {
            _removeToken(d.url);
            Dbs.g.main.downloadFiles.deleteSync(d.isarId!);
          },
        );
      } catch (e, trace) {
        log("writting downloaded file ${d.name} to uri",
            level: Level.SEVERE.value, error: e, stackTrace: trace);
        _removeToken(d.url);
        d.failed().save();
      }
    }).onError((error, stackTrace) {
      _removeToken(d.url);
      d.failed().save();

      progress.error(error.toString());
    }).whenComplete(() => _done());
  }

  void _removeTempContentsDownloads() async {
    try {
      final tempd = await getTemporaryDirectory();
      final downld = Directory(path.join(tempd.path, "downloads"));
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

  static Downloader get g => _global!;
}

Future<Downloader> initalizeDownloader() async {
  if (_global != null) {
    return _global!;
  }

  _global = Downloader._new(6, await chooseDownloadMoverPlug());
  _global!._removeTempContentsDownloads();
  return _global!;
}
