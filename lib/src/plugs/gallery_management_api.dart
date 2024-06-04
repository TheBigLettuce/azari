// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management/dummy.dart"
    if (dart.library.io) "package:gallery/src/plugs/gallery_management/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/gallery_management/web.dart";
import "package:gallery/src/plugs/platform_functions.dart";

abstract interface class GalleryManagementApi {
  factory GalleryManagementApi.current() => getApi();

  Future<String> ensureDownloadDirectoryExists(String site);

  Future<bool> fileExists(String filePath);

  void refreshFiles(String bucketId, SortingMode sortingMode);

  void refreshFilesMultiple(List<String> ids, SortingMode sortingMode);

  Future<void> refreshFavorites(List<int> ids, SortingMode sortingMode);

  Future<String> pickFileAndCopy(String outputDir);

  Future<void> rename(String uri, String newName, [bool notify = true]);

  void copyMoveFiles(
    String? chosen,
    String? chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    String? newDir,
  });

  Future<int?> trashThumbId();

  void deleteFiles(List<GalleryFile> selected);

  Future<SettingsPath?> chooseDirectory({bool temporary = false});

  Future<void> move(MoveOp op);

  void refreshGallery();

  void refreshTrashed(SortingMode sortingMode);

  void addToTrash(List<String> uris);

  void emptyTrash();

  void removeFromTrash(List<String> uris);

  Future<int> thumbCacheSize([bool fromPinned = false]);

  Future<ThumbId> getCachedThumb(int id);

  void clearCachedThumbs([bool fromPinned = false]);

  void deleteCachedThumbs(List<int> id, [bool fromPinned = false]);

  Future<ThumbId> saveThumbNetwork(String url, int id);
}

class DummyGalleryManagementApi implements GalleryManagementApi {
  const DummyGalleryManagementApi();

  @override
  void addToTrash(List<String> uris) {}

  @override
  Future<SettingsPath?> chooseDirectory({bool temporary = false}) =>
      Future.value();

  @override
  void clearCachedThumbs([bool fromPinned = false]) {}

  @override
  void copyMoveFiles(
    String? chosen,
    String? chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    String? newDir,
  }) {}

  @override
  void deleteCachedThumbs(List<int> id, [bool fromPinned = false]) {}

  @override
  void deleteFiles(List<GalleryFile> selected) {}

  @override
  void emptyTrash() {}

  @override
  Future<ThumbId> getCachedThumb(int id) {
    throw UnimplementedError();
  }

  @override
  Future<void> move(MoveOp op) => Future.value();

  @override
  Future<String> pickFileAndCopy(String outputDir) => Future.value("");

  @override
  Future<void> refreshFavorites(List<int> ids, SortingMode sortingMode) =>
      Future.value();

  @override
  void refreshFiles(String bucketId, SortingMode sortingMode) {}

  @override
  void refreshFilesMultiple(List<String> ids, SortingMode sortingMode) {}

  @override
  void refreshGallery() {}

  @override
  void refreshTrashed(SortingMode sortingMode) {}

  @override
  void removeFromTrash(List<String> uris) {}

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) =>
      Future.value();

  @override
  Future<ThumbId> saveThumbNetwork(String url, int id) {
    throw UnimplementedError();
  }

  @override
  Future<int> thumbCacheSize([bool fromPinned = false]) => Future.value(0);

  @override
  Future<int?> trashThumbId() => Future.value();

  @override
  Future<String> ensureDownloadDirectoryExists(String site) => Future.value("");

  @override
  Future<bool> fileExists(String filePath) => Future.value(false);
}

class MoveOp {
  const MoveOp({
    required this.source,
    required this.rootDir,
    required this.targetDir,
  });
  final String source;
  final String rootDir;
  final String targetDir;
}
