// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class _JoinedDirectories extends _AndroidGalleryFiles {
  _JoinedDirectories({
    required super.directories,
    required super.parent,
    required super.source,
    required super.sourceTags,
  }) : super(
          type: GalleryFilesPageType.normal,
          target: "joinedDir",
          bucketId: "joinedDir",
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

class _AndroidGalleryFiles implements Files {
  _AndroidGalleryFiles({
    required this.bucketId,
    required this.directories,
    required this.sourceTags,
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
  final MapFilesSourceTags sourceTags;

  @override
  final List<Directory> directories;

  @override
  final String bucketId;
}

class _AndroidFileSourceJoined implements SortingResourceSource<int, File> {
  _AndroidFileSourceJoined(
    this.directories,
    this.type,
    this.sourceTags,
  ) {
    // _favoritesWatcher =
    //     FavoritePostSourceService.safe()?.cache.countEvents.listen((_) {
    //   backingStorage.addAll([]);
    // });
  }

  final List<Directory> directories;
  final GalleryFilesPageType type;
  // late final StreamSubscription<int>? _favoritesWatcher;
  final MapFilesSourceTags sourceTags;

  final cursorApi = platform.FilesCursor();

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
  final ListStorage<File> backingStorage = ListStorage();

  @override
  Future<int> clearRefresh([bool silent = false]) async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    backingStorage.list.clear();
    sourceTags.clear();

    final cursor = await cursorApi.acquire(
      directories: directories.map((e) => e.bucketId).toList(),
      type: switch (type) {
        GalleryFilesPageType.normal ||
        GalleryFilesPageType.favorites =>
          platform.FilesCursorType.normal,
        GalleryFilesPageType.trash => platform.FilesCursorType.trashed,
      },
      sortingMode: switch (sortingMode) {
        SortingMode.size => platform.FilesSortingMode.size,
        SortingMode() => platform.FilesSortingMode.none,
      },
      limit: 0,
    );

    try {
      while (true) {
        final e = await cursorApi.advance(cursor);
        if (e.isEmpty) {
          break;
        }

        backingStorage.addAll(
          e.map((e) {
            final tags = LocalTagsService.safe()?.get(e.name) ?? <String>[];
            final f = e.toAndroidFile(
              tags.fold({}, (map, e) {
                map[e] = null;

                return map;
              }),
            );

            sourceTags.addAll(tags);

            return f;
          }),
          true,
        );
      }
    } catch (e, trace) {
      Logger.root.severe(
        "_AndroidFileSourceJoined",
        e,
        trace,
      );
    } finally {
      await cursorApi.destroy(cursor);
    }

    if (sortingMode == SortingMode.stars &&
        FavoritePostSourceService.available) {
      backingStorage.list.sort((e1, e2) {
        if (e1.res == null || e2.res == null) {
          return 0;
        }

        final e1FavoriteStars =
            const FavoritePostSourceService().cache.get(e1.res!)?.stars ??
                FavoriteStars.zero;
        final e2FavoriteStars =
            const FavoritePostSourceService().cache.get(e2.res!)?.stars ??
                FavoriteStars.zero;

        return e2FavoriteStars.index.compareTo(e1FavoriteStars.index);
      });
    }

    backingStorage.addAll([]);
    sourceTags.notify();
    progress.inRefreshing = false;

    return Future.value(backingStorage.count);
  }

  @override
  Future<int> clearRefreshSilent() => clearRefresh(true);

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    // _favoritesWatcher?.cancel();
    backingStorage.destroy();
    progress.close();
  }
}

class AndroidUriFile {
  const AndroidUriFile({
    required this.uri,
    required this.name,
    required this.lastModified,
    required this.height,
    required this.width,
    required this.size,
  });

  final int size;

  final int width;
  final int height;

  final int lastModified;

  final String name;
  final String uri;

  // @override
  // Contentable content() {
  //   final t = PostContentType.fromUrl(uri);

  //   final imageSize = Size(width.toDouble(), height.toDouble());

  //   return switch (t) {
  //     PostContentType.none => EmptyContent(this),
  //     PostContentType.video => AndroidVideo(this, uri: uri, size: imageSize),
  //     PostContentType.gif => AndroidGif(this, uri: uri, size: imageSize),
  //     PostContentType.image => AndroidImage(this, uri: uri, size: imageSize),
  //   };
  // }

  // @override
  // String alias(bool long) => name;

  // @override
  // Key uniqueKey() => ValueKey(uri);
}
