// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_api_directories.dart";

class _JoinedDirectories extends _AndroidGalleryFiles {
  _JoinedDirectories({
    required this.directories,
    required super.parent,
    required super.source,
    required super.directoryMetadata,
    required super.directoryTag,
    required super.favoriteFile,
    required super.localTags,
  }) : super(
          bucketId: "",
          type: GalleryFilesPageType.normal,
          target: "joinedDir",
        );

  final List<String> directories;

  @override
  bool isBucketId(String dirId) {
    for (final d in directories) {
      if (d == dirId) {
        return true;
      }
    }

    return false;
  }
}

class _AndroidGalleryFiles implements GalleryAPIFiles {
  _AndroidGalleryFiles({
    required this.localTags,
    required this.favoriteFile,
    required this.directoryMetadata,
    required this.directoryTag,
    required this.source,
    required this.type,
    required this.parent,
    required this.target,
    required String bucketId,
  })  : startTime = DateTime.now().millisecondsSinceEpoch,
        _bucketId = bucketId;

  @override
  final GalleryFilesPageType type;

  @override
  final _AndroidGallery parent;

  final String _bucketId;
  final int startTime;
  final String target;

  bool isThumbsLoading = false;

  bool isBucketId(String bucketId) => _bucketId == bucketId;

  @override
  final _AndroidFileSourceJoined source;

  @override
  void close() {
    parent.bindFiles = null;
    source.destroy();
  }

  @override
  final DirectoryMetadataService directoryMetadata;

  @override
  final DirectoryTagService directoryTag;

  @override
  final FavoriteFileService favoriteFile;

  @override
  final LocalTagsService localTags;
}

class _AndroidFileSourceJoined
    implements SortingResourceSource<int, GalleryFile> {
  _AndroidFileSourceJoined(this.bucketIds, this.type, this.favoriteFile) {
    _favoritesWatcher = favoriteFile.watch((_) {
      backingStorage.addAll([]);
    });
  }

  final List<String> bucketIds;
  final GalleryFilesPageType type;
  final FavoriteFileService favoriteFile;
  late final StreamSubscription<int>? _favoritesWatcher;

  @override
  int get count => backingStorage.count;

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final ListStorage<GalleryFile> backingStorage = ListStorage();

  @override
  Future<int> clearRefreshSorting(
    SortingMode sortingMode, [
    bool silent = false,
  ]) =>
      clearRefresh(sortingMode, silent);

  @override
  Future<int> nextSorting(SortingMode sortingMode, [bool silent = false]) =>
      next();

  @override
  Future<int> clearRefresh([
    SortingMode sortingMode = SortingMode.none,
    bool silent = false,
  ]) async {
    if (progress.inRefreshing) {
      return Future.value(count);
    }

    backingStorage.list.clear();

    progress.inRefreshing = true;
    if (type.isTrash()) {
      GalleryManagementApi.current().refreshTrashed(sortingMode);
    } else if (type.isFavorites()) {
      int offset = 0;

      while (true) {
        final f = favoriteFile.getAll(offset: offset, limit: 200);
        offset += f.length;

        if (f.isEmpty) {
          break;
        }

        await GalleryManagementApi.current().refreshFavorites(f, sortingMode);
      }
    } else {
      if (bucketIds.length == 1) {
        GalleryManagementApi.current()
            .refreshFiles(bucketIds.first, sortingMode);
      } else {
        GalleryManagementApi.current()
            .refreshFilesMultiple(bucketIds, sortingMode);
      }
    }

    return Future.value(backingStorage.count);
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    _favoritesWatcher?.cancel();
    backingStorage.destroy();
    progress.close();
  }
}


// Iterable<SystemGalleryDirectoryFile> Function(
//   int,
//   int,
//   String,
//   SortingMode,
//   FilteringMode,
// ) lastMofifiedGetElemsFiles(Isar db) {
//   return (offset, limit, s, sort, mode) {
//     if (sort == SortingMode.size) {
//       return db.systemGalleryDirectoryFiles
//           .filter()
//           .nameContains(s, caseSensitive: false)
//           .sortBySizeDesc()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     // if (mode == FilteringMode.same) {
//     //   return db.systemGalleryDirectoryFiles
//     //       .where()
//     //       .offset(offset)
//     //       .limit(limit)
//     //       .findAllSync();
//     // }

//     if (s.isEmpty) {
//       return db.systemGalleryDirectoryFiles
//           .where()
//           .sortByLastModifiedDesc()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     return db.systemGalleryDirectoryFiles
//         .filter()
//         .nameContains(s, caseSensitive: false)
//         .sortByLastModifiedDesc()
//         .offset(offset)
//         .limit(limit)
//         .findAllSync();
//   };
// }

// Iterable<SystemGalleryDirectoryFile> Function(
//   int,
//   int,
//   String,
//   SortingMode,
//   FilteringMode,
// ) defaultGetElemsFiles(Isar db) {
//   return (offset, limit, s, sort, _) {
//     if (sort == SortingMode.size) {
//       return db.systemGalleryDirectoryFiles
//           .filter()
//           .nameContains(s, caseSensitive: false)
//           .sortBySizeDesc()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     if (s.isEmpty) {
//       return db.systemGalleryDirectoryFiles
//           .where()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     return db.systemGalleryDirectoryFiles
//         .filter()
//         .nameContains(s, caseSensitive: false)
//         .offset(offset)
//         .limit(limit)
//         .findAllSync();
//   };
// }
