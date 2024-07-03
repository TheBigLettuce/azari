// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:logging/logging.dart";
import "package:path/path.dart";

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
      await Directory(joinAll([rootDir, targetDir])).create();
      await File(source).copy(
        joinAll([rootDir, targetDir, basename(source)]),
      );
      await File(source).delete();
    } catch (e, trace) {
      _log.severe("moveSingle", e, trace);
    }

    return;
  }

  @override
  Future<bool> exists(String filePath) => File(filePath).exists();

  @override
  void deleteAll(List<GalleryFile> selected) {}

  @override
  Future<void> rename(String path, String newName, [bool notify = true]) {
    throw UnimplementedError();
  }

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<GalleryFile> selected, {
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

class DummyIoGalleryManagementApi extends DummyGalleryManagementApi {
  const DummyIoGalleryManagementApi();

  @override
  FilesManagement get files => const IoFilesManagement();
}
