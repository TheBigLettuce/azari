// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";

part "misc_settings.g.dart";

@collection
class IsarMiscSettings extends MiscSettingsData {
  const IsarMiscSettings({
    required this.filesExtendedActions,
    required this.animeAlwaysLoadFromNet,
    required this.favoritesThumbId,
    required this.themeType,
    required this.favoritesPageMode,
    required this.animeWatchingOrderReversed,
  });

  Id get id => 0;

  @override
  final bool animeAlwaysLoadFromNet;

  @override
  final bool animeWatchingOrderReversed;

  @override
  @enumerated
  final FilteringMode favoritesPageMode;

  @override
  final int favoritesThumbId;

  @override
  final bool filesExtendedActions;

  @override
  @enumerated
  final ThemeType themeType;

  @override
  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
  }) =>
      IsarMiscSettings(
        animeWatchingOrderReversed:
            animeWatchingOrderReversed ?? this.animeWatchingOrderReversed,
        themeType: themeType ?? this.themeType,
        animeAlwaysLoadFromNet:
            animeAlwaysLoadFromNet ?? this.animeAlwaysLoadFromNet,
        favoritesPageMode: favoritesPageMode ?? this.favoritesPageMode,
        filesExtendedActions: filesExtendedActions ?? this.filesExtendedActions,
        favoritesThumbId: favoritesThumbId ?? this.favoritesThumbId,
      );
}
