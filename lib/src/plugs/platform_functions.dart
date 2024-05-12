// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/plugs/download_movers.dart";
import "package:gallery/src/plugs/gallery.dart";

@immutable
class ThumbId {
  const ThumbId({
    required this.id,
    required this.path,
    required this.differenceHash,
  });

  final int id;
  final String path;
  final int differenceHash;
}

abstract interface class PlatformApi {
  factory PlatformApi.current() => Platform.isAndroid
      ? const AndroidApiFunctions()
      : Platform.isLinux
          ? const LinuxApiFunctions()
          : const _DummyApiFunctions();

  Future<Color> accentColor();
  Future<void> setFullscreen(bool f);
  Future<void> setTitle(String windowTitle);

  Future<void> shareMedia(String originalUri, {bool url = false});
  Future<void> rename(String uri, String newName, [bool notify]);
  Future<void> setWallpaper(int id);
}

class _DummyApiFunctions implements PlatformApi {
  const _DummyApiFunctions();

  @override
  Future<Color> accentColor() => Future.value(Colors.indigo);

  @override
  Future<void> setFullscreen(bool f) => Future.value();

  @override
  Future<void> setTitle(String windowTitle) => Future.value();

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) =>
      Future.value();

  @override
  Future<void> setWallpaper(int id) => Future.value();
}

class LinuxApiFunctions implements PlatformApi {
  const LinuxApiFunctions();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  Future<Color> accentColor() async {
    try {
      return (await DynamicColorPlugin.getAccentColor())!;
    } catch (_) {
      return Colors.limeAccent;
    }
  }

  @override
  Future<void> setFullscreen(bool f) {
    if (f) {
      return _channel.invokeMethod("fullscreen");
    } else {
      _channel.invokeMethod("default_title");
      return _channel.invokeMethod("fullscreen_untoggle");
    }
  }

  @override
  Future<void> setTitle(String windowTitle) {
    return _channel.invokeMethod("set_title", windowTitle);
  }

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) {
    throw UnimplementedError();
  }

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) {
    // TODO: implement rename
    throw UnimplementedError();
  }

  @override
  Future<void> setWallpaper(int id) {
    // TODO: implement setWallpaper
    throw UnimplementedError();
  }
}

class AndroidApiFunctions implements PlatformApi {
  const AndroidApiFunctions();

  static const MethodChannel _channel =
      MethodChannel("lol.bruh19.azari.gallery");

  @override
  Future<void> setFullscreen(bool f) {
    if (f) {
      return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      return SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Future<void> setTitle(String windowTitle) => Future.value();

  void hideRecents(bool hide) {
    _channel.invokeMethod("hideRecents", hide);
  }

  void refreshFiles(String bucketId) {
    _channel.invokeMethod("refreshFiles", bucketId);
  }

  void refreshFilesMultiple(List<String> ids) {
    _channel.invokeMethod("refreshFilesMultiple", ids);
  }

  Future<void> refreshFavorites(List<int> ids) {
    return _channel.invokeMethod("refreshFavorites", ids);
  }

  Future<String> pickFileAndCopy(String outputDir) {
    return _channel
        .invokeMethod("pickFileAndCopy", outputDir)
        .then((value) => value as String);
  }

  void loadThumbnail(int thumb) {
    _channel.invokeMethod("loadThumbnail", thumb);
  }

  Future<bool> requestManageMedia() {
    return _channel
        .invokeMethod("requestManageMedia")
        .then((value) => value as bool);
  }

  @override
  Future<Color> accentColor() async {
    final int c = (await _channel.invokeMethod("accentColor")) as int;
    return Color(c);
  }

  void returnUri(String originalUri) {
    _channel.invokeMethod("returnUri", originalUri);
  }

  Future<void> rename(String uri, String newName, [bool notify = true]) {
    if (newName.isEmpty) {
      return Future.value();
    }

    return _channel.invokeMethod(
      "rename",
      {"uri": uri, "newName": newName, "notify": notify},
    );
  }

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

  Future<int?> trashThumbId() {
    if (!Platform.isAndroid) {
      return Future.value();
    }
    return _channel.invokeMethod("trashThumbId");
  }

  void deleteFiles(List<GalleryFile> selected) {
    _channel.invokeMethod(
      "deleteFiles",
      selected.map((e) => e.originalUri).toList(),
    );
  }

  Future<SettingsPath?> chooseDirectory({bool temporary = false}) async {
    return _channel.invokeMethod("chooseDirectory", temporary).then(
          (value) => SettingsPath.forCurrent(
            path: (value as Map<String, dynamic>)["path"] as String,
            pathDisplay: value["pathDisplay"] as String,
          ),
        );
  }

  void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
  }

  Future<bool> manageMediaSupported() {
    return _channel
        .invokeMethod("manageMediaSupported")
        .then((value) => value as bool);
  }

  Future<bool> manageMediaStatus() {
    return _channel
        .invokeMethod("manageMediaStatus")
        .then((value) => value as bool);
  }

  void emptyTrash() {
    _channel.invokeMethod("emptyTrash");
  }

  Future<void> move(MoveOp op) {
    return _channel.invokeMethod(
      "move",
      {"source": op.source, "rootUri": op.rootDir, "dir": op.targetDir},
    );
  }

  Future<void> shareMedia(String originalUri, {bool url = false}) {
    _channel.invokeMethod("shareMedia", {"uri": originalUri, "isUrl": url});

    return Future.value();
  }

  Future<bool> moveInternal(String internalAppDir, List<String> uris) {
    return _channel.invokeMethod(
      "moveInternal",
      {"dir": internalAppDir, "uris": uris},
    ).then((value) => (value as bool?) ?? false);
  }

  void refreshTrashed() {
    _channel.invokeMethod("refreshTrashed");
  }

  void addToTrash(List<String> uris) {
    _channel.invokeMethod("addToTrash", uris);
  }

  void removeFromTrash(List<String> uris) {
    _channel.invokeMethod("removeFromTrash", uris);
  }

  Future<bool> moveFromInternal(
    String fromInternalFile,
    String toDir,
    String volume,
  ) {
    return _channel.invokeMethod(
      "moveFromInternal",
      {"from": fromInternalFile, "to": toDir, "volume": volume},
    ).then((value) => (value as bool?) ?? false);
  }

  void preloadImage(String uri) {
    _channel.invokeMethod("preloadImage", uri);
  }

  Future<int> thumbCacheSize([bool fromPinned = false]) {
    return _channel
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value as int);
  }

  Future<ThumbId> getCachedThumb(int id) {
    return _channel.invokeMethod("getCachedThumb", id).then(
          (value) => ThumbId(
            id: id,
            path: (value as Map<String, dynamic>)["path"] as String,
            differenceHash: value["hash"] as int,
          ),
        );
  }

  void clearCachedThumbs([bool fromPinned = false]) {
    _channel.invokeMethod("clearCachedThumbs", fromPinned);
  }

  void deleteCachedThumbs(List<int> id, [bool fromPinned = false]) {
    _channel.invokeMethod(
      "deleteCachedThumbs",
      {"ids": id, "fromPinned": fromPinned},
    );
  }

  Future<int> currentMediastoreVersion() {
    return _channel
        .invokeMethod("currentMediastoreVersion")
        .then((value) => value as int);
  }

  Future<bool> currentNetworkStatus() {
    return _channel
        .invokeMethod("currentNetworkStatus")
        .then((value) => value as bool);
  }

  Future<void> setWallpaper(int id) {
    return _channel.invokeMethod("setWallpaper", id);
  }

  Future<ThumbId> saveThumbNetwork(String url, int id) {
    return _channel
        .invokeMethod("saveThumbNetwork", {"url": url, "id": id}).then(
      (value) => ThumbId(
        id: id,
        path: (value as Map<String, dynamic>)["path"] as String,
        differenceHash: value["hash"] as int,
      ),
    );
  }
}
