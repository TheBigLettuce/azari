// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class GalleryImpl implements GalleryApi {
  final Isar db;

  @override
  void finish(String version) {
    db.writeTxnSync(
        () => db.galleryLastModifieds.putSync(GalleryLastModified(version)));
  }

  factory GalleryImpl.instance() => _global!;

  factory GalleryImpl(bool temporary) {
    if (_global != null) {
      return _global!;
    }

    _global = GalleryImpl._new(openAndroidGalleryIsar(temporary: temporary));
    return _global!;
  }

  _AndroidGallery? _currentApi;

  void _setCurrentApi(_AndroidGallery api) {
    _currentApi = api;
  }

  void _unsetCurrentApi() {
    _currentApi = null;
  }

  GalleryImpl._new(this.db);

  @override
  void updatePictures(List<DirectoryFile?> f, String bucketId, int startTime,
      bool inRefresh, bool empty) {
    var st = _currentApi?.currentImages?.startTime;

    if (st == null || st > startTime) {
      return;
    }

    if (_currentApi?.currentImages?.bucketId != bucketId) {
      return;
    }

    var db = _currentApi?.currentImages?.db;
    if (db == null) {
      return;
    }

    if (empty) {
      _currentApi?.currentImages?.callback
          ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, true);
    }

    if (f.isEmpty) {
      return;
    }

    try {
      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(f
          .cast<DirectoryFile>()
          .map((e) => SystemGalleryDirectoryFile(
              id: e.id,
              bucketId: e.bucketId,
              name: e.name,
              lastModified: e.lastModified,
              height: e.height,
              width: e.width,
              isGif: e.isGif,
              originalUri: e.originalUri,
              isVideo: e.isVideo))
          .toList()));
    } catch (e) {
      log("updatePictures", level: Level.WARNING.value, error: e);
    }
    _currentApi?.currentImages?.callback
        ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, false);
  }

  @override
  void addThumbnails(List<ThumbnailId?> thumbs) {
    if (thumbs.isEmpty) {
      return;
    }

    if (thumbnailIsar().thumbnails.countSync() >= 3000) {
      thumbnailIsar().writeTxnSync(() => thumbnailIsar()
          .thumbnails
          .where()
          .sortByUpdatedAt()
          .limit(thumbs.length)
          .deleteAllSync());
    }

    thumbnailIsar().writeTxnSync(() {
      thumbnailIsar().thumbnails.putAllSync(thumbs
          .cast<ThumbnailId>()
          .map((e) => Thumbnail(e.id, DateTime.now(), e.thumb))
          .toList());
    });
  }

  @override
  List<int?> thumbsExist(List<int?> ids) {
    List<int> response = [];
    for (final id in ids.cast<int>()) {
      if (thumbnailIsar().thumbnails.where().idEqualTo(id).countSync() != 1) {
        response.add(id);
      }
    }

    return response;
  }

  @override
  void updateDirectories(List<Directory?> d, bool inRefresh, bool empty) {
    if (empty) {
      _currentApi?.callback
          ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, true);
      return;
    }
    var blacklisted = db.blacklistedDirectorys
        .where()
        .anyOf(d.cast<Directory>(),
            (q, element) => q.bucketIdEqualTo(element.bucketId))
        .findAllSync();
    final map = <String, void>{for (var i in blacklisted) i.bucketId: Null};
    d = List.from(d);
    d.removeWhere((element) => map.containsKey(element!.bucketId));

    db.writeTxnSync(() {
      db.systemGalleryDirectorys.putAllSync(d
          .cast<Directory>()
          .map((e) => SystemGalleryDirectory(
              bucketId: e.bucketId,
              name: e.name,
              relativeLoc: e.relativeLoc,
              thumbFileId: e.thumbFileId,
              lastModified: e.lastModified))
          .toList());
    });
    _currentApi?.callback
        ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, false);
  }

  @override
  void notify() {
    _currentApi?.currentImages?.refreshGrid?.call();
    _currentApi?.refreshGrid?.call();
  }
}

GalleryImpl? _global;
