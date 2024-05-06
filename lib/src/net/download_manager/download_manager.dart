// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/plugs/download_movers.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";

part "download_entry.dart";
part "download_status.dart";
part "download_handle.dart";

class DownloadManager with _StatisticsTimer {
  DownloadManager(this.moverPlug, this._db);

  int _notificationId = 0;

  int _inWork = 0;
  final _client = Dio();
  final StreamController<void> _events = StreamController();

  final DownloadFileService _db;

  final NotificationPlug notificationPlug = chooseNotificationPlug();
  final DownloadMoverPlug moverPlug;

  final Map<String, _DownloadEntry> _aliveEntries = {};

  static const _log = LogTarget.downloader;
  static const int maximum = 6;

  StreamSubscription<void> watch(void Function(void) f) =>
      _events.stream.listen(f);

  ValueKey<int> get widgetKey => ValueKey(_notificationId);
  Iterable<DownloadHandle> get handles => _aliveEntries.values;

  // String downloadDescription(DownloadFile f) {
  //   if (_hasCancelKey(f.url)) {
  //     return kDownloadInProgress;
  //   }

  //   if (f.isOnHold()) {
  //     return kDownloadOnHold;
  //   }

  //   return kDownloadFailed;
  // }

  // void add(DownloadFile download, SettingsData settings) {
  //   if (settings.path.isEmpty) {
  //     download.failed().save();

  //     return;
  //   }
  //   if ((download.isarId != null && _hasCancelKey(download.url)) ||
  //       DownloadFile.exist(download.url)) {
  //     return;
  //   }

  //   download.onHold().save();

  //   if (_inWork <= maximum) {
  //     _inWork++;
  //     final d = download.inprogress()..save();

  //     _addToken(d.url, CancelToken());
  //     _download(d);
  //   }
  // }

  //  void restartFailed() {
  //   final failed = DownloadFile.allFailed;

  //   addAll(
  //     failed.length < 7
  //         ? failed + DownloadFile.nextNumber(failed.length)
  //         : failed,
  //     SettingsService.currentData,
  //   );
  // }

  // void retry(DownloadFile f, IsarSettings settings) {
  //   if (f.isOnHold()) {
  //     f.failed().save();
  //   } else if (_hasCancelKey(f.url)) {
  //     cancelAndRemoveToken(f.url);
  //   } else {
  //     add(f, settings);
  //   }
  // }

  // void markStale({List<DownloadFile>? override}) {
  //   if (override != null) {
  //     for (final element in override) {
  //       final t = _tokens[element.url];
  //       if (t != null) {
  //         t.cancel();
  //         _tokens.remove(element.url);
  //       }
  //     }

  //     DownloadFile.saveAll(override.map((e) => e.failed()).toList());

  //     return;
  //   }

  //   final toUpdate = <DownloadFile>[];

  //   final inProgress = DownloadFile.inProgressNow;
  //   for (final element in inProgress) {
  //     if (_tokens[element.url] == null) {
  //       toUpdate.add(element.failed());
  //     }
  //   }

  //   if (toUpdate.isEmpty) {
  //     return;
  //   }

  //   DownloadFile.saveAll(toUpdate);
  // }

  void dispose() {
    _client.close();
    _events.close();
  }

  void removeAll() {
    _aliveEntries
      ..values.map((e) {
        e.token.cancel();
        e.watcher?.close();
      })
      ..clear();

    _db.clear();
  }

  void remove(List<DownloadHandle> l) {
    if (l.isEmpty) {
      return;
    }

    final removed = <String>[];

    for (final e in l) {
      e.cancel();
      final r = _aliveEntries.remove(e.key);
      if (r != null) {
        removed.add(r.key);
        r.watcher?.close();
      }
    }

    _db.deleteAll(removed);
  }

  void addAll(Iterable<DownloadEntry> downloads, SettingsData settings) {
    if (settings.path.isEmpty) {
      return;
    }

    final toDownload = downloads
        .skipWhile(
          (element) => _aliveEntries.containsKey(element.url),
        )
        .toList();
    if (downloads.isEmpty) {
      return;
    }

    final List<DownloadFileData> toSaveDb = [];

    for (final e in toDownload) {
      if (_inWork > maximum) {
        final hold = e._copyStatus(DownloadStatus.onHold);

        _aliveEntries[e.url] = _DownloadEntry(data: hold, token: CancelToken());
        toSaveDb.add(hold._toDb());
      } else {
        _aliveEntries[e.url] = _DownloadEntry(data: e, token: CancelToken());
        toSaveDb.add(e._toDb());

        _inWork += 1;

        _download(e.url);
      }
    }

    _db.saveAll(toSaveDb);
  }

  void _tryAddNew() {
    final newAdd = maximum - _inWork;
    if (newAdd.isNegative || newAdd == 0) {
      if (_inWork == 0) {
        _turnOff();
      }

      return;
    }

    final entries = _aliveEntries.values
        .where(
          (element) => element.data.status == DownloadStatus.onHold,
        )
        .take(newAdd)
        .map(
          (e) => _DownloadEntry(
            data: e.data._copyStatus(DownloadStatus.inProgress),
            token: CancelToken(),
            watcher: e.watcher,
          ),
        )
        .toList();

    if (entries.isEmpty) {
      return;
    }

    _inWork += entries.length;

    _aliveEntries.addEntries(
      entries.map(
        (e) => MapEntry(
          e.key,
          e,
        ),
      ),
    );
    _db.saveAll(entries.map((e) => e.data._toDb()).toList());

    for (final e in entries) {
      _download(e.key);
    }
  }

  void _downloadProgress(
    String url,
    NotificationProgress notif, {
    required int count,
    required int total,
  }) {
    if (count == total || !_aliveEntries.containsKey(url)) {
      notif.done();
      return;
    }

    notif.setTotal(total);
    notif.update(count);
  }

  void _remove(String url) {
    _aliveEntries.remove(url)?.watcher?.close();
    _db.deleteAll([url]);
  }

  void _complete(String url) {
    _remove(url);
    _events.add(null);
  }

  void _failed(_DownloadEntry entry) {
    final newEntry = entry.data._copyStatus(DownloadStatus.failed);

    _aliveEntries[entry.key] = _DownloadEntry(
      data: newEntry,
      token: CancelToken(),
      watcher: entry.watcher,
    );
    _db.saveAll([newEntry._toDb()]);

    _events.add(null);
  }

  Future<void> _download(String url) async {
    final entry = _aliveEntries[url]!;

    try {
      final dir = await _tryCreateInternalDownloadDir(entry);
      final filePath = path.joinAll([dir.path, entry.data.name]);

      if (await _fileExists(filePath)) {
        _failed(entry);
        _tryAddNew();
        return;
      }

      final progress = await notificationPlug.newProgress(
        entry.data.name,
        _notificationId += 1,
        entry.data.site,
        "Downloader",
      );

      _start();

      _log.logDefault("Started download: ${entry.data}".message);

      await _client.download(
        entry.data.url,
        filePath,
        cancelToken: entry.token,
        onReceiveProgress: (count, total) => _downloadProgress(
          url,
          progress,
          count: count,
          total: total,
        ),
      );

      await _moveDownloadedFile(
        entry,
        filePath: filePath,
      );

      _complete(entry.key);
      progress.done();
    } catch (e, stackTrace) {
      _log.logDefaultImportant(
        "writting downloaded file ${entry.data.name} to uri".errorMessage(e),
        stackTrace,
      );

      _failed(entry);
    }

    _tryAddNew();
  }

  Future<Directory> _tryCreateInternalDownloadDir(_DownloadEntry entry) async {
    final downloadtd = Directory(
      path.joinAll([(await getTemporaryDirectory()).path, "downloads"]),
    );

    final dirpath = path.joinAll([downloadtd.path, entry.data.site]);
    try {
      await downloadtd.create();

      return Directory(dirpath).create();
    } catch (e, trace) {
      _log.logDefaultImportant(
        "while creating directory $dirpath".errorMessage(e),
        trace,
      );

      rethrow;
    }
  }

  Future<bool> _fileExists(String filePath) => File(filePath).exists();

  Future<void> _moveDownloadedFile(
    _DownloadEntry entry, {
    required String filePath,
  }) async {
    final settings = SettingsService.currentData;

    await moverPlug.move(
      MoveOp(
        source: filePath,
        rootDir: settings.path.path,
        targetDir: entry.data.site,
      ),
    );
  }

  // Future<void> _removeTempContentsDownloads() async {
  //   try {
  //     final tempd = await getTemporaryDirectory();
  //     final downld = Directory(path.join(tempd.path, "downloads"));
  //     if (!downld.existsSync()) {
  //       return;
  //     }

  //     downld.list().map((event) {
  //       event.deleteSync(recursive: true);
  //     }).drain<void>();
  //   } catch (e, trace) {
  //     _log.logDefaultImportant(
  //       "deleting temp directories".errorMessage(e),
  //       trace,
  //     );
  //   }
  // }
}
