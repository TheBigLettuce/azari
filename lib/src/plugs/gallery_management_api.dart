// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management/dummy.dart"
    if (dart.library.io) "package:gallery/src/plugs/gallery_management/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/gallery_management/web.dart";
import "package:gallery/src/plugs/platform_functions.dart";

abstract interface class GalleryManagementApi {
  factory GalleryManagementApi.current() => getApi();

  GalleryTrash get trash;
  CachedThumbs get thumbs;
  FilesManagement get files;

  Future<String> ensureDownloadDirectoryExists(String site);

  Future<(String formattedPath, String path)?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  });
}

abstract interface class FilesManagement {
  Future<void> rename(String uri, String newName, [bool notify = true]);

  Future<bool> exists(String filePath);

  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  });

  void copyMove(
    String chosen,
    String chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    required bool newDir,
  });

  void deleteAll(List<GalleryFile> selected);
}

abstract interface class CachedThumbs {
  Future<int> size([bool fromPinned = false]);

  Future<ThumbId> get(int id);

  void clear([bool fromPinned = false]);

  void removeAll(List<int> id, [bool fromPinned = false]);

  Future<ThumbId> saveFromNetwork(String url, int id);
}

abstract interface class GalleryTrash {
  Future<int?> get thumbId;

  void addAll(List<String> uris);

  void empty();

  void removeAll(List<String> uris);
}

class DummyGalleryManagementApi implements GalleryManagementApi {
  const DummyGalleryManagementApi();

  @override
  GalleryTrash get trash => const DummyGalleryTrash();

  @override
  CachedThumbs get thumbs => const DummyCachedThumbs();

  @override
  FilesManagement get files => const DummyFilesManagement();

  @override
  Future<(String, String)?> chooseDirectory(
    AppLocalizations _, {
    bool temporary = false,
  }) =>
      Future.value();

  @override
  Future<String> ensureDownloadDirectoryExists(String site) => Future.value("");
}

class DummyGalleryTrash implements GalleryTrash {
  const DummyGalleryTrash();

  @override
  void addAll(List<String> uris) {}

  @override
  void empty() {}

  @override
  void removeAll(List<String> uris) {}

  @override
  Future<int?> get thumbId => Future.value();
}

class DummyFilesManagement implements FilesManagement {
  const DummyFilesManagement();

  @override
  void deleteAll(List<GalleryFile> selected) {}

  @override
  Future<bool> exists(String filePath) => Future.value(false);

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) =>
      Future.value();

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) =>
      Future.value();

  @override
  void copyMove(
    String chosen,
    String chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    required bool newDir,
  }) {}
}

class DummyCachedThumbs implements CachedThumbs {
  const DummyCachedThumbs();

  @override
  void clear([bool fromPinned = false]) {}

  @override
  Future<ThumbId> get(int id) => throw UnimplementedError();

  @override
  void removeAll(List<int> id, [bool fromPinned = false]) {}

  @override
  Future<ThumbId> saveFromNetwork(String url, int id) {
    throw UnimplementedError();
  }

  @override
  Future<int> size([bool fromPinned = false]) => Future.value(0);
}
