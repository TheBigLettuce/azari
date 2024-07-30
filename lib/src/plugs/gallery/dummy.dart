// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/plugs/gallery.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

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

  @override
  GalleryDirectory makeGalleryDirectory({
    required int thumbFileId,
    required String bucketId,
    required String name,
    required String relativeLoc,
    required String volumeName,
    required int lastModified,
    required String tag,
  }) {
    throw UnimplementedError();
  }

  @override
  GalleryFile makeGalleryFile({
    required Map<String, void> tags,
    required int id,
    required String bucketId,
    required String name,
    required int lastModified,
    required String originalUri,
    required int height,
    required int width,
    required int size,
    required bool isVideo,
    required bool isGif,
    required bool isDuplicate,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<void>? get galleryTapDownEvents => null;
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
    GalleryDirectory directory,
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
    List<GalleryDirectory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    throw UnimplementedError();
  }
}
