// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';

const MethodChannel _channel = MethodChannel("lol.bruh19.azari.gallery");

/// Platform functions which are currently implemented.
/// Most of the methods here depend on the callbacks methods created by Pigeon.
class PlatformFunctions {
  static void refreshFiles(String bucketId) {
    _channel.invokeMethod("refreshFiles", bucketId);
  }

  static void refreshFilesMultiple(List<String> ids) {
    _channel.invokeMethod("refreshFilesMultiple", ids);
  }

  static Future<void> refreshFavorites(List<int> ids) {
    return _channel.invokeMethod("refreshFavorites", ids);
  }

  static Future<String> pickFileAndCopy(String outputDir) {
    return _channel
        .invokeMethod("pickFileAndCopy", outputDir)
        .then((value) => value!);
  }

  static void loadThumbnail(int thumb) {
    _channel.invokeMethod("loadThumbnail", thumb);
  }

  static Future<bool> requestManageMedia() {
    return _channel.invokeMethod("requestManageMedia").then((value) => value);
  }

  static Future<Color> accentColor() async {
    try {
      final int c = await _channel.invokeMethod("accentColor");
      return Color(c);
    } catch (e) {
      try {
        return (await DynamicColorPlugin.getAccentColor())!;
      } catch (_) {}
      return Colors.limeAccent;
    }
  }

  static void returnUri(String originalUri) {
    _channel.invokeMethod("returnUri", originalUri);
  }

  static void rename(String uri, String newName, {bool notify = true}) {
    if (newName.isEmpty) {
      return;
    }

    _channel.invokeMethod(
        "rename", {"uri": uri, "newName": newName, "notify": notify});
  }

  static void copyMoveFiles(String? chosen, String? chosenVolumeName,
      List<SystemGalleryDirectoryFile> selected,
      {required bool move, String? newDir}) {
    _channel.invokeMethod("copyMoveFiles", {
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
      "newDir": newDir != null
    });
  }

  static Future<int?> trashThumbId() {
    if (!Platform.isAndroid) {
      return Future.value(null);
    }
    return _channel.invokeMethod("trashThumbId");
  }

  static void deleteFiles(List<SystemGalleryDirectoryFile> selected) {
    _channel.invokeMethod(
        "deleteFiles", selected.map((e) => e.originalUri).toList());
  }

  static Future<SettingsPath?> chooseDirectory({bool temporary = false}) async {
    return _channel
        .invokeMethod("chooseDirectory", temporary)
        .then((value) => SettingsPath(
              path: value["path"],
              pathDisplay: value["pathDisplay"],
            ));
  }

  static void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
  }

  static Future<bool> manageMediaSupported() {
    return _channel.invokeMethod("manageMediaSupported").then((value) => value);
  }

  static Future<bool> manageMediaStatus() {
    return _channel.invokeMethod("manageMediaStatus").then((value) => value);
  }

  static void emptyTrash() {
    _channel.invokeMethod("emptyTrash");
  }

  static void move(MoveOp op) {
    _channel.invokeMethod("move",
        {"source": op.source, "rootUri": op.rootDir, "dir": op.targetDir});
  }

  static void shareMedia(String originalUri, {bool url = false}) {
    _channel.invokeMethod("shareMedia", {"uri": originalUri, "isUrl": url});
  }

  static Future<bool> moveInternal(String internalAppDir, List<String> uris) {
    return _channel.invokeMethod("moveInternal",
        {"dir": internalAppDir, "uris": uris}).then((value) => value ?? false);
  }

  static void refreshTrashed() {
    _channel.invokeMethod("refreshTrashed");
  }

  static void addToTrash(List<String> uris) {
    _channel.invokeMethod("addToTrash", uris);
  }

  static void removeFromTrash(List<String> uris) {
    _channel.invokeMethod("removeFromTrash", uris);
  }

  static Future<bool> moveFromInternal(
      String fromInternalFile, String toDir, String volume) {
    return _channel.invokeMethod("moveFromInternal", {
      "from": fromInternalFile,
      "to": toDir,
      "volume": volume
    }).then((value) => value ?? false);
  }

  static void preloadImage(String uri) {
    _channel.invokeMethod("preloadImage", uri);
  }

  static Future<int> thumbCacheSize([bool fromPinned = false]) {
    return _channel
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value);
  }

  static Future<ThumbId> getCachedThumb(int id) {
    return _channel.invokeMethod("getCachedThumb", id).then((value) =>
        ThumbId(id: id, path: value["path"], differenceHash: value["hash"]));
  }

  static void clearCachedThumbs([bool fromPinned = false]) {
    _channel.invokeMethod("clearCachedThumbs", fromPinned);
  }

  static void deleteCachedThumbs(List<int> id, [bool fromPinned = false]) {
    _channel.invokeMethod(
        "deleteCachedThumbs", {"ids": id, "fromPinned": fromPinned});
  }

  static Future<int> currentMediastoreVersion() {
    return _channel
        .invokeMethod("currentMediastoreVersion")
        .then((value) => value);
  }

  static Future<bool> currentNetworkStatus() {
    return _channel.invokeMethod("currentNetworkStatus").then((value) => value);
  }

  static Future<void> setWallpaper(int id) {
    return _channel.invokeMethod("setWallpaper", id);
  }

  static Future<ThumbId> saveThumbNetwork(String url, int id) {
    return _channel.invokeMethod("saveThumbNetwork", {
      "url": url,
      "id": id
    }).then((value) =>
        ThumbId(id: id, path: value["path"], differenceHash: value["hash"]));
  }

  const PlatformFunctions();
}

@immutable
class ThumbId {
  final int id;
  final String path;
  final int differenceHash;

  const ThumbId({
    required this.id,
    required this.path,
    required this.differenceHash,
  });
}
