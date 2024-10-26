// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io" as io;

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;
import "package:path/path.dart";

part "download_entry.dart";
part "download_handle.dart";
part "download_status.dart";

abstract class DownloadManager
    implements
        MapStorage<String, _DownloadEntry>,
        ResourceSource<String, _DownloadEntry> {
  factory DownloadManager.of(BuildContext context) =>
      DatabaseConnectionNotifier.downloadManagerOf(context);

  Dio get client;
  String get downloadDir;

  void restoreFile(DownloadFileData f);

  void addLocalTags(
    Iterable<DownloadEntryTags> downloads,
    SettingsData settings,
    PostTags postTags,
  );

  void restartAll(Iterable<DownloadHandle> d, SettingsData settings);
  void putAll(Iterable<DownloadEntry> downloads, SettingsData settings);
}

class MemoryOnlyDownloadManager extends MapStorage<String, _DownloadEntry>
    with DefaultDownloadManagerImpl
    implements DownloadManager {
  MemoryOnlyDownloadManager(this.downloadDir) : super((e) => e.data.url);

  @override
  final client = Dio();

  @override
  final String downloadDir;

  @override
  final ClosableRefreshProgress progress =
      ClosableRefreshProgress(canLoadMore: false);

  @override
  SourceStorage<String, _DownloadEntry> get backingStorage => this;

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  bool get hasNext => false;

  @override
  Future<int> next() => Future.value(count);

  @override
  void restoreFile(DownloadFileData f) {}

  @override
  void destroy() {
    super.destroy();
    progress.close();

    client.close();
  }
}

abstract class DownloadManagerHasPersistence {
  DownloadFileService get db;
}

class PersistentDownloadManager extends MapStorage<String, _DownloadEntry>
    with DefaultDownloadManagerImpl
    implements DownloadManager, DownloadManagerHasPersistence {
  PersistentDownloadManager(this.db, this.downloadDir)
      : super((e) => e.data.url) {
    _refresher = Stream<void>.periodic(1.seconds).listen((event) {
      if (_inWork != 0) {
        StatisticsGeneralService.db()
            .current
            .add(timeDownload: 1.seconds.inMilliseconds)
            .save();
      }
    });
  }

  @override
  final client = Dio();

  @override
  final String downloadDir;

  @override
  final DownloadFileService db;

  late final StreamSubscription<void> _refresher;

  @override
  SourceStorage<String, _DownloadEntry> get backingStorage => this;

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  bool get hasNext => false;

  @override
  Future<int> next() => Future.value(count);

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  void restoreFile(DownloadFileData f) {
    map_[f.url] = _DownloadEntry(
      data: DownloadEntry._(
        name: f.name,
        url: f.url,
        thumbUrl: f.thumbUrl,
        site: f.site,
        status: f.status,
        thenMoveTo: null,
      ),
      token: CancelToken(),
    );
  }

  @override
  void add(DownloadHandle e, [bool silent = false]) =>
      throw "should not be called";

  @override
  void addAll(Iterable<DownloadHandle> l, [bool silent = false]) =>
      l.isEmpty ? super.addAll([], silent) : throw "should not be called";

  @override
  void destroy() {
    super.destroy();
    progress.close();
    _refresher.cancel();

    client.close();
  }
}

mixin DefaultDownloadManagerImpl on MapStorage<String, _DownloadEntry>
    implements DownloadManager {
  static final _log = Logger("Download Manager");
  static const int maximum = 6;

  int _notificationId = 0;

  int _inWork = 0;

  @override
  void clear([bool silent = false]) {
    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.clear();
    }
    super.clear(silent);
  }

  @override
  List<_DownloadEntry> removeAll(Iterable<String> idx, [bool silent = false]) {
    final idx_ = idx.toList();

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.deleteAll(idx_);
    }

    final removed = <_DownloadEntry>[];

    for (final key in idx_) {
      final e = map_.remove(key);
      if (e != null) {
        e.cancel();
        e.watcher?.close();
        removed.add(e);
      }
    }

    if (!silent) {
      addAll([]);
    }

    return removed;
  }

  @override
  void addLocalTags(
    Iterable<DownloadEntryTags> downloads,
    SettingsData settings,
    PostTags postTags,
  ) {
    for (final e in downloads) {
      postTags.addTagsPost(e.name, e.tags, true);
    }

    putAll(downloads, settings);
  }

  @override
  void restartAll(Iterable<DownloadHandle> d, SettingsData settings) {
    if (settings.path.isEmpty) {
      return;
    }

    for (final e in d) {
      final ee1 = map_[e.key];
      if (ee1 != null && ee1.data.status != DownloadStatus.inProgress) {
        if (_inWork > maximum) {
          map_[e.key] = _DownloadEntry(
            data: ee1.data._copyStatus(DownloadStatus.onHold),
            token: ee1.token,
            watcher: ee1.watcher,
          );
          continue;
        } else {
          map_[e.key] = _DownloadEntry(
            data: ee1.data._copyStatus(DownloadStatus.inProgress),
            token: ee1.token,
            watcher: ee1.watcher,
          );

          _inWork += 1;

          _download(e.key);
        }
      }
    }

    addAll([]);
  }

  @override
  void putAll(Iterable<DownloadEntry> downloads, SettingsData settings) {
    if (settings.path.isEmpty) {
      return;
    }

    final toDownload = downloads
        .skipWhile(
          (element) => map_.containsKey(element.url),
        )
        .toList();
    if (downloads.isEmpty) {
      return;
    }

    final List<DownloadFileData> toSaveDb = [];

    for (final e in toDownload) {
      if (_inWork > maximum) {
        final hold = e._copyStatus(DownloadStatus.onHold);

        map_[e.url] = _DownloadEntry(data: hold, token: CancelToken());
        toSaveDb.add(hold._toDb());
      } else {
        map_[e.url] = _DownloadEntry(data: e, token: CancelToken());
        toSaveDb.add(e._toDb());

        _inWork += 1;

        _download(e.url);
      }
    }

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.saveAll(toSaveDb);
    }
    addAll([]);
  }

  void _tryAddNew() {
    final newAdd = maximum - _inWork;
    if (newAdd.isNegative || newAdd == 0) {
      return;
    }

    final entries = map_.values
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

    for (final e in entries) {
      map_[e.key] = e;
    }

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence)
          .db
          .saveAll(entries.map((e) => e.data._toDb()).toList());
    }

    for (final e in entries) {
      _download(e.key);
    }
  }

  void _downloadProgress(
    String url,
    NotificationHandle notif, {
    required int count,
    required int total,
  }) {
    if (count == total || !map_.containsKey(url)) {
      notif.done();
      return;
    }

    notif.setTotal(total);
    notif.update(count);
  }

  void _remove(String url) {
    final e = map_.remove(url);
    if (e != null) {
      e.cancel();
      e.watcher?.close();
      if (this is DownloadManagerHasPersistence) {
        (this as DownloadManagerHasPersistence).db.deleteAll([url]);
      }
    }
  }

  void _complete(String url) {
    StatisticsBooruService.db().current.add(downloaded: 1).save();
    _remove(url);
    _inWork -= 1;
    addAll([]);
  }

  void _failed(_DownloadEntry entry) {
    final newEntry = entry.data._copyStatus(DownloadStatus.failed);

    _inWork -= 1;

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.saveAll([newEntry._toDb()]);
    }

    map_[entry.key] = _DownloadEntry(
      data: newEntry,
      token: CancelToken(),
      watcher: entry.watcher,
    );

    addAll([]);
  }

  Future<void> _download(String url) async {
    final entry = map_[url]!;

    final dir =
        await _ensureDownloadDirExists(dir: downloadDir, site: entry.data.site);
    final filePath = path.joinAll([dir, entry.data.name]);

    if (await GalleryApi().files.exists(filePath)) {
      _failed(entry);
      _tryAddNew();
      return;
    }

    final progress = await NotificationApi().show(
      id: _notificationId += 1,
      title: entry.data.name,
      channel: NotificationChannel.downloader,
      group: NotificationGroup.downloader,
      body: entry.data.site,
      payload: "downloads",
    );

    try {
      _log.info("Started download: ${entry.data}");

      await client.download(
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
    } catch (e, trace) {
      _log.warning(
        "writting downloaded file ${entry.data.name} to uri",
        e,
        trace,
      );

      progress.done();
      _failed(entry);
    }

    _tryAddNew();
  }

  Future<void> _moveDownloadedFile(
    _DownloadEntry entry, {
    required String filePath,
  }) async {
    final settings = SettingsService.db().current;

    if (entry.data.thenMoveTo != null) {
      await GalleryApi().files.copyMoveInternal(
        relativePath: entry.data.thenMoveTo!.path,
        volume: entry.data.thenMoveTo!.volume,
        dirName: entry.data.thenMoveTo!.dirName,
        internalPaths: [filePath],
      );
    } else {
      await GalleryApi().files.moveSingle(
            source: filePath,
            rootDir: settings.path.path,
            targetDir: entry.data.site,
          );
    }
  }

  Future<String> _ensureDownloadDirExists({
    required String dir,
    required String site,
  }) async {
    final downloadtd = io.Directory(joinAll([dir, "downloads"]));

    final dirpath = joinAll([downloadtd.path, site]);
    await downloadtd.create();

    await io.Directory(dirpath).create();

    return dirpath;
  }
}
