// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class _AndroidGallery implements Directories {
  _AndroidGallery(
    this.blacklistedDirectory,
    this.directoryTag,
    this.settingsService,
    this.galleryTrash,
  );

  final BlacklistedDirectoryService? blacklistedDirectory;
  final DirectoryTagService? directoryTag;
  final GalleryTrash? galleryTrash;

  final SettingsService settingsService;

  final time = DateTime.now();

  bool isThumbsLoading = false;

  @override
  _AndroidGalleryFiles? bindFiles;

  @override
  TrashCell? get trashCell => source.trashCell;

  @override
  late final _AndroidSource source = _AndroidSource(
    galleryTrash != null ? TrashCell(galleryTrash!) : null,
    blacklistedDirectory,
    directoryTag,
  );

  @override
  void close() {
    source.destroy();
    trashCell?.dispose();
    bindFiles = null;
    _GalleryImpl().liveInstances.removeWhere((e) => e == this);
    if (kDebugMode) {
      print(_GalleryImpl().liveInstances);
    }
  }

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService? directoryTag,
    DirectoryMetadataService? directoryMetadata,
    FavoritePostSourceService? favoritePosts,
    LocalTagsService? localTags, {
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
        localTags,
      ),
      sourceTags: sourceTags,
      directories: [directory],
      target: name,
      type: type,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTags: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
      bucketId: bucketId,
    );
  }

  @override
  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService? directoryTag,
    DirectoryMetadataService? directoryMetadata,
    FavoritePostSourceService? favoritePosts,
    LocalTagsService? localTags,
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
        localTags,
      ),
      sourceTags: sourceTags,
      directories: directories,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTags: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
    );
  }
}

class _AndroidSource implements ResourceSource<int, Directory> {
  _AndroidSource(
    this.trashCell,
    this.blacklistedDirectory,
    this.directoryTag,
  );

  final TrashCell? trashCell;
  final BlacklistedDirectoryService? blacklistedDirectory;
  final DirectoryTagService? directoryTag;

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final SourceStorage<int, Directory> backingStorage = ListStorage();

  final cursorApi = platform.DirectoriesCursor();

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return Future.value(count);
    }
    progress.inRefreshing = true;

    backingStorage.clear();
    trashCell?.refresh();

    final token = await cursorApi.acquire();
    try {
      while (true) {
        final e = await cursorApi.advance(token);
        if (e.isEmpty) {
          break;
        }

        final blacklisted =
            blacklistedDirectory?.getAll(e.keys.map((e) => e).toList()) ??
                const [];
        for (final b in blacklisted) {
          e.remove(b.bucketId);
        }

        backingStorage.addAll(
          e.values
              .map(
                (e) => Directory(
                  bucketId: e.bucketId,
                  name: e.name,
                  tag: directoryTag?.get(e.bucketId) ?? "",
                  volumeName: e.volumeName,
                  relativeLoc: e.relativeLoc,
                  thumbFileId: e.thumbFileId,
                  lastModified: e.lastModified,
                ),
              )
              .toList(),
          true,
        );
      }
    } catch (e, trace) {
      Logger.root.severe("_AndroidSource", e, trace);
    } finally {
      await cursorApi.destroy(token);
    }

    progress.inRefreshing = false;
    backingStorage.addAll([]);

    return Future.value(count);
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    trashCell?.dispose();
    backingStorage.destroy();
    progress.close();
  }
}
