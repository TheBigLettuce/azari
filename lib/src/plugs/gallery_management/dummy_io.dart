// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:developer";
import "dart:io";

import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

class DummyIoGalleryManagementApi extends DummyGalleryManagementApi {
  const DummyIoGalleryManagementApi();

  @override
  Future<void> move(MoveOp op) async {
    try {
      await Directory(joinAll([op.rootDir, op.targetDir])).create();
      await File(op.source).copy(
        joinAll([op.rootDir, op.targetDir, basename(op.source)]),
      );
      await File(op.source).delete();
    } catch (e, trace) {
      log("file mover", level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return;
  }

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
}
