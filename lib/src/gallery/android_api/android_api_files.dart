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

  void loadThumbnails(int thumb) {
    _thumbs(thumb);
  }

  void _thumbs(int from) {
    try {
      final db = _impl.filter.isFiltering ? _impl.filter.to : _impl.db;

      final cell = db.systemGalleryDirectoryFiles.getSync(from + 1)!;

      thumbnailIsar().writeTxnSync(() => thumbnailIsar()
          .thumbnails
          .putSync(Thumbnail(cell.id, DateTime.now(), kTransparentImage, 0)));

      PlatformFunctions.loadThumbnail(cell.id);
      _impl.onThumbUpdate?.call();
    } catch (e, trace) {
      log("loading thumbs",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
    _impl.isThumbsLoading = false;
  }

  void setOnThumbnailCallback(void Function() callback) {
    _impl.onThumbUpdate = callback;
  }

  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
  }

  void setPassFilter(
      (Iterable<SystemGalleryDirectoryFile>, dynamic) Function(
              Iterable<SystemGalleryDirectoryFile> cells,
              dynamic data,
              bool end)
          f) {
    _impl.filter.passFilter = f;
  }

  List<SystemGalleryDirectoryFile> getCellsIds(Set<int> isarIds) {
    return _impl.db.systemGalleryDirectoryFiles
        .where()
        .anyOf(isarIds, (q, element) => q.isarIdEqualTo(element))
        .findAllSync();
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
  final String target;
  bool isThumbsLoading = false;

  @override
  AndroidGalleryFilesExtra getExtra() {
    return AndroidGalleryFilesExtra._(this);
  }

  late final filter = IsarFilter<SystemGalleryDirectoryFile,
          SystemGalleryDirectoryFileShrinked>(db, openAndroidGalleryInnerIsar(),
      (offset, limit, s) {
    if (s.isEmpty) {
      return db.systemGalleryDirectoryFiles
          .where()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }
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

      PlatformFunctions.refreshFiles(bucketId);
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectoryFiles.countSync());
  }

  _AndroidGalleryFiles(
      this.db, this.bucketId, this.unsetCurrentImages, this.target)
      : startTime = DateTime.now().millisecondsSinceEpoch;
}
