// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/display_quality.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:isar/isar.dart";

part "settings.g.dart";

@embedded
class IsarSettingsPath implements SettingsPath {
  const IsarSettingsPath({
    this.path = "",
    this.pathDisplay = "",
  });

  @override
  final String path;
  @override
  final String pathDisplay;

  @override
  SettingsPath copy({String? path, String? pathDisplay}) => IsarSettingsPath(
        path: path ?? this.path,
        pathDisplay: pathDisplay ?? this.pathDisplay,
      );
}

@collection
class IsarSettings extends SettingsData {
  const IsarSettings({
    required this.path,
    required this.selectedBooru,
    required this.quality,
    required this.safeMode,
    required this.showWelcomePage,
    required this.showAnimeMangaPages,
    required this.extraSafeFilters,
  });

  Id get id => 0;

  @override
  final IsarSettingsPath path;

  @override
  final bool extraSafeFilters;

  @override
  @enumerated
  final DisplayQuality quality;

  @override
  @enumerated
  final SafeMode safeMode;

  @override
  @enumerated
  final Booru selectedBooru;

  @override
  final bool showAnimeMangaPages;

  @override
  final bool showWelcomePage;

  @override
  IsarSettings copy({
    bool? extraSafeFilters,
    bool? showAnimeMangaPages,
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
  }) {
    return IsarSettings(
      extraSafeFilters: extraSafeFilters ?? this.extraSafeFilters,
      showAnimeMangaPages: showAnimeMangaPages ?? this.showAnimeMangaPages,
      showWelcomePage: showWelcomePage ?? this.showWelcomePage,
      path: (path as IsarSettingsPath?) ?? this.path,
      selectedBooru: selectedBooru ?? this.selectedBooru,
      quality: quality ?? this.quality,
      safeMode: safeMode ?? this.safeMode,
    );
  }
}
