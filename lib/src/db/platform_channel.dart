// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/plugs/download_movers.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';

const MethodChannel _channel = MethodChannel("lol.bruh19.azari.gallery");

class PlatformFunctions {
  static void refreshFiles(String bucketId) {
    _channel.invokeMethod("refreshFiles", bucketId);
  }

  static Future loadThumbnails(List<int> thumbs) async {
    return _channel.invokeMethod("loadThumbnails", thumbs);
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
      return Colors.limeAccent;
    }
  }

  static void returnUri(String originalUri) {
    _channel.invokeMethod("returnUri", originalUri);
  }

  static void rename(String uri, String newName) {
    if (newName.isEmpty) {
      return;
    }

    _channel.invokeMethod("rename", {
      "uri": uri,
      "newName": newName,
    });
  }

  static void copyMoveFiles(String? chosen, String? chosenVolumeName,
      List<SystemGalleryDirectoryFileShrinked> selected,
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

  static void deleteFiles(List<SystemGalleryDirectoryFileShrinked> selected) {
    _channel.invokeMethod(
        "deleteFiles", selected.map((e) => e.originalUri).toList());
  }

  static Future<String?> chooseDirectory({bool temporary = false}) async {
    return _channel.invokeMethod<String>("chooseDirectory", temporary);
  }

  static void refreshGallery() {
    _channel.invokeMethod("refreshGallery");
  }

  static void move(MoveOp op) {
    _channel.invokeMethod("move",
        {"source": op.source, "rootUri": op.rootDir, "dir": op.targetDir});
  }

  static void share(String originalUri) {
    _channel.invokeMethod("shareMedia", originalUri);
  }

  const PlatformFunctions();
}
