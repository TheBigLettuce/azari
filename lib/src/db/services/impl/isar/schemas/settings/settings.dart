// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
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
  @ignore
  bool get isEmpty => path.isEmpty;

  @override
  @ignore
  bool get isNotEmpty => path.isNotEmpty;
}

@collection
class IsarSettings extends SettingsData {
  const IsarSettings({
    required this.path,
    required super.selectedBooru,
    required super.quality,
    required super.safeMode,
    required super.showWelcomePage,
    required super.showAnimeMangaPages,
    required super.extraSafeFilters,
  });

  Id get id => 0;

  @override
  final IsarSettingsPath path;

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
