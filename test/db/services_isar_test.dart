// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;

import "package:azari/src/db/services/impl/isar/impl.dart";
import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:flutter_test/flutter_test.dart";
import "package:isar/isar.dart";
import "package:path/path.dart" as path;

void main() {
  late final IoServices services;

  final dir =
      io.Directory(io.Directory.systemTemp.path).createTempSync("azariDbTests");

  final tempDir = io.Directory(path.join(dir.path, "temp"))..createSync();

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    services = IoServices();

    await initalizeIsarDb(
      AppInstanceType.full,
      services,
      dir.path,
      tempDir.path,
    );
  });

  tearDownAll(() {
    dir.deleteSync(recursive: true);
  });

  group("Settings service tests", () {
    setUp(() {
      services.settings.clearStorageTest_();
    });

    _settingsServiceTests(services);
  });

  group("MiscSettings service tests", () {
    setUp(() {
      services.miscSettings.clearStorageTest_();
    });

    _miscSettingsServiceTests(services);
  });
}

void _miscSettingsServiceTests(IoServices services) {
  test("Combined MiscSettings test", () {});
}

void _settingsServiceTests(IoServices services) {
  test("SettingsPath", tags: ["db"], () {
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

      final pathCopy = s.path.copy(path: newPath, pathDisplay: newPathDisplay);

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

  test("Combined Settings test", tags: ["db"], () {
    // extraSafeFilters
    {
      final s = services.settings.current;

      expect(s.extraSafeFilters, equals(true));

      final sCopy = s.copy(extraSafeFilters: false);

      expect(sCopy.extraSafeFilters, equals(false));

      sCopy.save();

      expect(services.settings.current.extraSafeFilters, equals(false));
    }

    {
      final s = services.settings.current;

      expect(s.quality, equals(DisplayQuality.sample));

      final sCopy = s.copy(quality: DisplayQuality.original);

      expect(sCopy.quality, equals(DisplayQuality.original));

      sCopy.save();

      expect(
        services.settings.current.quality,
        equals(DisplayQuality.original),
      );
    }

    // safeMode
    {
      final s = services.settings.current;

      expect(s.safeMode, equals(SafeMode.normal));

      final sCopy = s.copy(safeMode: SafeMode.relaxed);

      expect(sCopy.safeMode, equals(SafeMode.relaxed));

      sCopy.save();

      expect(services.settings.current.safeMode, equals(SafeMode.relaxed));

      {
        final sCopy = s.copy(safeMode: SafeMode.none);

        expect(sCopy.safeMode, SafeMode.none);

        sCopy.save();

        expect(services.settings.current.safeMode, equals(SafeMode.none));
      }
    }

    // selectedBooru
    {
      final s = services.settings.current;

      expect(s.selectedBooru, equals(Booru.gelbooru));

      final sCopy = s.copy(selectedBooru: Booru.danbooru);

      expect(sCopy.selectedBooru, equals(Booru.danbooru));

      sCopy.save();

      expect(services.settings.current.selectedBooru, equals(Booru.danbooru));
    }

    // showWelcomePage
    {
      final s = services.settings.current;

      expect(s.showWelcomePage, equals(true));

      final sCopy = s.copy(showWelcomePage: false);

      expect(sCopy.showWelcomePage, equals(false));

      sCopy.save();

      expect(services.settings.current.showWelcomePage, equals(false));
    }
  });
}
