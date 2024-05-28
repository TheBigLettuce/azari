// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:flutter/services.dart";
import "package:gallery/src/db/services/services.dart";
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
  Future<String> ensureDownloadDirectoryExists(String site) async {
    final downloadtd = Directory(
      joinAll([(await getTemporaryDirectory()).path, "downloads"]),
    );

    final dirpath = joinAll([downloadtd.path, site]);
    await downloadtd.create();

    await Directory(dirpath).create();

    return dirpath;
  }

  @override
  Future<bool> fileExists(String filePath) => File(filePath).exists();

  @override
  void refreshFiles(String bucketId, SortingMode sortingMode) {
    _channel.invokeMethod("refreshFiles", {
      "bucketId": bucketId,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  @override
  void refreshFilesMultiple(List<String> ids, SortingMode sortingMode) {
    _channel.invokeMethod("refreshFilesMultiple", {
      "ids": ids,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  @override
  Future<void> refreshFavorites(List<int> ids, SortingMode sortingMode) {
    return _channel.invokeMethod("refreshFavorites", {
      "ids": ids,
      "sort": sortingMode.sortingIdAndroid,
    });
  }

  @override
  Future<String> pickFileAndCopy(String outputDir) {
    return _channel
        .invokeMethod("pickFileAndCopy", outputDir)
        .then((value) => value as String);
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

  @override
  void copyMoveFiles(
    String? chosen,
    String? chosenVolumeName,
    List<GalleryFile> selected, {
    required bool move,
    String? newDir,
  }) {
    _channel.invokeMethod(
      "copyMoveFiles",
      {
        "dest": chosen ?? newDir,
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
        "newDir": newDir != null,
      },
    );
  }

  @override
  Future<int?> trashThumbId() {
    return _channel.invokeMethod("trashThumbId");
  }

  @override
  void deleteFiles(List<GalleryFile> selected) {
    _channel.invokeMethod(
      "deleteFiles",
      selected.map((e) => e.originalUri).toList(),
    );
  }

  @override
  Future<SettingsPath?> chooseDirectory({bool temporary = false}) async {
    return _channel.invokeMethod("chooseDirectory", temporary).then(
          (value) => objFactory.makeSettingsPath(
            path: (value as Map)["path"] as String,
            pathDisplay: value["pathDisplay"] as String,
          ),
        );
  }

  @override
  void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
  }

  @override
  void emptyTrash() {
    _channel.invokeMethod("emptyTrash");
  }

  @override
  Future<void> move(MoveOp op) {
    return _channel.invokeMethod(
      "move",
      {"source": op.source, "rootUri": op.rootDir, "dir": op.targetDir},
    );
  }

  @override
  void refreshTrashed() {
    _channel.invokeMethod("refreshTrashed");
  }

  @override
  void addToTrash(List<String> uris) {
    _channel.invokeMethod("addToTrash", uris);
  }

  @override
  void removeFromTrash(List<String> uris) {
    _channel.invokeMethod("removeFromTrash", uris);
  }

  @override
  Future<int> thumbCacheSize([bool fromPinned = false]) {
    return _channel
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value as int);
  }

  @override
  Future<ThumbId> getCachedThumb(int id) {
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
  void clearCachedThumbs([bool fromPinned = false]) {
    _channel.invokeMethod("clearCachedThumbs", fromPinned);
  }

  @override
  void deleteCachedThumbs(List<int> id, [bool fromPinned = false]) {
    _channel.invokeMethod(
      "deleteCachedThumbs",
      {"ids": id, "fromPinned": fromPinned},
    );
  }

  @override
  Future<ThumbId> saveThumbNetwork(String url, int id) {
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
