// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension MiscSettingsDataExt on MiscSettingsData {
  void maybeSave() => _currentDb.get<MiscSettingsService>()?.add(this);
}

abstract interface class MiscSettingsService implements ServiceMarker {
  MiscSettingsData get current;

  void add(MiscSettingsData data);

  StreamSubscription<MiscSettingsData> watch(
    void Function(MiscSettingsData) f, [
    bool fire = false,
  ]);
}

mixin MiscSettingsWatcherMixin<S extends StatefulWidget> on State<S> {
  MiscSettingsService? get miscSettingsService;

  StreamSubscription<MiscSettingsData>? _miscSettingsEvents;

  late MiscSettingsData? miscSettings;

  void onNewMiscSettings(MiscSettingsData newSettings) {}

  @override
  void initState() {
    super.initState();

    miscSettings = miscSettingsService?.current;

    _miscSettingsEvents?.cancel();
    _miscSettingsEvents = miscSettingsService?.watch((newSettings) {
      onNewMiscSettings(newSettings);

      setState(() {
        miscSettings = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _miscSettingsEvents?.cancel();

    super.dispose();
  }
}

enum ThemeType {
  systemAccent(),
  pink();

  const ThemeType();

  String translatedString(AppLocalizations l10n) => switch (this) {
        ThemeType.systemAccent => l10n.enumThemeTypeSystemAccent,
        ThemeType.pink => l10n.enumThemeTypePink,
      };
}

@immutable
abstract class MiscSettingsData {
  const MiscSettingsData();

  bool get filesExtendedActions;
  int get favoritesThumbId;
  ThemeType get themeType;
  FilteringMode get favoritesPageMode;
  String get randomVideosAddTags;
  RandomPostsOrder get randomVideosOrder;

  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    FilteringMode? favoritesPageMode,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
  });
}
