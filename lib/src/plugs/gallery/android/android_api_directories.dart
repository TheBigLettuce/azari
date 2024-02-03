// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:gallery/src/db/schemas/gallery/thumbnail.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/gallery/note_gallery.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_booru_post.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_directories.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_files.dart';
import 'package:gallery/src/interfaces/gallery/gallery_files_extra.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/more/settings/network_status.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:gallery/src/plugs/gallery/android/api.g.dart';
import '../../../db/isar_filter.dart';
import '../../../interfaces/filtering/filtering_interface.dart';
import '../../../interfaces/filtering/filtering_mode.dart';
import '../../../interfaces/filtering/sorting_mode.dart';
import '../../platform_functions.dart';
import '../../gallery.dart';
import '../../../interfaces/gallery/gallery_directories_extra.dart';

part 'android_api_files.dart';
part 'gallery_impl.dart';
part 'android_gallery.dart';

class _GalleryExtra implements GalleryDirectoriesExtra {
  final _AndroidGallery _impl;

  @override
  FilterInterface<SystemGalleryDirectory> get filter => _impl.filter;

  @override
  Isar get db => _impl.db;

  @override
  GalleryAPIFiles joinedDir(List<String> directoriesId) {
    final db = DbsOpen.androidGalleryFiles();

    final instance =
        _JoinedDirectories(directoriesId, db, () => _impl.currentImages = null);
    _impl.currentImages = instance;

    return instance;
  }

  @override
  GalleryAPIFiles trash() {
    final db = DbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => _impl.currentImages = null,
        isTrash: true,
        bucketId: "trash",
        target: "trash",
        getElems: defaultGetElemsFiles(db));
    _impl.currentImages = instance;

    return instance;
  }

  @override
  GalleryAPIFiles favorites() {
    final db = DbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => _impl.currentImages = null,
        isFavorites: true,
        bucketId: "favorites",
        target: "favorites",
        getElems: defaultGetElemsFiles(db));
    _impl.currentImages = instance;

    return instance;
  }

  @override
  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {
    Dbs.g.blacklisted.writeTxnSync(
        () => Dbs.g.blacklisted.blacklistedDirectorys.putAllSync(bucketIds));
    _impl.refreshGrid?.call();
  }

  @override
  void setRefreshGridCallback(void Function() callback) {
    _impl.refreshGrid = callback;
  }

  @override
  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    _impl.callback = callback;
  }

  @override
  void setTemporarySet(void Function(int, bool) callback) {
    _impl.temporarySet = callback;
  }

  @override
  void setPassFilter(
      (Iterable<SystemGalleryDirectory>, dynamic) Function(
              Iterable<SystemGalleryDirectory>, dynamic, bool)?
          filter) {
    _impl.filter.passFilter = filter;
  }

  const _GalleryExtra._(this._impl);
}

class _AndroidGallery implements GalleryAPIDirectories {
  final bool? temporary;
  final time = DateTime.now();

  void Function(int i, bool inRefresh, bool empty)? callback;
  void Function()? refreshGrid;
  void Function(int, bool)? temporarySet;

  _AndroidGalleryFiles? currentImages;

  bool isThumbsLoading = false;

  final filter = IsarFilter<SystemGalleryDirectory>(
      _global!.db, DbsOpen.androidGalleryDirectories(temporary: true),
      (offset, limit, v, _, __) {
    return _global!.db.systemGalleryDirectorys
        .filter()
        .nameContains(v, caseSensitive: false)
        .or()
        .tagContains(v, caseSensitive: false)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  Isar get db => _global!.db;

  @override
  GalleryDirectoriesExtra getExtra() => _GalleryExtra._(this);

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
      _global!.db.systemGalleryDirectorys.getSync(i + 1)!;

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
  GalleryAPIFiles files(SystemGalleryDirectory d) {
    final db = DbsOpen.androidGalleryFiles();
    final instance = _AndroidGalleryFiles(db, () => currentImages = null,
        bucketId: d.bucketId,
        target: d.name,
        getElems: defaultGetElemsFiles(db));

    currentImages = instance;

    return instance;
  }

  _AndroidGallery({this.temporary});
}
