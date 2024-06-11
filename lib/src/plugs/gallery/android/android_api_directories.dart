// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery/android/api.g.dart";
import "package:gallery/src/plugs/gallery_management/android.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/plugs/platform_functions.dart";

part "android_api_files.dart";
part "android_gallery.dart";
part "gallery_impl.dart";

class _AndroidGallery implements GalleryAPIDirectories {
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
  late final _AndroidSource source =
      _AndroidSource(TrashCell(localizations, const AndroidGallery()));

  @override
  void close() {
    source.destroy();
    trashCell.dispose();
    bindFiles = null;
    _global!._currentApi = null;
  }

  @override
  GalleryAPIFiles files(
    String bucketId,
    String name,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _AndroidGalleryFiles(
      source: _AndroidFileSourceJoined([bucketId], type, favoriteFile),
      bucketId: bucketId,
      target: name,
      type: type,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoriteFile: favoriteFile,
      localTags: localTags,
    );
  }

  @override
  GalleryAPIFiles joinedFiles(
    List<String> bucketIds,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _JoinedDirectories(
      source: _AndroidFileSourceJoined(
        bucketIds,
        GalleryFilesPageType.normal,
        favoriteFile,
      ),
      directories: bucketIds,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoriteFile: favoriteFile,
      localTags: localTags,
    );
  }
}

class _AndroidSource implements ResourceSource<int, GalleryDirectory> {
  _AndroidSource(this.trashCell);

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final SourceStorage<int, GalleryDirectory> backingStorage = ListStorage();

  final TrashCell trashCell;

  @override
  Future<int> clearRefresh() {
    if (progress.inRefreshing) {
      return Future.value(count);
    }
    progress.inRefreshing = true;

    backingStorage.clear();
    const AndroidGalleryManagementApi().refreshGallery();
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
