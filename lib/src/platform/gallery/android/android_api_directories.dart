// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class _AndroidGallery implements Directories {
  _AndroidGallery(
    this.blacklistedDirectory,
    this.directoryTag, {
    required this.localizations,
  });

  final BlacklistedDirectoryService blacklistedDirectory;
  final DirectoryTagService directoryTag;
  final AppLocalizations localizations;

  final time = DateTime.now();

  bool isThumbsLoading = false;

  @override
  _AndroidGalleryFiles? bindFiles;

  @override
  TrashCell get trashCell => source.trashCell;

  @override
  late final _AndroidSource source = _AndroidSource(TrashCell(localizations));

  @override
  void close() {
    source.destroy();
    trashCell.dispose();
    bindFiles = null;
    _GalleryImpl()._currentApi = null;
  }

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags, {
    required String bucketId,
    required String name,
  }) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    final sourceTags = MapFilesSourceTags();

    return bindFiles = _AndroidGalleryFiles(
      source: _AndroidFileSourceJoined(
        [directory],
        type,
        favoritePosts,
        sourceTags,
      ),
      sourceTags: sourceTags,
      directories: [directory],
      target: name,
      type: type,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
      bucketId: bucketId,
    );
  }

  @override
  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    final sourceTags = MapFilesSourceTags();

    return bindFiles = _JoinedDirectories(
      source: _AndroidFileSourceJoined(
        directories,
        GalleryFilesPageType.normal,
        favoritePosts,
        sourceTags,
      ),
      sourceTags: sourceTags,
      directories: directories,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
    );
  }
}

class _AndroidSource implements ResourceSource<int, Directory> {
  _AndroidSource(this.trashCell);

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final SourceStorage<int, Directory> backingStorage = ListStorage();

  final TrashCell trashCell;

  @override
  Future<int> clearRefresh() {
    if (progress.inRefreshing) {
      return Future.value(count);
    }
    progress.inRefreshing = true;

    backingStorage.clear();
    AndroidGalleryApi.appContext.invokeMethod("refreshGallery");
    trashCell.refresh();

    return Future.value(count);
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    trashCell.dispose();
    backingStorage.destroy();
    progress.close();
  }
}
