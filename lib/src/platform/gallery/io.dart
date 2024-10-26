// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;

import "package:azari/src/platform/gallery/android/android_gallery.dart";
import "package:azari/src/platform/gallery/dummy.dart";
import "package:azari/src/platform/gallery/linux/impl.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;

GalleryApi getApi() {
  if (io.Platform.isAndroid) {
    return const AndroidGalleryApi();
  } else if (io.Platform.isLinux) {
    return const LinuxGalleryApi();
  }

  return DummyGalleryApi();
}

void initApi() {
  if (io.Platform.isAndroid) {
    initalizeAndroidGallery();
  }
}

class IoFilesManagement implements FilesManagement {
  const IoFilesManagement();

  static final _log = Logger("IoFilesManagement");

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) async {
    try {
      await io.Directory(path.joinAll([rootDir, targetDir])).create();
      await io.File(source).copy(
        path.joinAll([rootDir, targetDir, path.basename(source)]),
      );
      await io.File(source).delete();
    } catch (e, trace) {
      _log.severe("moveSingle", e, trace);
    }

    return;
  }

  @override
  Future<bool> exists(String filePath) => io.File(filePath).exists();

  @override
  void deleteAll(List<File> selected) {}

  @override
  Future<void> rename(String path, String newName, [bool notify = true]) {
    throw UnimplementedError();
  }

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) {
    return Future.value();
  }

  @override
  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) {
    throw UnimplementedError();
  }
}
