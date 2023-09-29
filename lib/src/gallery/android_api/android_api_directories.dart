// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:gallery/src/gallery/android_api/api.g.dart';
import '../../db/platform_channel.dart';
import '../../widgets/search_filter_grid.dart';
import '../interface.dart';

part 'android_api_files.dart';
part 'android_side.dart';

class AndroidGalleryExtra {
  final _AndroidGallery _impl;
  FilterInterface<SystemGalleryDirectory> get filter => _impl.filter;

  Isar get db => _impl.db;

  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      joinedDir(List<String> directoriesId) {
    final db = IsarDbsOpen.androidGalleryFiles();
    final instance =
        _JoinedDirectories(directoriesId, db, () => _impl.currentImages = null);
    _impl.currentImages = instance;

    return instance;
  }

  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      trash() {
    final db = IsarDbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => _impl.currentImages = null,
        isTrash: true,
        bucketId: "trash",
        target: "trash",
        getElems: defaultGetElemsFiles(db));
    _impl.currentImages = instance;

    return instance;
  }

  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      favorites() {
    final db = IsarDbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => _impl.currentImages = null,
        isFavorites: true,
        bucketId: "favorites",
        target: "favorites",
        getElems: defaultGetElemsFiles(db));
    _impl.currentImages = instance;

    return instance;
  }

  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {
    Dbs.g.blacklisted!.writeTxnSync(
        () => Dbs.g.blacklisted!.blacklistedDirectorys.putAllSync(bucketIds));
    _impl.refreshGrid?.call();
  }

  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
  }

  void setTemporarySet(void Function(int, bool) callback) {
    _impl.temporarySet = callback;
  }

  void setPassFilter(
      (Iterable<SystemGalleryDirectory>, dynamic) Function(
              Iterable<SystemGalleryDirectory>, dynamic, bool)?
          filter) {
    _impl.filter.passFilter = filter;
  }

  const AndroidGalleryExtra._(this._impl);
}

GalleryAPIDirectories<AndroidGalleryExtra, AndroidGalleryFilesExtra,
        SystemGalleryDirectory, SystemGalleryDirectoryFile>
    getAndroidGalleryApi({bool? temporaryDb, bool setCurrentApi = true}) {
  final api = _AndroidGallery(temporary: temporaryDb);
  if (setCurrentApi) {
    _global!._setCurrentApi(api);
  } else {
    _global!._temporaryApis.add(api);
  }

  return api;
}

class _AndroidGallery
    implements
        GalleryAPIDirectories<AndroidGalleryExtra, AndroidGalleryFilesExtra,
            SystemGalleryDirectory, SystemGalleryDirectoryFile> {
  final bool? temporary;
  final time = DateTime.now();

  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;
  void Function(int, bool)? temporarySet;

  _AndroidGalleryFiles? currentImages;

  bool isThumbsLoading = false;

  final filter = IsarFilter<SystemGalleryDirectory>(
      GalleryImpl.g.db, IsarDbsOpen.androidGalleryDirectories(temporary: true),
      (offset, limit, v, _, __) {
    return GalleryImpl.g.db.systemGalleryDirectorys
        .filter()
        .nameContains(v, caseSensitive: false)
        .or()
        .tagEqualTo(v)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  Isar get db => GalleryImpl.g.db;

  @override
  AndroidGalleryExtra getExtra() => AndroidGalleryExtra._(this);

  @override
  void close() {
    filter.dispose();
    refreshGrid = null;
    callback = null;
    currentImages = null;
    if (temporary == false) {
      _global!._unsetCurrentApi();
    } else if (temporary == true) {
      _global!._temporaryApis.removeWhere((element) => element.time == time);
    }
  }

  @override
  SystemGalleryDirectory directCell(int i) =>
      GalleryImpl.g.db.systemGalleryDirectorys.getSync(i + 1)!;

  @override
  Future<int> refresh() {
    try {
      db.writeTxnSync(() => db.systemGalleryDirectorys.clearSync());

      PlatformFunctions.refreshGallery();
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return Future.value(db.systemGalleryDirectorys.countSync());
  }

  @override
  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile> files(
      SystemGalleryDirectory d) {
    final db = IsarDbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => currentImages = null,
        bucketId: d.bucketId,
        target: d.name,
        getElems: defaultGetElemsFiles(db));

    currentImages = instance;

    return instance;
  }

  _AndroidGallery({this.temporary});
}
