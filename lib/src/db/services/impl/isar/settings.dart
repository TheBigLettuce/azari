// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/services/settings.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/display_quality.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:meta/meta.dart';

@immutable
class IsarSettingsService implements SettingsService {
  const IsarSettingsService();

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  @override
  Future<bool> chooseDirectory(
    void Function(String) onError, {
    required String emptyResult,
    required String pickDirectory,
    required String validDirectory,
  }) async {
    late final SettingsPath resp;

    if (Platform.isAndroid) {
      try {
        resp = (await PlatformFunctions.chooseDirectory())!;
      } catch (e) {
        onError(emptyResult);
        return false;
      }
    } else {
      final r = await FilePicker.platform
          .getDirectoryPath(dialogTitle: pickDirectory);
      if (r == null) {
        onError(validDirectory);
        return false;
      }
      resp = IsarSettingsPath(path: r, pathDisplay: r);
    }

    current.copy(path: resp).save();

    return Future.value(true);
  }

  @override
  SettingsData get current =>
      Dbs.g.main.isarSettings.getSync(0) ??
      const IsarSettings(
        showWelcomePage: true,
        path: IsarSettingsPath(),
        selectedBooru: Booru.gelbooru,
        quality: DisplayQuality.sample,
        safeMode: SafeMode.normal,
      );

  @override
  StreamSubscription<SettingsData?> watch(void Function(SettingsData? s) f,
      {bool fire = false}) {
    return Dbs.g.main.isarSettings
        .watchObject(0, fireImmediately: fire)
        .listen(f);
  }
}
