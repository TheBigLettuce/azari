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
      temporary,
    );
    return _global!;
  }

  _GalleryImpl._new(this.temporary);
  final bool temporary;

  bool isSavingTags = false;

  _AndroidGallery? _currentApi;

  static final _regxp = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

  @override
  bool updatePictures(
    List<DirectoryFile?> f,
    String bucketId,
    int startTime,
    bool inRefresh,
    bool empty,
  ) {
    final api = _currentApi?.bindFiles;
    if (api == null || api.startTime > startTime || !api.isBucketId(bucketId)) {
      return false;
    } else if (empty) {
      api.source.progress.inRefreshing = false;
      api.source.backingStorage.clear();

      return false;
    }

    if (f.isEmpty && !inRefresh) {
      api.source.progress.inRefreshing = false;
      api.source.backingStorage.addAll([]);

      return false;
    } else if (f.isEmpty) {
      return false;
    }

    if (api.type.isFavorites()) {
      final c = <String, DirectoryMetadataData>{};

      api.source.backingStorage.addAll(
        f.where((dir) {
          final segment = GalleryDirectories.segmentCell(
            dir!.bucketName,
            dir.bucketId,
            api.directoryTag,
          );

          DirectoryMetadataData? data = c[segment];
          if (data == null) {
            final d = api.directoryMetadata.get(segment);
            if (d == null) {
              return true;
            }

            data = d;
            c[segment] = d;
          }

          return !data.requireAuth && !data.blur;
        }).map(
          (e) => GalleryFile.forPlatform(
            tagsFlat: api.localTags.get(e!.name).join(" "),
            id: e.id,
            bucketId: e.bucketId,
            name: e.name,
            lastModified: e.lastModified,
            originalUri: e.originalUri,
            height: e.height,
            width: e.width,
            size: e.size,
            isVideo: e.isVideo,
            isGif: e.isGif,
            isDuplicate: _regxp.hasMatch(e.name),
          ),
        ),
      );
    } else {
      api.source.backingStorage.addAll(
        f.map(
          (e) => GalleryFile.forPlatform(
            tagsFlat: api.localTags.get(e!.name).join(" "),
            id: e.id,
            bucketId: e.bucketId,
            name: e.name,
            lastModified: e.lastModified,
            originalUri: e.originalUri,
            height: e.height,
            width: e.width,
            size: e.size,
            isVideo: e.isVideo,
            isGif: e.isGif,
            isDuplicate: _regxp.hasMatch(e.name),
          ),
        ),
        true,
      );
    }

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
      return false;
    } else if (d.isEmpty && !inRefresh) {
      api.source.progress.inRefreshing = false;
      api.source.backingStorage.addAll([]);

      return false;
    } else if (d.isEmpty) {
      return false;
    }

    final b = api.blacklistedDirectory.getAll(d.keys.map((e) => e!).toList());
    for (final e in b) {
      d.remove(e.bucketId);
    }

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
      true,
    );

    return true;
  }

  @override
  void notify(String? target) {
    if (target == null || target == _currentApi?.bindFiles?.target) {
      _currentApi?.bindFiles?.source.clearRefresh();
    }
    _currentApi?.source.clearRefresh();
  }

  @override
  void notifyNetworkStatus(bool hasInternet) {
    if (NetworkStatus.g.hasInternet != hasInternet) {
      NetworkStatus.g.hasInternet = hasInternet;
      NetworkStatus.g.notify?.call();
    }
  }
}
