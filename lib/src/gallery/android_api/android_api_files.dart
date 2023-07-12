// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class AndroidGalleryFilesExtra {
  final _AndroidGalleryFiles _impl;

  FilterInterface<SystemGalleryDirectoryFile,
      SystemGalleryDirectoryFileShrinked> get filter => _impl.filter;

  void loadThumbnails(int from) {
    if (_impl.isThumbsLoading) {
      return;
    }

    _impl.isThumbsLoading = true;

    _thumbs(from);
  }

  void _thumbs(int from) async {
    try {
      final db = _impl.filter.isFiltering ? _impl.filter.to : _impl.db;
      var thumbs = db.systemGalleryDirectoryFiles
          .where()
          .offset(from)
          .limit(from == 0 ? 20 : from + 20)
          .findAllSync()
          .map((e) => e.id)
          .toList();
      const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
      await channel.invokeMethod("loadThumbnails", thumbs);
      _impl.onThumbUpdate?.call();
    } catch (e, trace) {
      log("loading thumbs",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
    _impl.isThumbsLoading = false;
  }

  void setOnThumbnailCallback(VoidCallback callback) {
    _impl.onThumbUpdate = callback;
  }

  void setRefreshGridCallback(VoidCallback callback) {
    _impl.refreshGrid = callback;
  }

  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
  }

  const AndroidGalleryFilesExtra._(this._impl);
}

class _AndroidGalleryFiles
    implements
        GalleryAPIFilesRead<AndroidGalleryFilesExtra,
            SystemGalleryDirectoryFile, SystemGalleryDirectoryFileShrinked> {
  Isar db;
  final String bucketId;
  void Function() unsetCurrentImages;

  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;
  void Function()? onThumbUpdate;
  final int startTime;
  bool isThumbsLoading = false;

  @override
  AndroidGalleryFilesExtra getExtra() {
    return AndroidGalleryFilesExtra._(this);
  }

  late final filter = IsarFilter<SystemGalleryDirectoryFile,
          SystemGalleryDirectoryFileShrinked>(db, openAndroidGalleryInnerIsar(),
      (offset, limit, s) {
    return db.systemGalleryDirectoryFiles
        .filter()
        .nameContains(s, caseSensitive: false)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  @override
  void close() {
    filter.dispose();
    db.close(deleteFromDisk: true);
    onThumbUpdate = null;
    callback = null;
    refreshGrid = null;

    unsetCurrentImages();
  }

  @override
  SystemGalleryDirectoryFile directCell(int i) =>
      db.systemGalleryDirectoryFiles.getSync(i + 1)!;

  @override
  Future<int> refresh() {
    try {
      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

      const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
      channel.invokeMethod("refreshFiles", bucketId);
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectoryFiles.countSync());
  }

  _AndroidGalleryFiles(this.db, this.bucketId, this.unsetCurrentImages)
      : startTime = DateTime.now().millisecondsSinceEpoch;
}
