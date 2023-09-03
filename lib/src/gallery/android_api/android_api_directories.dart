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
import 'package:gallery/src/schemas/expensive_hash.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:gallery/src/gallery/android_api/api.g.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../db/platform_channel.dart';
import '../../widgets/search_filter_grid.dart';
import '../interface.dart';

part 'android_api_files.dart';
part 'android_side.dart';

class AndroidGalleryExtra {
  final _AndroidGallery _impl;
  FilterInterface<SystemGalleryDirectory> get filter => _impl.filter;
  void loadThumbs(SystemGalleryDirectory cell) {
    try {
      thumbnailIsar().writeTxnSync(() => thumbnailIsar().thumbnails.putSync(
          Thumbnail(
              cell.thumbFileId, DateTime.now(), kTransparentImage, 0, true)));

      PlatformFunctions.loadThumbnail(cell.thumbFileId);
    } catch (e, trace) {
      log("loading thumbs",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
    _impl.isThumbsLoading = false;
  }

  Isar get db => _impl.db;

  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      trash() {
    final instance = _AndroidGalleryFiles(
      IsarDbsOpen.androidGalleryFiles(),
      () => _impl.currentImages = null,
      isTrash: true,
      bucketId: "trash",
      target: "trash",
    );
    _impl.currentImages = instance;

    return instance;
  }

  GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      favorites() {
    final instance = _AndroidGalleryFiles(
      IsarDbsOpen.androidGalleryFiles(),
      () => _impl.currentImages = null,
      isFavorites: true,
      bucketId: "favorites",
      target: "favorites",
    );
    _impl.currentImages = instance;

    return instance;
  }

  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {
    blacklistedDirIsar().writeTxnSync(
        () => blacklistedDirIsar().blacklistedDirectorys.putAllSync(bucketIds));
    _impl.refreshGrid?.call();
  }

  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
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
  }

  return api;
}

class _AndroidGallery
    implements
        GalleryAPIDirectories<AndroidGalleryExtra, AndroidGalleryFilesExtra,
            SystemGalleryDirectory, SystemGalleryDirectoryFile> {
  final bool? temporary;

  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;

  _AndroidGalleryFiles? currentImages;

  bool isThumbsLoading = false;

  final filter = IsarFilter<SystemGalleryDirectory>(GalleryImpl.instance().db,
      IsarDbsOpen.androidGalleryDirectories(temporary: true),
      (offset, limit, v) {
    return GalleryImpl.instance()
        .db
        .systemGalleryDirectorys
        .filter()
        .nameContains(v, caseSensitive: false)
        .or()
        .tagEqualTo(v)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  Isar get db => GalleryImpl.instance().db;

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
    }
  }

  @override
  SystemGalleryDirectory directCell(int i) =>
      GalleryImpl.instance().db.systemGalleryDirectorys.getSync(i + 1)!;

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
    final instance = _AndroidGalleryFiles(
      IsarDbsOpen.androidGalleryFiles(),
      () => currentImages = null,
      bucketId: d.bucketId,
      target: d.name,
    );

    currentImages = instance;

    return instance;
  }

  _AndroidGallery({this.temporary});
}
