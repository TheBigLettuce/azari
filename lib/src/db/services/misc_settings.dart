// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension MiscSettingsDataExt on MiscSettingsData {
  void save() => _currentDb.miscSettings.add(this);
  MiscSettingsService get s => _currentDb.miscSettings;
}

abstract interface class MiscSettingsService implements ServiceMarker {
  factory MiscSettingsService.db() => _currentDb.miscSettings;

  MiscSettingsData get current;

  void add(MiscSettingsData data);

  StreamSubscription<MiscSettingsData?> watch(
    void Function(MiscSettingsData?) f, [
    bool fire = false,
  ]);
}

enum ThemeType {
  systemAccent(),
  secretPink();

  const ThemeType();

  String translatedString(AppLocalizations l10n) => switch (this) {
        ThemeType.systemAccent => l10n.enumThemeTypeSystemAccent,
        ThemeType.secretPink => l10n.enumThemeTypeSecretPink,
      };
}

@immutable
abstract class MiscSettingsData {
  const MiscSettingsData();

  bool get filesExtendedActions;
  bool get animeAlwaysLoadFromNet;
  int get favoritesThumbId;
  bool get animeWatchingOrderReversed;
  ThemeType get themeType;
  FilteringMode get favoritesPageMode;
  String get randomVideosAddTags;
  RandomPostsOrder get randomVideosOrder;

  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
  });
}
