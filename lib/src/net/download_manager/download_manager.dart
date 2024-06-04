// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:path/path.dart" as path;

part "download_entry.dart";
part "download_handle.dart";
part "download_status.dart";

class DownloadManager extends MapStorage<String, _DownloadEntry>
    implements ResourceSource<String, _DownloadEntry> {
  DownloadManager(this._db) : super((e) => e.data.url) {
    _refresher = Stream<void>.periodic(1.seconds).listen((event) {
      if (_inWork != 0) {
        StatisticsGeneralService.db()
            .current
            .add(timeDownload: 1.seconds.inMilliseconds)
            .save();
      }
    });
  }

  factory DownloadManager.of(BuildContext context) =>
      DatabaseConnectionNotifier.downloadManagerOf(context);

  int _notificationId = 0;

  int _inWork = 0;
  final _client = Dio();

  final DownloadFileService _db;

  final NotificationPlug notificationPlug = chooseNotificationPlug();

  static const _log = LogTarget.downloader;
  static const int maximum = 6;

  late final StreamSubscription<void> _refresher;

  void restoreFile(DownloadFileData f) {
    map_[f.url] = _DownloadEntry(
      data: DownloadEntry._(
        name: f.name,
        url: f.url,
        thumbUrl: f.thumbUrl,
        site: f.site,
        status: f.status,
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

    _client.close();
  }

  @override
  void clear([bool silent = false]) {
    _db.clear();
    super.clear(silent);
  }

  @override
  List<_DownloadEntry> removeAll(Iterable<String> idx, [bool silent = false]) {
    final idx_ = idx.toList();

    _db.deleteAll(idx_);

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

    _db.saveAll(toSaveDb);
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
      _db.deleteAll([url]);
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

    _db.saveAll([newEntry._toDb()]);

    map_[entry.key] = _DownloadEntry(
      data: newEntry,
      token: CancelToken(),
      watcher: entry.watcher,
    );

    addAll([]);
  }

  Future<void> _download(String url) async {
    final entry = map_[url]!;

    final dir = await GalleryManagementApi.current()
        .ensureDownloadDirectoryExists(entry.data.site);
    final filePath = path.joinAll([dir, entry.data.name]);

    if (await GalleryManagementApi.current().files.exists(filePath)) {
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

    try {
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

    await GalleryManagementApi.current().files.moveSingle(
          source: filePath,
          rootDir: settings.path.path,
          targetDir: entry.data.site,
        );
  }

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
}
