// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_api_directories.dart";

_GalleryImpl? _global;

extension DirectoryFileToAndroidFile on DirectoryFile {
  static final _regxp = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

  GalleryFile toAndroidFile(List<String> tags) {
    return AndroidGalleryFile(
      tagsFlat: tags.join(" "),
      id: id,
      bucketId: bucketId,
      name: name,
      lastModified: lastModified,
      originalUri: originalUri,
      height: height,
      width: width,
      size: size,
      isVideo: isVideo,
      isGif: isGif,
      isDuplicate: _regxp.hasMatch(name),
    );
  }
}

class AndroidGalleryDirectory extends GalleryDirectoryBase
    with GalleryDirectory {
  const AndroidGalleryDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

class AndroidGalleryFile extends FileBase with GalleryFile {
  const AndroidGalleryFile({
    required super.id,
    required super.bucketId,
    required super.name,
    required super.isVideo,
    required super.isGif,
    required super.size,
    required super.height,
    required super.isDuplicate,
    required super.width,
    required super.lastModified,
    required super.originalUri,
    required super.tagsFlat,
  });
}

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

  // static final _regxp = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

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
      api.sourceTags.notify();

      return false;
    } else if (f.isEmpty) {
      return false;
    }

    if (api.type.isFavorites()) {
      final c = <String, DirectoryMetadataData>{};

      api.source.backingStorage.addAll(
        f
            .where(
          (dir) => GalleryFilesPageType.filterAuthBlur(
            c,
            dir,
            api.directoryTag,
            api.directoryMetadata,
          ),
        )
            .map((e) {
          final tags = api.localTags.get(e!.name);
          final f = e.toAndroidFile(tags);

          api.sourceTags.addAll(tags);

          return f;
        }),
      );
    } else {
      api.source.backingStorage.addAll(
        f.map((e) {
          final tags = api.localTags.get(e!.name);
          final f = e.toAndroidFile(tags);

          api.sourceTags.addAll(tags);

          return f;
        }),
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
            (e) => AndroidGalleryDirectory(
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

  @override
  void galleryTapDownEvent() {
    AndroidGallery._tapDownEvents.add(null);
  }
}
