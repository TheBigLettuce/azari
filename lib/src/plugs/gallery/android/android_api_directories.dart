// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/pages/more/settings/network_status.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery/android/api.g.dart";
import "package:gallery/src/plugs/platform_functions.dart";

part "android_api_files.dart";
part "android_gallery.dart";
part "gallery_impl.dart";

class _AndroidGallery implements GalleryAPIDirectories {
  _AndroidGallery(
    this.blacklistedDirectory,
    this.directoryTag, {
    required this.temporary,
  });

  final BlacklistedDirectoryService blacklistedDirectory;
  final DirectoryTagService directoryTag;

  final bool temporary;
  final time = DateTime.now();

  bool isThumbsLoading = false;

  @override
  _AndroidGalleryFiles? bindFiles;

  @override
  void close() {
    source.destroy();
    bindFiles = null;
    if (temporary == false) {
      _global!._unsetCurrentApi();
    } else if (temporary) {
      // _global!._temporaryApis.removeWhere((element) => element.time == time);
    }
  }

  @override
  GalleryAPIFiles files(GalleryDirectory d, GalleryFilesPageType type) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _AndroidGalleryFiles(
      source: _AndroidFileSource(d.bucketId),
      bucketId: d.bucketId,
      target: d.name,
      type: type,
      parent: this,
    );
  }

  @override
  GalleryAPIFiles joinedFiles(List<String> bucketIds) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _JoinedDirectories(
      source: _AndroidFileSourceJoined(bucketIds),
      directories: bucketIds,
      parent: this,
    );
  }

  @override
  final ResourceSource<GalleryDirectory> source = _AndroidSource();
}

class _AndroidSource implements ResourceSource<GalleryDirectory> {
  _AndroidSource();

  @override
  final SourceStorage<GalleryDirectory> backingStorage = ListStorage();

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  Future<int> next() => Future.value(count);

  @override
  int get count => backingStorage.count;

  @override
  void destroy() {
    backingStorage.destroy();
  }

  @override
  GalleryDirectory? forIdx(int idx) => backingStorage.get(idx);

  @override
  GalleryDirectory forIdxUnsafe(int idx) => backingStorage[idx];
}

  // final filter = IsarFilter<SystemGalleryDirectory>(
  //     _global!.db, DbsOpen.androidGalleryDirectories(),
  //     (offset, limit, v, _, __) {
  //   return _global!.db.systemGalleryDirectorys
  //       .filter()
  //       .nameContains(v, caseSensitive: false)
  //       .or()
  //       .tagContains(v, caseSensitive: false)
  //       .offset(offset)
  //       .limit(limit)
  //       .findAllSync();
  // });

  // @override
  // StreamSubscription<int> watch(void Function(int c) f) {
  //   // TODO: implement watch
  //   throw UnimplementedError();
  // }

  // @override
  // SystemGalleryDirectory directCell(int i) => filter.isFiltering
  //     ? filter.to.systemGalleryDirectorys.getSync(i + 1)!
  //     : _global!.db.systemGalleryDirectorys.getSync(i + 1)!;

  // @override
  // Future<int> refresh() {
  //   try {
  //     db.writeTxnSync(() => db.systemGalleryDirectorys.clearSync());

  //     PlatformFunctions.refreshGallery();
  //   } catch (e, trace) {
  //     log(
  //       "android gallery",
  //       level: Level.SEVERE.value,
  //       error: e,
  //       stackTrace: trace,
  //     );
  //   }

  //   return Future.value(db.systemGalleryDirectorys.countSync());
  // }

// class _GalleryExtra implements GalleryDirectoriesExtra {
//   const _GalleryExtra._(this._impl);
//   final _AndroidGallery _impl;

//   @override
//   FilterInterface<SystemGalleryDirectory> get filter => _impl.filter;

//   @override
//   Isar get db => _impl.db;

//   @override
//   bool get currentlyHostingFiles => _impl.currentImages != null;

//   @override
//   GalleryAPIFiles joinedDir(List<String> directoriesId) {
//     final db = DbsOpen.androidGalleryFiles();

//     final instance =
//         _JoinedDirectories(directoriesId, db, () => _impl.currentImages = null);
//     _impl.currentImages = instance;

//     return instance;
//   }

//   @override
//   GalleryAPIFiles trash() {
//     final db = DbsOpen.androidGalleryFiles();
//     final instance = _AndroidGalleryFiles(
//       db,
//       () => _impl.currentImages = null,
//       isTrash: true,
//       bucketId: "trash",
//       target: "trash",
//       getElems: defaultGetElemsFiles(db),
//     );
//     _impl.currentImages = instance;

//     return instance;
//   }

//   @override
//   GalleryAPIFiles favorites() {
//     final db = DbsOpen.androidGalleryFiles();
//     final instance = _AndroidGalleryFiles(
//       db,
//       () => _impl.currentImages = null,
//       isFavorites: true,
//       bucketId: "favorites",
//       target: "favorites",
//       getElems: defaultGetElemsFiles(db),
//     );
//     _impl.currentImages = instance;

//     return instance;
//   }

//   @override
//   void addBlacklisted(List<BlacklistedDirectory> bucketIds) {
//     Dbs.g.blacklisted.writeTxnSync(
//       () => Dbs.g.blacklisted.blacklistedDirectorys.putAllSync(bucketIds),
//     );
//     _impl.refreshGrid?.call();
//   }

//   @override
//   void setRefreshGridCallback(void Function() callback) {
//     _impl.refreshGrid = callback;
//   }

//   @override
//   void setRefreshingStatusCallback(
//     void Function(int i, bool inRefresh, bool empty) callback,
//   ) {
//     _impl.callback = callback;
//   }

//   @override
//   void setTemporarySet(void Function(int, bool) callback) {
//     _impl.temporarySet = callback;
//   }

//   @override
//   void setPassFilter(
//     (Iterable<SystemGalleryDirectory>, dynamic) Function(
//       Iterable<SystemGalleryDirectory>,
//       dynamic,
//       bool,
//     )? filter,
//   ) {
//     _impl.filter.passFilter = filter;
//   }
// }