// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

_GalleryImpl? _global;

/// Callbacks related to the gallery.
class _GalleryImpl implements GalleryApi {
  final Isar db;
  final bool temporary;
  final List<_AndroidGallery> _temporaryApis = [];

  bool isSavingTags = false;

  _AndroidGallery? _currentApi;

  @override
  void updatePictures(List<DirectoryFile?> f, String bucketId, int startTime,
      bool inRefresh, bool empty) {
    final st = _currentApi?.currentImages?.startTime;

    if (st == null || st > startTime) {
      return;
    }

    if (_currentApi?.currentImages?.isBucketId(bucketId) != true) {
      return;
    }

    final db = _currentApi?.currentImages?.db;
    if (db == null) {
      return;
    }

    if (empty) {
      _currentApi?.currentImages?.callback
          ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, true);
      return;
    } else if (f.isEmpty && !inRefresh) {
      _currentApi?.currentImages?.callback
          ?.call(db.systemGalleryDirectoryFiles.countSync(), false, false);

      return;
    } else if (f.isEmpty) {
      return;
    }

    try {
      final out = f
          .cast<DirectoryFile>()
          .map((e) => SystemGalleryDirectoryFile(
              id: e.id,
              bucketId: e.bucketId,
              notesFlat: Dbs.g.main.noteGallerys
                      .getByIdSync(e.id)
                      ?.text
                      .join()
                      .toLowerCase() ??
                  "",
              name: e.name,
              size: e.size,
              isDuplicate:
                  RegExp(r'[(][0-9].*[)][.][a-zA-Z0-9].*').hasMatch(e.name),
              isFavorite:
                  Dbs.g.blacklisted.favoriteBooruPosts.getSync(e.id) != null,
              lastModified: e.lastModified,
              height: e.height,
              width: e.width,
              isGif: e.isGif,
              isOriginal: PostTags.g.isOriginal(e.name),
              originalUri: e.originalUri,
              isVideo: e.isVideo,
              tagsFlat: PostTags.g.getTagsPost(e.name).join(" ")))
          .toList();

      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(out));
    } catch (e) {
      log("updatePictures", level: Level.WARNING.value, error: e);
    }

    _currentApi?.currentImages?.callback
        ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, false);
  }

  @override
  void updateDirectories(List<Directory?> d, bool inRefresh, bool empty) {
    if (empty) {
      _currentApi?.callback
          ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, true);
      for (final api in _temporaryApis) {
        api.temporarySet?.call(db.systemGalleryDirectorys.countSync(), true);
      }

      return;
    } else if (d.isEmpty && !inRefresh) {
      _currentApi?.callback
          ?.call(db.systemGalleryDirectorys.countSync(), false, false);
      for (final api in _temporaryApis) {
        api.temporarySet
            ?.call(db.systemGalleryDirectorys.countSync(), !inRefresh);
      }

      return;
    } else if (d.isEmpty) {
      return;
    }

    final blacklisted = Dbs.g.blacklisted.blacklistedDirectorys
        .where()
        .anyOf(d.cast<Directory>(),
            (q, element) => q.bucketIdEqualTo(element.bucketId))
        .findAllSync();
    final map = <String, void>{for (var i in blacklisted) i.bucketId: Null};
    d = List.from(d);
    d.removeWhere((element) => map.containsKey(element!.bucketId));

    final out = d
        .cast<Directory>()
        .map((e) => SystemGalleryDirectory(
            bucketId: e.bucketId,
            name: e.name,
            tag: PostTags.g.directoryTag(e.bucketId) ?? "",
            volumeName: e.volumeName,
            relativeLoc: e.relativeLoc,
            thumbFileId: e.thumbFileId,
            lastModified: e.lastModified))
        .toList();

    db.writeTxnSync(() {
      db.systemGalleryDirectorys.putAllSync(out);
    });

    _currentApi?.callback
        ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, false);
    for (final api in _temporaryApis) {
      api.temporarySet
          ?.call(db.systemGalleryDirectorys.countSync(), !inRefresh);
    }
  }

  @override
  void notify(String? target) {
    if (target == null || target == _currentApi?.currentImages?.target) {
      _currentApi?.currentImages?.refreshGrid?.call();
    }
    _currentApi?.refreshGrid?.call();
    for (final api in _temporaryApis) {
      api.refreshGrid?.call();
    }
  }

  @override
  void notifyNetworkStatus(bool hasInternet) {
    if (NetworkStatus.g.hasInternet != hasInternet) {
      NetworkStatus.g.hasInternet = hasInternet;
      NetworkStatus.g.notify?.call();
    }
  }

  factory _GalleryImpl(bool temporary) {
    if (_global != null) {
      return _global!;
    }

    _global = _GalleryImpl._new(
        DbsOpen.androidGalleryDirectories(temporary: temporary), temporary);
    return _global!;
  }

  void _setCurrentApi(_AndroidGallery api) {
    _currentApi = api;
  }

  void _unsetCurrentApi() {
    _currentApi = null;
  }

  _GalleryImpl._new(this.db, this.temporary);
}
