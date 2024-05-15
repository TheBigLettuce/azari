// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension SettingsDataExt on SettingsData {
  void save() => SettingsService.db().add(this);
}

abstract class SettingsPath {
  const SettingsPath();

  String get path;
  String get pathDisplay;

  bool get isEmpty => path.isEmpty;
  bool get isNotEmpty => path.isNotEmpty;

  static SettingsPath forCurrent({
    required String path,
    required String pathDisplay,
  }) =>
      _currentDb.settingsPathForCurrent(
        path: path,
        pathDisplay: pathDisplay,
      );
}

abstract class SettingsData {
  const SettingsData({
    required this.selectedBooru,
    required this.quality,
    required this.safeMode,
    required this.showWelcomePage,
  });

  SettingsPath get path;
  @enumerated
  final Booru selectedBooru;
  @enumerated
  final DisplayQuality quality;
  @enumerated
  final SafeMode safeMode;

  final bool showWelcomePage;

  @ignore
  SettingsService get s => _currentDb.settings;

  SettingsData copy({
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
  });
}

abstract interface class SettingsService implements ServiceMarker {
  const SettingsService();

  factory SettingsService.db() => _currentDb.settings;

  SettingsData get current;

  void add(SettingsData data);

  StreamSubscription<SettingsData?> watch(void Function(SettingsData? s) f);

  Future<bool> chooseDirectory(
    void Function(String) onError, {
    required String emptyResult,
    required String pickDirectory,
    required String validDirectory,
  });
}
