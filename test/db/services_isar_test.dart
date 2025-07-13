// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;
import "dart:ui";

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/impl/io/isar/impl.dart";
import "package:azari/src/services/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:isar/isar.dart";
import "package:path/path.dart" as path;

class PlatformApiDummy implements PlatformApi {
  const PlatformApiDummy();

  @override
  AppApi get app => const AppApiDummy();

  @override
  FilesApi? get files => null;

  @override
  GalleryApi? get gallery => null;

  @override
  NetworkStatusApi? get network => null;

  @override
  NotificationApi? get notifications => null;

  @override
  ThumbsApi? get thumbs => null;

  @override
  WindowApi? get window => null;
}

class AppApiDummy implements AppApi {
  const AppApiDummy();
  @override
  Color get accentColor => const Color(0xff6d5e0f);

  @override
  bool get canAuthBiometric => false;

  @override
  void close([Object? returnValue]) {}

  @override
  Stream<NotificationRouteEvent> get notificationEvents => const Stream.empty();

  @override
  List<PermissionController> get requiredPermissions => const [];

  @override
  Future<void> setWallpaper(int id) => Future.value();

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  String get version => "";

  @override
  bool get canOpenBy => false;

  @override
  Future<void> openSettingsOpenBy() => Future.value();
}

void main() {
  late final IoServices services;

  final dir = io.Directory(
    io.Directory.systemTemp.path,
  ).createTempSync("azariDbTests");

  final tempDir = io.Directory(path.join(dir.path, "temp"))..createSync();

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    services = IoServices.newTests(const PlatformApiDummy());

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

  // group("MiscSettings service tests", () {
  //   setUp(() {
  //     services.settings.clearStorageTest_();
  //   });

  //   _miscSettingsServiceTests(services);
  // });
}

// void _miscSettingsServiceTests(IoServices services) {
//   test("Combined MiscSettings test", () {});
// }

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

      final sCopy = s.copy(
        path: s.path.copy(path: "", pathDisplay: ""),
      );

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

      expect(s.exceptionAlerts, equals(true));

      final sCopy = s.copy(exceptionAlerts: false);

      expect(sCopy.exceptionAlerts, equals(false));

      sCopy.save();

      expect(services.settings.current.exceptionAlerts, equals(false));
    }
  });
}
