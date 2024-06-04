// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

class AndroidGalleryManagementApi implements GalleryManagementApi {
  const AndroidGalleryManagementApi();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  GalleryTrash get trash => const AndroidGalleryTrash();

  @override
  CachedThumbs get thumbs => const AndroidCachedThumbs();

  @override
  FilesManagement get files => const AndroidFilesManagement();

  @override
  Future<String> ensureDownloadDirectoryExists(String site) async {
    final downloadtd = Directory(
      joinAll([(await getTemporaryDirectory()).path, "downloads"]),
    );

    final dirpath = joinAll([downloadtd.path, site]);
    await downloadtd.create();

    await Directory(dirpath).create();

    return dirpath;
  }

  void refreshFiles(String bucketId, SortingMode sortingMode) {
    _channel.invokeMethod("refreshFiles", {
      "bucketId": bucketId,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  void refreshFilesMultiple(List<String> ids, SortingMode sortingMode) {
    _channel.invokeMethod("refreshFilesMultiple", {
      "ids": ids,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  Future<void> refreshFavorites(List<int> ids, SortingMode sortingMode) {
    return _channel.invokeMethod("refreshFavorites", {
      "ids": ids,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  Future<String> pickFileAndCopy(String outputDir) {
    return _channel
        .invokeMethod("pickFileAndCopy", outputDir)
        .then((value) => value as String);
  }

  @override
  Future<(String, String)?> chooseDirectory(
    AppLocalizations _, {
    bool temporary = false,
  }) async {
    return _channel.invokeMethod("chooseDirectory", temporary).then(
          (value) => (
            (value as Map)["pathDisplay"] as String,
            value["path"] as String,
          ),
        );
  }

  void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
  }

  void refreshTrashed(SortingMode sortingMode) {
    _channel.invokeMethod("refreshTrashed", sortingMode.sortingIdAndroid);
  }
}

class AndroidFilesManagement implements FilesManagement {
  const AndroidFilesManagement();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) {
    return _channel.invokeMethod(
      "move",
      {"source": source, "rootUri": rootDir, "dir": targetDir},
    );
  }

  @override
  void deleteAll(List<GalleryFile> selected) {
    _channel.invokeMethod(
      "deleteFiles",
      selected.map((e) => e.originalUri).toList(),
    );
  }

  @override
  Future<bool> exists(String filePath) => File(filePath).exists();

  void refreshFiles(String bucketId, SortingMode sortingMode) {
    _channel.invokeMethod("refreshFiles", {
      "bucketId": bucketId,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  @override
  void copyMove(
    String chosen,
    String chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    required bool newDir,
  }) {
    _channel.invokeMethod(
      "copyMoveFiles",
      {
        "dest": chosen,
        "images": selected
            .where((element) => !element.isVideo)
            .map((e) => e.id)
            .toList(),
        "videos": selected
            .where((element) => element.isVideo)
            .map((e) => e.id)
            .toList(),
        "move": move,
        "volumeName": chosenVolumeName,
        "newDir": newDir,
      },
    );
  }

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) {
    if (newName.isEmpty) {
      return Future.value();
    }

    // TODO: make awaitable in platform

    _channel.invokeMethod(
      "rename",
      {"uri": uri, "newName": newName, "notify": notify},
    );

    return Future.value();
  }
}

class AndroidCachedThumbs implements CachedThumbs {
  const AndroidCachedThumbs();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  Future<int> size([bool fromPinned = false]) {
    return _channel
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value as int);
  }

  @override
  Future<ThumbId> get(int id) {
    return _channel.invokeMethod("getCachedThumb", id).then(
      (value) {
        return ThumbId(
          id: id,
          path: (value as Map)["path"] as String,
          differenceHash: value["hash"] as int,
        );
      },
    );
  }

  @override
  void clear([bool fromPinned = false]) {
    _channel.invokeMethod("clearCachedThumbs", fromPinned);
  }

  @override
  void removeAll(List<int> id, [bool fromPinned = false]) {
    _channel.invokeMethod(
      "deleteCachedThumbs",
      {"ids": id, "fromPinned": fromPinned},
    );
  }

  @override
  Future<ThumbId> saveFromNetwork(String url, int id) {
    return _channel
        .invokeMethod("saveThumbNetwork", {"url": url, "id": id}).then(
      (value) => ThumbId(
        id: id,
        path: (value as Map)["path"] as String,
        differenceHash: value["hash"] as int,
      ),
    );
  }
}

class AndroidGalleryTrash implements GalleryTrash {
  const AndroidGalleryTrash();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  Future<int?> get thumbId {
    return _channel.invokeMethod("trashThumbId");
  }

  @override
  void addAll(List<String> uris) {
    _channel.invokeMethod("addToTrash", uris);
  }

  @override
  void removeAll(List<String> uris) {
    _channel.invokeMethod("removeFromTrash", uris);
  }

  @override
  void empty() {
    _channel.invokeMethod("emptyTrash");
  }
}
