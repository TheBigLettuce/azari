// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension SettingsDataExt on SettingsData {
  void save() => _currentDb.require<SettingsService>().add(this);
}

abstract interface class SettingsService implements RequiredService {
  const SettingsService();

  SettingsData get current;

  void add(SettingsData data);

  StreamSubscription<SettingsData> watch(
    void Function(SettingsData s) f, [
    bool fire = false,
  ]);

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  static Future<bool> chooseDirectory(
    void Function(String) onError,
    AppLocalizations l10n, {
    required GalleryService galleryServices,
  }) async {
    late final ({String formattedPath, String path}) resp;

    try {
      resp = (await galleryServices.chooseDirectory(l10n))!;
    } catch (e, trace) {
      Logger.root.severe("chooseDirectory", e, trace);
      onError(l10n.emptyResult);
      return false;
    }

    final current = _currentDb.require<SettingsService>().current;
    current
        .copy(
          path: current.path
              .copy(path: resp.path, pathDisplay: resp.formattedPath),
        )
        .save();

    return Future.value(true);
  }
}

mixin SettingsWatcherMixin<S extends StatefulWidget> on State<S> {
  SettingsService get settingsService;

  StreamSubscription<SettingsData>? _settingsEvents;

  late SettingsData settings;

  void onNewSettings(SettingsData newSettings) {}

  @override
  void initState() {
    super.initState();

    settings = settingsService.current;

    _settingsEvents?.cancel();
    _settingsEvents = settingsService.watch((newSettings) {
      onNewSettings(newSettings);

      setState(() {
        settings = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _settingsEvents?.cancel();

    super.dispose();
  }
}

extension SettingsPathEmptyExt on SettingsPath {
  bool get isEmpty => path.isEmpty;
  bool get isNotEmpty => path.isNotEmpty;
}

@immutable
abstract class SettingsPath {
  const SettingsPath();

  String get path;
  String get pathDisplay;

  SettingsPath copy({
    String? path,
    String? pathDisplay,
  });
}

enum ThemeType {
  main,
  systemAccent,
  pink;

  const ThemeType();

  String translatedString(AppLocalizations l10n) => switch (this) {
        main => "Default", // TODO: change
        ThemeType.systemAccent => l10n.enumThemeTypeSystemAccent,
        ThemeType.pink => l10n.enumThemeTypePink,
      };
}

@immutable
abstract class SettingsData {
  const SettingsData();

  SettingsPath get path;
  Booru get selectedBooru;
  DisplayQuality get quality;
  SafeMode get safeMode;
  bool get showWelcomePage;
  bool get extraSafeFilters;
  bool get sampleThumbnails;
  bool get filesExtendedActions;
  ThemeType get themeType;
  String get randomVideosAddTags;
  RandomPostsOrder get randomVideosOrder;

  SettingsData copy({
    bool? filesExtendedActions,
    ThemeType? themeType,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
    bool? extraSafeFilters,
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
    bool? sampleThumbnails,
  });
}
