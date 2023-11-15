// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class _GalleryFilesExtra implements GalleryFilesExtra {
  final _AndroidGalleryFiles _impl;

  @override
  Isar get db => _impl.db;

  @override
  FilterInterface<SystemGalleryDirectoryFile> get filter => _impl.filter;

  @override
  bool get supportsDirectRefresh => false;

  @override
  bool get isTrash => _impl.isTrash;
  @override
  bool get isFavorites => _impl.isFavorites;

  @override
  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  @override
  Future<void> loadNextThumbnails(void Function() callback) async {
    var offset = 0;
    var count = 0;
    List<Future<ThumbId>> thumbnails = [];

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

          thumbnails.add(PlatformFunctions.getCachedThumb(file.id));

          if (thumbnails.length > 8) {
            ThumbId.addThumbnailsToDb(await thumbnails.wait);
            thumbnails.clear();
          }
        }
      }

      if (count >= 80) {
        break;
      }
    }

    if (thumbnails.isNotEmpty) {
      ThumbId.addThumbnailsToDb(await thumbnails.wait);
    }

    callback();
  }

  @override
  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
  }

  @override
  void setPassFilter(
      (Iterable<SystemGalleryDirectoryFile>, dynamic) Function(
              Iterable<SystemGalleryDirectoryFile> cells,
              dynamic data,
              bool end)
          f) {
    _impl.filter.passFilter = f;
  }

  List<SystemGalleryDirectoryFile> getCellsIds(Set<int> isarIds) =>
      _impl.db.systemGalleryDirectoryFiles
          .where()
          .anyOf(isarIds, (q, element) => q.isarIdEqualTo(element))
          .findAllSync();

  const _GalleryFilesExtra._(this._impl);
}

class _JoinedDirectories extends _AndroidGalleryFiles {
  final List<String> directories;

  @override
  bool isBucketId(String dirId) {
    for (final d in directories) {
      if (d == dirId) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<int> refresh() async {
    try {
      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

      if (isTrash) {
        PlatformFunctions.refreshTrashed();
      } else if (isFavorites) {
        int offset = 0;

        while (true) {
          final f = Dbs.g.blacklisted.favoriteMedias
              .where()
              .offset(offset)
              .limit(200)
              .findAllSync()
              .map((e) => e.id)
              .toList();
          offset += f.length;

          if (f.isEmpty) {
            break;
          }

          await PlatformFunctions.refreshFavorites(f);
        }
      } else {
        PlatformFunctions.refreshFilesMultiple(directories);
      }
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectoryFiles.countSync());
  }

  _JoinedDirectories(this.directories, super.db, super.unsetCurrentImages)
      : super(
            bucketId: "",
            isTrash: false,
            isFavorites: false,
            target: "joinedDir",
            getElems: lastMofifiedGetElemsFiles(db));
}

class _AndroidGalleryFiles implements GalleryAPIFiles {
  final bool isTrash;
  final bool isFavorites;
  final String _bucketId;
  final int startTime;
  final String target;

  final Isar db;

  void Function() unsetCurrentImages;
  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;

  bool isThumbsLoading = false;

  bool isBucketId(String bucketId) => _bucketId == bucketId;

  @override
  GalleryFilesExtra getExtra() => _GalleryFilesExtra._(this);

  @override
  SystemGalleryDirectoryFile directCell(int i) =>
      db.systemGalleryDirectoryFiles.getSync(i + 1)!;

  final IsarFilter<SystemGalleryDirectoryFile> filter;

  @override
  void close() {
    filter.dispose();
    db.close(deleteFromDisk: true);
    callback = null;
    refreshGrid = null;

    unsetCurrentImages();
  }

  @override
  Future<int> refresh() async {
    try {
      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

      if (isTrash) {
        PlatformFunctions.refreshTrashed();
      } else if (isFavorites) {
        int offset = 0;

        while (true) {
          final f = Dbs.g.blacklisted.favoriteMedias
              .where()
              .offset(offset)
              .limit(200)
              .findAllSync()
              .map((e) => e.id)
              .toList();
          offset += f.length;

          if (f.isEmpty) {
            break;
          }

          await PlatformFunctions.refreshFavorites(f);
        }
      } else {
        PlatformFunctions.refreshFiles(_bucketId);
      }
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectoryFiles.countSync());
  }

  _AndroidGalleryFiles(
    this.db,
    this.unsetCurrentImages, {
    required Iterable<SystemGalleryDirectoryFile> Function(
            int, int, String, SortingMode, FilteringMode)
        getElems,
    required this.target,
    required String bucketId,
    this.isTrash = false,
    this.isFavorites = false,
  })  : startTime = DateTime.now().millisecondsSinceEpoch,
        _bucketId = bucketId,
        filter = IsarFilter<SystemGalleryDirectoryFile>(
            db,
            DbsOpen.androidGalleryFiles(),
            isFavorites ? lastMofifiedGetElemsFiles(db) : getElems);
}

Iterable<SystemGalleryDirectoryFile> Function(
        int, int, String, SortingMode, FilteringMode)
    lastMofifiedGetElemsFiles(Isar db) {
  return (offset, limit, s, sort, mode) {
    if (sort == SortingMode.size) {
      return db.systemGalleryDirectoryFiles
          .filter()
          .nameContains(s, caseSensitive: false)
          .sortBySizeDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

    // if (mode == FilteringMode.same) {
    //   return db.systemGalleryDirectoryFiles
    //       .where()
    //       .offset(offset)
    //       .limit(limit)
    //       .findAllSync();
    // }

    if (s.isEmpty) {
      return db.systemGalleryDirectoryFiles
          .where()
          .sortByLastModifiedDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

    return db.systemGalleryDirectoryFiles
        .filter()
        .nameContains(s, caseSensitive: false)
        .sortByLastModifiedDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  };
}

Iterable<SystemGalleryDirectoryFile> Function(
        int, int, String, SortingMode, FilteringMode)
    defaultGetElemsFiles(Isar db) {
  return (offset, limit, s, sort, _) {
    if (sort == SortingMode.size) {
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
  };
}
