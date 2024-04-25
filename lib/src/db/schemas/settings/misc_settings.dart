// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:isar/isar.dart";

part "misc_settings.g.dart";

enum ThemeType {
  systemAccent(),
  secretPink();

  const ThemeType();

  String translatedString(BuildContext context) => switch (this) {
        ThemeType.systemAccent =>
          AppLocalizations.of(context)!.enumThemeTypeSystemAccent,
        ThemeType.secretPink =>
          AppLocalizations.of(context)!.enumThemeTypeSecretPink,
      };
}

@collection
class MiscSettings {
  const MiscSettings({
    required this.filesExtendedActions,
    required this.animeAlwaysLoadFromNet,
    required this.favoritesThumbId,
    required this.themeType,
    required this.favoritesPageMode,
    required this.animeWatchingOrderReversed,
  });

  Id get id => 0;

  final bool filesExtendedActions;
  final bool animeAlwaysLoadFromNet;
  final int favoritesThumbId;

  final bool animeWatchingOrderReversed;

  @enumerated
  final ThemeType themeType;

  @enumerated
  final FilteringMode favoritesPageMode;

  MiscSettings copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
  }) =>
      MiscSettings(
        animeWatchingOrderReversed:
            animeWatchingOrderReversed ?? this.animeWatchingOrderReversed,
        themeType: themeType ?? this.themeType,
        animeAlwaysLoadFromNet:
            animeAlwaysLoadFromNet ?? this.animeAlwaysLoadFromNet,
        favoritesPageMode: favoritesPageMode ?? this.favoritesPageMode,
        filesExtendedActions: filesExtendedActions ?? this.filesExtendedActions,
        favoritesThumbId: favoritesThumbId ?? this.favoritesThumbId,
      );

  static MiscSettings get current =>
      Dbs.g.main.miscSettings.getSync(0) ??
      const MiscSettings(
        animeWatchingOrderReversed: false,
        animeAlwaysLoadFromNet: false,
        filesExtendedActions: false,
        themeType: ThemeType.systemAccent,
        favoritesThumbId: 0,
        favoritesPageMode: FilteringMode.tag,
      );

  static void setFilesExtendedActions(bool b) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings
          .putSync(current.copy(filesExtendedActions: b)),
    );
  }

  static void setFavoritesThumbId(int id) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings.putSync(current.copy(favoritesThumbId: id)),
    );
  }

  static void setFavoritesPageMode(FilteringMode favoritesPageMode) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings
          .putSync(current.copy(favoritesPageMode: favoritesPageMode)),
    );
  }

  static void setAnimeAlwaysLoadFromNet(bool animeAlwaysLoadFromNet) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings.putSync(
        current.copy(animeAlwaysLoadFromNet: animeAlwaysLoadFromNet),
      ),
    );
  }

  static void setAnimeWatchingOrderReversed(bool animeWatchingOrderReversed) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings.putSync(
        current.copy(animeWatchingOrderReversed: animeWatchingOrderReversed),
      ),
    );
  }

  static void setThemeType(ThemeType theme) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.miscSettings.putSync(current.copy(themeType: theme)),
    );
  }

  static StreamSubscription<MiscSettings?> watch(
    void Function(MiscSettings?) f, [
    bool fire = false,
  ]) {
    return Dbs.g.main.miscSettings
        .watchObject(0, fireImmediately: fire)
        .listen(f);
  }
}
