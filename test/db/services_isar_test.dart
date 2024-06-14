// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl_table/io.dart";
import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";
import "package:path/path.dart" as path;

void main() {
  late final IoServicesImplTable services;

  final dir =
      Directory(Directory.systemTemp.path).createTempSync("azariDbTests");

  final tempDir = Directory(path.join(dir.path, "temp"))..createSync();

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    services = IoServicesImplTable();

    print("test db dir: $dir");

    await initalizeIsarDb(false, services, dir.path, tempDir.path);
  });

  tearDownAll(() {
    dir.deleteSync(recursive: true);
  });

  group("Settings service tests", () {
    setUp(() {
      services.settings.clearStorageTest_();
    });

    test("SettingsPath", () {
      const newPath = "path";
      const newPathDisplay = "display";

      void comparePathsAndEmpty(
        SettingsPath settingsPath,
        String path,
        String pathDisplay,
      ) {
        expect(settingsPath.path, equals(path));
        expect(settingsPath.pathDisplay, equals(pathDisplay));

        expect(settingsPath.isEmpty, equals(path.isEmpty));
        expect(settingsPath.isNotEmpty, equals(path.isNotEmpty));
      }

      {
        final s = services.settings.current;

        // ensure that path is empty when the db is only just been created
        // or cleared
        comparePathsAndEmpty(s.path, "", "");
      }

      {
        final s = services.settings.current;

        final pathCopy =
            s.path.copy(path: newPath, pathDisplay: newPathDisplay);

        comparePathsAndEmpty(pathCopy, newPath, newPathDisplay);

        final sCopy = s.copy(path: pathCopy);

        comparePathsAndEmpty(sCopy.path, newPath, newPathDisplay);

        // save the copy to the db
        sCopy.save();
      }

      {
        final s = services.settings.current;

        comparePathsAndEmpty(s.path, newPath, newPathDisplay);

        final sCopy = s.copy(path: s.path.copy(path: "", pathDisplay: ""));

        comparePathsAndEmpty(sCopy.path, "", "");

        sCopy.save();

        comparePathsAndEmpty(services.settings.current.path, "", "");
      }
    });
  });
}
