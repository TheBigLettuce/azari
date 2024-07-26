// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_api_directories.dart";

class _JoinedDirectories extends _AndroidGalleryFiles {
  _JoinedDirectories({
    required super.directories,
    required super.parent,
    required super.source,
    required super.directoryMetadata,
    required super.directoryTag,
    required super.favoriteFile,
    required super.localTags,
    required super.sourceTags,
  }) : super(
          type: GalleryFilesPageType.normal,
          target: "joinedDir",
        );

  @override
  bool isBucketId(String dirId) {
    for (final d in directories) {
      if (d.bucketId == dirId) {
        return true;
      }
    }

    return false;
  }
}

class _AndroidGalleryFiles implements GalleryAPIFiles {
  _AndroidGalleryFiles({
    required this.directories,
    required this.sourceTags,
    required this.localTags,
    required this.favoriteFile,
    required this.directoryMetadata,
    required this.directoryTag,
    required this.source,
    required this.type,
    required this.parent,
    required this.target,
  }) : startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  final GalleryFilesPageType type;

  @override
  final _AndroidGallery parent;

  final int startTime;
  final String target;

  bool isThumbsLoading = false;

  bool isBucketId(String bucketId) => directories.first.bucketId == bucketId;

  @override
  final _AndroidFileSourceJoined source;

  @override
  void close() {
    parent.bindFiles = null;
    source.destroy();
    sourceTags.dispose();
  }

  @override
  final DirectoryMetadataService directoryMetadata;

  @override
  final DirectoryTagService directoryTag;

  @override
  final FavoriteFileService favoriteFile;

  @override
  final LocalTagsService localTags;

  @override
  final MapFilesSourceTags sourceTags;

  @override
  final List<GalleryDirectory> directories;
}

class _AndroidFileSourceJoined
    implements SortingResourceSource<int, GalleryFile> {
  _AndroidFileSourceJoined(
    this.directories,
    this.type,
    this.favoriteFile,
    this.sourceTags,
  ) {
    _favoritesWatcher = favoriteFile.watch((_) {
      backingStorage.addAll([]);
    });
  }

  final List<GalleryDirectory> directories;
  final GalleryFilesPageType type;
  final FavoriteFileService favoriteFile;
  late final StreamSubscription<int>? _favoritesWatcher;
  final MapFilesSourceTags sourceTags;

  @override
  bool get hasNext => false;

  SortingMode _sortingMode = SortingMode.none;

  @override
  SortingMode get sortingMode => _sortingMode;

  @override
  set sortingMode(SortingMode s) {
    _sortingMode = s;

    clearRefresh();
  }

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final ListStorage<GalleryFile> backingStorage = ListStorage();

  @override
  Future<int> clearRefresh([bool silent = false]) async {
    if (progress.inRefreshing) {
      return Future.value(count);
    }

    backingStorage.list.clear();
    sourceTags.clear();

    progress.inRefreshing = true;
    if (type.isTrash()) {
      const AndroidGalleryManagementApi().refreshTrashed(sortingMode);
    } else if (type.isFavorites()) {
      int offset = 0;

      while (true) {
        final f = favoriteFile.getAll(offset: offset, limit: 200);
        offset += f.length;

        if (f.isEmpty) {
          break;
        }

        await const AndroidGalleryManagementApi()
            .refreshFavorites(f, sortingMode);
      }
    } else {
      if (directories.length == 1) {
        const AndroidGalleryManagementApi()
            .refreshFiles(directories.first.bucketId, sortingMode);
      } else {
        const AndroidGalleryManagementApi().refreshFilesMultiple(
          directories.map((e) => e.bucketId).toList(),
          sortingMode,
        );
      }
    }

    return Future.value(backingStorage.count);
  }

  @override
  Future<int> clearRefreshSilent() => clearRefresh(true);

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    _favoritesWatcher?.cancel();
    backingStorage.destroy();
    progress.close();
  }
}

class AndroidUriFile implements ImageViewContentable, ContentWidgets {
  const AndroidUriFile({
    required this.uri,
    required this.name,
    required this.lastModified,
    required this.height,
    required this.width,
    required this.size,
  });

  factory AndroidUriFile.fromUriFile(UriFile uriFile) => AndroidUriFile(
        uri: uriFile.uri,
        name: uriFile.name,
        lastModified: uriFile.lastModified,
        height: uriFile.height,
        width: uriFile.width,
        size: uriFile.size,
      );

  final int size;

  final int width;
  final int height;

  final int lastModified;

  final String name;
  final String uri;

  @override
  Contentable content() {
    final t = PostContentType.fromUrl(uri);

    final imageSize = Size(width.toDouble(), height.toDouble());

    return switch (t) {
      PostContentType.none => EmptyContent(this),
      PostContentType.video => AndroidVideo(this, uri: uri, size: imageSize),
      PostContentType.gif => AndroidGif(this, uri: uri, size: imageSize),
      PostContentType.image => AndroidImage(this, uri: uri, size: imageSize),
    };
  }

  @override
  String alias(bool long) => name;

  @override
  Key uniqueKey() => ValueKey(uri);
}
