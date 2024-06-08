// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/plugs/gallery.dart";

class DummyGallery implements GalleryPlug {
  @override
  Future<int> get version => Future.value(0);

  @override
  bool get temporary => true;

  @override
  void notify(String? target) {}

  @override
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    bool? temporaryDb,
    bool setCurrentApi = true,
    required AppLocalizations l10n,
  }) {
    return _DummyDirectories();
  }
}

class _DummyDirectories implements GalleryAPIDirectories {
  _DummyDirectories();
  @override
  void close() {
    source.destroy();
  }

  @override
  GalleryAPIFiles? get bindFiles => null;

  @override
  final ResourceSource<int, GalleryDirectory> source =
      GenericListSource(() => Future.value([]));

  @override
  TrashCell get trashCell => throw UnimplementedError();

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
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles joinedFiles(
    List<String> bucketIds,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    throw UnimplementedError();
  }
}
