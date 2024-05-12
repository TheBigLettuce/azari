// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_api_directories.dart";

_GalleryImpl? _global;

/// Callbacks related to the gallery.
class _GalleryImpl implements GalleryApi {
  factory _GalleryImpl(bool temporary) {
    if (_global != null) {
      return _global!;
    }

    _global = _GalleryImpl._new(
      // DbsOpen.androidGalleryDirectories(temporary),
      temporary,
    );
    return _global!;
  }

  _GalleryImpl._new(this.temporary);
  // final Isar db;
  final bool temporary;
  // final List<_AndroidGallery> _temporaryApis = [];

  bool isSavingTags = false;

  _AndroidGallery? _currentApi;

  @override
  bool updatePictures(
    List<DirectoryFile?> f,
    String bucketId,
    int startTime,
    bool inRefresh,
    bool empty,
  ) {
    final api = _currentApi?.bindFiles;
    if (api == null) {
      return false;
    }

    if (api.startTime > startTime) {
      return false;
    }

    if (!api.isBucketId(bucketId)) {
      return false;
    }

    // final db = _currentApi?.bindFiles?.db;
    // if (db == null) {
    //   return;
    // }

    if (empty) {
      // _currentApi?.currentImages?.callback
      //     ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, true);
      return false;
    } else if (f.isEmpty && !inRefresh) {
      // _currentApi?.currentImages?.callback
      //     ?.call(db.systemGalleryDirectoryFiles.countSync(), false, false);

      return false;
    } else if (f.isEmpty) {
      return false;
    }

    final r = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

    if (api.type.isFavorites()) {
    } else {
      api.source.backingStorage.addAll(
        f
            .map(
              (e) => GalleryFile.forPlatform(
                id: e!.id,
                bucketId: e.bucketId,
                name: e.name,
                lastModified: e.lastModified,
                originalUri: e.originalUri,
                height: e.height,
                width: e.width,
                size: e.size,
                isVideo: e.isVideo,
                isGif: e.isGif,
                isDuplicate: r.hasMatch(e.name),
              ),
            )
            .toList(),
        inRefresh,
      );
    }

    // try {
    //   final c = <String, DirectoryMetadata>{};

    //   final out = bucketId == "favorites"
    //       ? f
    //           .where((dir) {
    //             final segment = GalleryDirectories.segmentCell(
    //               dir!.bucketName,
    //               dir.bucketId,
    //             );

    //             DirectoryMetadata? data = c[segment];
    //             if (data == null) {
    //               final d = DirectoryMetadata.get(segment);
    //               if (d == null) {
    //                 return true;
    //               }

    //               data = d;
    //               c[segment] = d;
    //             }

    //             return !data.requireAuth && !data.blur;
    //           })
    //           .map(SystemGalleryDirectoryFile.fromDirectoryFile)
    //           .toList()
    //       : f.map(SystemGalleryDirectoryFile.fromDirectoryFile).toList();

    //   db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(out));
    // } catch (e) {
    //   log("updatePictures", level: Level.WARNING.value, error: e);
    // }

    // _currentApi?.currentImages?.callback
    //     ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, false);

    return true;
  }

  @override
  bool updateDirectories(
    Map<String?, Directory?> d,
    bool inRefresh,
    bool empty,
  ) {
    final api = _currentApi;
    if (empty || api == null) {
      // _currentApi?.callback
      //     ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, true);
      // for (final api in _temporaryApis) {
      //   api.temporarySet?.call(db.systemGalleryDirectorys.countSync(), true);
      // }

      return false;
    } else if (d.isEmpty && !inRefresh) {
      // _currentApi?.callback
      //     ?.call(db.systemGalleryDirectorys.countSync(), false, false);
      // for (final api in _temporaryApis) {
      //   api.temporarySet
      //       ?.call(db.systemGalleryDirectorys.countSync(), !inRefresh);
      // }

      return false;
    } else if (d.isEmpty) {
      return false;
    }

    final b = api.blacklistedDirectory.getAll(d.keys.map((e) => e!).toList());
    for (final e in b) {
      d.remove(e.bucketId);
    }

    // final blacklisted = Dbs.g.blacklisted.blacklistedDirectorys
    //     .where()
    //     // ignore: inference_failure_on_function_invocation
    //     .anyOf(
    //       d.cast<Directory>(),
    //       (q, element) => q.bucketIdEqualTo(element.bucketId),
    //     )
    //     .findAllSync();
    // final map = <String, void>{for (final i in blacklisted) i.bucketId: Null};
    // d = List.from(d);
    // d.removeWhere((element) => map.containsKey(element!.bucketId));

    // d
    //     .cast<Directory>()
    //     .map(
    // (e) => ,
    //     )
    //     .toList();

    // db.writeTxnSync(() {
    //   db.systemGalleryDirectorys.putAllSync(out);
    // });

    api.source.backingStorage.addAll(
      d.values
          .map(
            (e) => GalleryDirectory.forPlatform(
              bucketId: e!.bucketId,
              name: e.name,
              tag: api.directoryTag.get(e.bucketId) ?? "",
              volumeName: e.volumeName,
              relativeLoc: e.relativeLoc,
              thumbFileId: e.thumbFileId,
              lastModified: e.lastModified,
            ),
          )
          .toList(),
      inRefresh,
    );

    // _currentApi?.callback
    //     ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, false);
    // for (final api in _temporaryApis) {
    //   api.temporarySet
    //       ?.call(db.systemGalleryDirectorys.countSync(), !inRefresh);
    // }

    return true;
  }

  @override
  void notify(String? target) {
    if (target == null || target == _currentApi?.bindFiles?.target) {
      _currentApi?.bindFiles?.source.clearRefresh();
    }
    _currentApi?.source.clearRefresh();
    // for (final api in _temporaryApis) {
    //   api.refreshGrid?.call();
    // }
  }

  @override
  void notifyNetworkStatus(bool hasInternet) {
    if (NetworkStatus.g.hasInternet != hasInternet) {
      NetworkStatus.g.hasInternet = hasInternet;
      NetworkStatus.g.notify?.call();
    }
  }

  void _setCurrentApi(_AndroidGallery api) {
    _currentApi = api;
  }

  void _unsetCurrentApi() {
    _currentApi = null;
  }
}
