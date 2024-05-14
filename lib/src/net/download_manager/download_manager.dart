// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:path/path.dart" as path;

part "download_entry.dart";
part "download_status.dart";
part "download_handle.dart";

mixin _SourceImpl on SourceStorage<DownloadHandle>
    implements ResourceSource<DownloadHandle> {
  @override
  SourceStorage<DownloadHandle> get backingStorage => this;

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  void destroy() {}

  @override
  DownloadHandle? forIdx(int idx) => get(idx);

  @override
  DownloadHandle forIdxUnsafe(int idx) => this[idx];

  @override
  Future<int> next() => Future.value(count);
}

class DownloadManager extends SourceStorage<DownloadHandle>
    with _StatisticsTimer, _SourceImpl {
  DownloadManager(this._db);

  factory DownloadManager.of(BuildContext context) =>
      DatabaseConnectionNotifier.downloadManagerOf(context);

  int _notificationId = 0;

  int _inWork = 0;
  final _client = Dio();
  final StreamController<int> _events = StreamController.broadcast();

  @override
  RefreshingProgress get progress => const RefreshingProgress.empty();

  final DownloadFileService _db;

  final NotificationPlug notificationPlug = chooseNotificationPlug();

  final Map<String, int> _entriesMap = {};
  final List<_DownloadEntry> _aliveEntries = [];

  static const _log = LogTarget.downloader;
  static const int maximum = 6;

  // ValueKey<int> get widgetKey => ValueKey(_notificationId);
  // Iterable<DownloadHandle> get handles => _aliveEntries.values;

  @override
  int get count => _aliveEntries.length;

  @override
  DownloadHandle? get(int idx) =>
      idx >= _aliveEntries.length ? null : _aliveEntries[0];

  @override
  Iterator<DownloadHandle> get iterator => _aliveEntries.iterator;

  @override
  DownloadHandle operator [](int index) => _aliveEntries[0];

  @override
  void operator []=(int index, DownloadHandle value) {
    if (value is _DownloadEntry) {
      _aliveEntries[index] = value;

      _events.add(count);
    }
  }

  @override
  bool get hasNext => false;

  @override
  Iterable<DownloadHandle> get reversed => _aliveEntries.reversed;

  @override
  void add(DownloadHandle e, [bool silent = false]) =>
      throw "should not be called";

  @override
  void addAll(List<DownloadHandle> l, [bool silent = false]) =>
      throw "should not be called";

  @override
  void removeAll(List<int> idx) => throw "should not be called";

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

  @override
  void clear() {
    _aliveEntries
      ..map((e) {
        e.token.cancel();
        e.watcher?.close();
      })
      ..clear();
    _entriesMap.clear();

    _db.clear();
    _events.add(count);
  }

  void remove(List<DownloadHandle> l) {
    if (l.isEmpty) {
      return;
    }

    final removed = <String>[];

    for (final e in l) {
      e.cancel();
      final id = _entriesMap.remove(e.key);
      if (id != null) {
        final r = _aliveEntries.removeAt(id);
        removed.add(r.key);
        r.watcher?.close();
      }
    }

    _db.deleteAll(removed);
    _events.add(count);
  }

  void addLocalTags(
    Iterable<DownloadEntryTags> downloads,
    SettingsData settings,
    PostTags postTags,
  ) {}

  void putAll(Iterable<DownloadEntry> downloads, SettingsData settings) {
    if (settings.path.isEmpty) {
      return;
    }

    final toDownload = downloads
        .skipWhile(
          (element) => _entriesMap.containsKey(element.url),
        )
        .toList();
    if (downloads.isEmpty) {
      return;
    }

    final List<DownloadFileData> toSaveDb = [];

    for (final e in toDownload) {
      if (_inWork > maximum) {
        final hold = e._copyStatus(DownloadStatus.onHold);

        _aliveEntries.add(_DownloadEntry(data: hold, token: CancelToken()));
        _entriesMap[e.url] = _aliveEntries.length - 1;
        toSaveDb.add(hold._toDb());
      } else {
        _aliveEntries.add(_DownloadEntry(data: e, token: CancelToken()));
        _entriesMap[e.url] = _aliveEntries.length - 1;
        toSaveDb.add(e._toDb());

        _inWork += 1;

        _download(e.url);
      }
    }

    _db.saveAll(toSaveDb);
    // _events.add(null);
  }

  void _tryAddNew() {
    final newAdd = maximum - _inWork;
    if (newAdd.isNegative || newAdd == 0) {
      if (_inWork == 0) {
        _turnOff();
      }

      return;
    }

    final entries = _aliveEntries.indexed
        .where(
          (element) => element.$2.data.status == DownloadStatus.onHold,
        )
        .take(newAdd)
        .map(
          (e) => (
            e.$1,
            _DownloadEntry(
              data: e.$2.data._copyStatus(DownloadStatus.inProgress),
              token: CancelToken(),
              watcher: e.$2.watcher,
            )
          ),
        )
        .toList();

    if (entries.isEmpty) {
      return;
    }

    _inWork += entries.length;

    for (final (id, e) in entries) {
      _aliveEntries[id] = e;
    }

    _db.saveAll(entries.map((e) => e.$2.data._toDb()).toList());

    for (final e in entries) {
      _download(e.$2.key);
    }
  }

  void _downloadProgress(
    String url,
    NotificationProgress notif, {
    required int count,
    required int total,
  }) {
    if (count == total || !_entriesMap.containsKey(url)) {
      notif.done();
      return;
    }

    notif.setTotal(total);
    notif.update(count);
  }

  void _remove(String url) {
    final id = _entriesMap.remove(url);
    if (id != null) {
      _aliveEntries.removeAt(id).watcher?.close();
      _db.deleteAll([url]);
    }
  }

  void _complete(String url) {
    _remove(url);
    _events.add(count);
  }

  void _failed(_DownloadEntry entry) {
    final newEntry = entry.data._copyStatus(DownloadStatus.failed);

    _aliveEntries[_entriesMap[entry.key]!] = _DownloadEntry(
      data: newEntry,
      token: CancelToken(),
      watcher: entry.watcher,
    );
    _db.saveAll([newEntry._toDb()]);

    _events.add(count);
  }

  Future<void> _download(String url) async {
    final entry = _aliveEntries[_entriesMap[url]!];

    try {
      final dir = await GalleryManagementApi.current()
          .ensureDownloadDirectoryExists(entry.data.site);
      final filePath = path.joinAll([dir, entry.data.name]);

      if (await GalleryManagementApi.current().fileExists(filePath)) {
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

  Future<void> _moveDownloadedFile(
    _DownloadEntry entry, {
    required String filePath,
  }) async {
    final settings = SettingsService.db().current;

    await GalleryManagementApi.current().move(
      MoveOp(
        source: filePath,
        rootDir: settings.path.path,
        targetDir: entry.data.site,
      ),
    );
  }

  @override
  StreamSubscription<int> watch(void Function(int) f) =>
      _events.stream.listen(f);

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
