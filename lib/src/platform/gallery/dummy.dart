// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart";

class DummyGalleryApi implements GalleryApi {
  @override
  Future<int> get version => Future.value(0);

  @override
  void notify(String? target) {}

  @override
  Directories open(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    bool? temporaryDb,
    bool setCurrentApi = true,
    required AppLocalizations l10n,
  }) {
    return _DummyDirectories();
  }

  @override
  Events get events => const Events.none();

  @override
  Future<({String path, String formattedPath})?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  }) {
    return Future.value();
  }

  @override
  FilesManagement get files => const FilesManagement.dummy();

  @override
  CachedThumbs get thumbs => const CachedThumbs.dummy();

  @override
  GalleryTrash get trash => const GalleryTrash.dummy();

  @override
  Search get search => const Search.dummy();
}

class _DummyDirectories implements Directories {
  _DummyDirectories();

  @override
  void close() {
    source.destroy();
  }

  @override
  Files? get bindFiles => null;

  @override
  final ResourceSource<int, Directory> source =
      GenericListSource(() => Future.value([]));

  @override
  TrashCell get trashCell => throw UnimplementedError();

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags, {
    required String name,
    required String bucketId,
  }) {
    throw UnimplementedError();
  }

  @override
  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags,
  ) {
    throw UnimplementedError();
  }
}
