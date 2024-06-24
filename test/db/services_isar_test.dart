// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl_table/io.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/display_quality.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
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

    _settingsServiceTests(services);
  });

  group("MiscSettings service tests", () {
    setUp(() {
      services.miscSettings.clearStorageTest_();
    });

    _miscSettingsServiceTests(services);
  });
}

void _miscSettingsServiceTests(IoServicesImplTable services) {
  test("Combined MiscSettings test", () {});
}

void _settingsServiceTests(IoServicesImplTable services) {
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

  test("Settings.s.current and service.settings.current should be equal",
      tags: ["db"], () {
    final s = services.settings.current;

    expect(services.settings.current, equals(s.s.current));
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

    // showAnimeMangaPages
    {
      final s = services.settings.current;

      expect(s.showAnimeMangaPages, equals(false));

      final sCopy = s.copy(showAnimeMangaPages: true);

      expect(sCopy.showAnimeMangaPages, equals(true));

      sCopy.save();

      expect(services.settings.current.showAnimeMangaPages, equals(true));
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
