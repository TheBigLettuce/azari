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
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/thumbnail.dart';
import 'package:isar/isar.dart';

import '../db/initalize_db.dart';

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

  static void refreshFavorites(List<int> ids) {
    _channel.invokeMethod("refreshFavorites", ids);
  }

  static Future<String> pickFileAndCopy(String outputDir) {
    return _channel
        .invokeMethod("pickFileAndCopy", outputDir)
        .then((value) => value!);
  }

  static void loadThumbnail(int thumb) {
    _channel.invokeMethod("loadThumbnail", thumb);
  }

  static void requestManageMedia() {
    _channel.invokeMethod("requestManageMedia");
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

  static Future<String?> chooseDirectory({bool temporary = false}) async {
    return _channel.invokeMethod<String>("chooseDirectory", temporary);
  }

  static void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
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

  static Future<ThumbId> getThumbDirectly(int id) {
    return _channel.invokeMethod("getThumbDirectly", id).then((value) =>
        ThumbId(id: id, thumb: value["data"], differenceHash: value["hash"]));
  }

  static Future<ThumbId> getThumbNetwork(String url, int id) {
    return _channel.invokeMethod("getThumbNetwork", url).then((value) =>
        ThumbId(id: id, thumb: value["data"], differenceHash: value["hash"]));
  }

  const PlatformFunctions();
}

class ThumbId {
  final int id;
  final Uint8List thumb;
  final int differenceHash;

  const ThumbId(
      {required this.id, required this.thumb, required this.differenceHash});

  static void addThumbnailsToDb(List<ThumbId> l) {
    if (Dbs.g.thumbnail!.thumbnails.countSync() >= 3000) {
      Dbs.g.thumbnail!.writeTxnSync(() {
        Dbs.g.thumbnail!.thumbnails
            .where()
            .sortByUpdatedAt()
            .limit(l.length)
            .deleteAllSync();
      });
    }

    Dbs.g.thumbnail!.writeTxnSync(() {
      Dbs.g.thumbnail!.thumbnails.putAllSync(l
          .map(
              (e) => Thumbnail(e.id, DateTime.now(), e.thumb, e.differenceHash))
          .toList());
    });
  }
}
