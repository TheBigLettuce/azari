// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class AndroidGalleryFilesExtra {
  final _AndroidGalleryFiles _impl;

  FilterInterface<SystemGalleryDirectoryFile> get filter => _impl.filter;

  void loadThumbnails(int thumb) {
    _thumbs(thumb);
  }

  void _thumbs(int from) {
    try {
      final db = _impl.filter.isFiltering ? _impl.filter.to : _impl.db;

      final cell = db.systemGalleryDirectoryFiles.getSync(from + 1);
      if (cell == null) {
        return;
      }

      thumbnailIsar().writeTxnSync(() => thumbnailIsar().thumbnails.putSync(
          Thumbnail(cell.id, DateTime.now(), kTransparentImage, 0, true)));

      PlatformFunctions.loadThumbnail(cell.id);
      _impl.onThumbUpdate?.call();
    } catch (e, trace) {
      log("loading thumbs",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
    _impl.isThumbsLoading = false;
  }

  bool isTrash() => _impl.isTrash;

  void setOnThumbnailCallback(void Function() callback) {
    _impl.onThumbUpdate = callback;
  }

  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  void loadNextThumbnails(void Function() callback) async {
    var offset = 0;
    var count = 0;
    List<Future<ThumbnailId>> thumbnails = [];

    for (;;) {
      final elems = _impl.db.systemGalleryDirectoryFiles
          .where()
          .offset(offset)
          .limit(40)
          .findAllSync();
      offset += elems.length;

      if (elems.isEmpty) {
        break;
      }

      for (final file in elems) {
        if (file.getThumbnail() == null) {
          count++;

          thumbnails.add(PlatformFunctions.getThumbDirectly(file.id));

          if (thumbnails.length > 8) {
            GalleryImpl.instance().addThumbnails(await thumbnails.wait, false);
            thumbnails.clear();
          }
        }
      }

      if (count >= 80) {
        break;
      }
    }

    if (thumbnails.isNotEmpty) {
      GalleryImpl.instance().addThumbnails(await thumbnails.wait, false);
    }

    callback();
  }

  bool get supportsDirectRefresh => false;

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
            SystemGalleryDirectoryFile> {
  Isar db;
  final String bucketId;
  void Function() unsetCurrentImages;

  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;
  void Function()? onThumbUpdate;
  final int startTime;
  final String target;
  bool isThumbsLoading = false;
  final bool isTrash;

  @override
  AndroidGalleryFilesExtra getExtra() {
    return AndroidGalleryFilesExtra._(this);
  }

  late final IsarFilter<SystemGalleryDirectoryFile> filter =
      IsarFilter<SystemGalleryDirectoryFile>(db, openAndroidGalleryInnerIsar(),
          (offset, limit, s) {
    if (filter.currentSorting == SortingMode.size) {
      return db.systemGalleryDirectoryFiles
          .filter()
          .nameContains(s, caseSensitive: false)
          .sortBySizeDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

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

      if (isTrash) {
        PlatformFunctions.refreshTrashed();
      } else {
        PlatformFunctions.refreshFiles(bucketId);
      }
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectoryFiles.countSync());
  }

  _AndroidGalleryFiles(
      this.db, this.bucketId, this.unsetCurrentImages, this.target,
      {this.isTrash = false})
      : startTime = DateTime.now().millisecondsSinceEpoch;
}
