// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Downloader? _global;

const kDownloadOnHold = "On hold"; // TODO: change
const kDownloadFailed = "Failed"; // TODO: change
const kDownloadInProgress = "In progress"; // TODO: change

mixin _StatisticsTimer {
  StreamSubscription? _refresher;

  void _start() {
    _refresher ??= Stream.periodic(1.seconds).listen((event) {
      StatisticsGeneral.addTimeDownload(1.seconds.inMilliseconds);
    });
  }

  void _turnOff() {
    _refresher?.cancel();
    _refresher = null;
  }
}

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

class Downloader with _CancelTokens, _StatisticsTimer {
  static const _log = LogTarget.downloader;

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
      final f = DownloadFile.next();

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

    if (_inWork == 0) {
      _turnOff();
    }
  }

  void remove(List<DownloadFile> l) {
    if (l.isEmpty) {
      return;
    }

    for (final e in l) {
      if (_hasCancelKey(e.url)) {
        _tokens[e.url]?.cancel();
        _removeToken(e.url);
      }
    }

    DownloadFile.deleteAll(l.map((e) => e.url).toList());
  }

  void add(DownloadFile download, Settings settings) {
    if (settings.path.isEmpty) {
      download.failed().save();

      return;
    }
    if ((download.isarId != null && _hasCancelKey(download.url)) ||
        DownloadFile.exist(download.url)) {
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

  void addAll(Iterable<DownloadFile> downloads, Settings settings) {
    if (settings.path.isEmpty) {
      return;
    }

    final toDownload = downloads
        .where((element) =>
            element.isarId == null ||
            !_hasCancelKey(element.url) ||
            DownloadFile.notExist(element.url))
        .map((e) => e.onHold())
        .toList();

    if (downloads.isEmpty) {
      return;
    }

    DownloadFile.saveAll(toDownload);

    List<DownloadFile> toSave = [];

    for (final e in toDownload) {
      if (_inWork >= maximum) {
        break;
      }

      _inWork += 1;
      final d = e.inprogress();
      toSave.add(e);

      _addToken(d.url, CancelToken());
      _download(d);
    }

    DownloadFile.saveAll(toSave);
  }

  void removeAll() {
    DownloadFile.clear();

    for (final element in _tokens.values) {
      element.cancel();
    }
    _tokens.clear();
  }

  void markStale({List<DownloadFile>? override}) {
    if (override != null) {
      for (final element in override) {
        final t = _tokens[element.url];
        if (t != null) {
          t.cancel();
          _tokens.remove(element.url);
        }
      }

      DownloadFile.saveAll(override.map((e) => e.failed()).toList());

      return;
    }

    final toUpdate = <DownloadFile>[];

    final inProgress = DownloadFile.inProgressNow;
    for (final element in inProgress) {
      if (_tokens[element.url] == null) {
        toUpdate.add(element.failed());
      }
    }

    if (toUpdate.isEmpty) {
      return;
    }

    DownloadFile.saveAll(toUpdate);
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
      _log.logDefaultImportant(
          "while creating directory $dirpath".errorMessage(e), trace);

      return;
    }

    final filePath = path.joinAll([downloadtd.path, d.site, d.name]);
    if (File(filePath).existsSync()) {
      _done();
      return;
    }

    final progress = await notificationPlug.newProgress(
        d.name, d.isarId!, d.site, "Downloader");

    _start();

    _log.logDefault("Started download: $d".message);

    dio.download(d.url, filePath,
        cancelToken: _tokens[d.url],
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
            source: filePath, rootDir: settings.path.path, targetDir: d.site));

        DownloadFile.deleteAll([d.url]);
        _removeToken(d.url);

        StatisticsBooru.addDownloaded();
      } catch (e, trace) {
        _log.logDefaultImportant(
            "writting downloaded file ${d.name} to uri".errorMessage(e), trace);
        _removeToken(d.url);
        d.failed().save();
      }
    }).onError((error, stackTrace) {
      if (_hasCancelKey(d.url)) {
        _removeToken(d.url);
        d.failed().save();
      }

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
      _log.logDefaultImportant(
          "deleting temp directories".errorMessage(e), trace);
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
