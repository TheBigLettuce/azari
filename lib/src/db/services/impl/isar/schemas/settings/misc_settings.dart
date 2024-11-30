// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:isar/isar.dart";

part "misc_settings.g.dart";

@collection
class IsarMiscSettings extends MiscSettingsData {
  const IsarMiscSettings({
    required this.filesExtendedActions,
    required this.favoritesThumbId,
    required this.themeType,
    required this.favoritesPageMode,
    required this.randomVideosAddTags,
    required this.randomVideosOrder,
  });

  Id get id => 0;

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
  final String randomVideosAddTags;

  @override
  @enumerated
  final RandomPostsOrder randomVideosOrder;

  @override
  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    FilteringMode? favoritesPageMode,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
  }) =>
      IsarMiscSettings(
        themeType: themeType ?? this.themeType,
        favoritesPageMode: favoritesPageMode ?? this.favoritesPageMode,
        filesExtendedActions: filesExtendedActions ?? this.filesExtendedActions,
        favoritesThumbId: favoritesThumbId ?? this.favoritesThumbId,
        randomVideosAddTags: randomVideosAddTags ?? this.randomVideosAddTags,
        randomVideosOrder: randomVideosOrder ?? this.randomVideosOrder,
      );
}
