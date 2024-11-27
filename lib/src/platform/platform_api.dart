// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/platform/api_functions/io.dart"
    if (dart.library.html) "package:azari/src/platform/api_functions/web.dart";
import "package:flutter/material.dart";

abstract interface class PlatformApi {
  factory PlatformApi() {
    if (_api != null) {
      return _api!;
    }

    return _api = getApi();
  }

  const factory PlatformApi.dummy() = _DummyPlatformApi;

  static PlatformApi? _api;

  Future<Color> get accentColor;
  Future<String> get version;
  bool get authSupported;

  WindowApi get window;

  List<PermissionController> get requiredPermissions;

  Future<void> setFullscreen(bool f);

  Future<void> shareMedia(String originalUri, {bool url = false});
  Future<void> setWallpaper(int id);
  Future<void> setWakelock(bool lockWake);

  void closeApp([Object? returnValue]);
}

abstract interface class WindowApi {
  const factory WindowApi.dummy() = _DummyWindowApi;

  void setTitle(String n);
  void setProtected(bool enabled);
}

abstract interface class PermissionController {
  Object get token;
  Future<bool> get granted;
  Future<bool> get enabled;

  (String, IconData) translatedNameIcon(AppLocalizations l10n);

  Future<bool> request();
}

class _DummyWindowApi implements WindowApi {
  const _DummyWindowApi();

  @override
  void setProtected(bool enabled) {}

  @override
  void setTitle(String n) {}
}

class _DummyPlatformApi implements PlatformApi {
  const _DummyPlatformApi();

  @override
  List<PermissionController> get requiredPermissions => const [];

  @override
  Future<Color> get accentColor => Future.value(Colors.indigo);

  @override
  Future<void> setFullscreen(bool f) => Future.value();

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  Future<void> setWallpaper(int id) => Future.value();

  @override
  Future<String> get version => Future.value("");

  @override
  Future<void> setWakelock(bool lockWake) => Future.value();

  @override
  WindowApi get window => const WindowApi.dummy();

  @override
  void closeApp([Object? _]) {}

  @override
  bool get authSupported => false;
}
