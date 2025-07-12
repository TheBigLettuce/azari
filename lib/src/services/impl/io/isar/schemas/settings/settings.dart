// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "settings.g.dart";

const int _safeFilters = 0x0001;
const int _sampleThumbnails = 0x0002;
const int _welcomePage = 0x0004;
const int _filesExtendedActions = 0x0008;
const int _exceptionAlerts = 0x0010;

@embedded
class IsarSettingsPath implements SettingsPath {
  const IsarSettingsPath({this.path = "", this.pathDisplay = ""});

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

@Collection(
  ignore: {
    "extraSafeFilters",
    "sampleThumbnails",
    "exceptionAlerts",
    "filesExtendedActions",
  },
)
class IsarSettings extends SettingsData {
  const IsarSettings({
    required this.flags,
    required this.path,
    required this.selectedBooru,
    required this.quality,
    required this.safeMode,
    required this.themeType,
    required this.randomVideosAddTags,
    required this.randomVideosOrder,
  });

  const IsarSettings.empty()
    : flags = _safeFilters | _welcomePage,
      path = const IsarSettingsPath(),
      selectedBooru = Booru.danbooru,
      quality = DisplayQuality.sample,
      safeMode = SafeMode.normal,
      randomVideosAddTags = "",
      randomVideosOrder = RandomPostsOrder.latest,
      themeType = ThemeType.systemAccent;

  Id get id => 0;

  @override
  bool get extraSafeFilters => (flags & _safeFilters) == _safeFilters;

  @override
  bool get sampleThumbnails => (flags & _sampleThumbnails) == _sampleThumbnails;

  @override
  bool get exceptionAlerts => (flags & _exceptionAlerts) == _exceptionAlerts;

  @override
  bool get filesExtendedActions =>
      (flags & _filesExtendedActions) == _filesExtendedActions;

  final int flags;

  @override
  final IsarSettingsPath path;

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
  @enumerated
  final ThemeType themeType;

  @override
  final String randomVideosAddTags;

  @override
  @enumerated
  final RandomPostsOrder randomVideosOrder;

  @override
  IsarSettings copy({
    bool? extraSafeFilters,
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? exceptionAlerts,
    bool? sampleThumbnails,
    bool? filesExtendedActions,
    ThemeType? themeType,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
  }) {
    final safeFiltersValue =
        (extraSafeFilters != null && extraSafeFilters) ||
            (extraSafeFilters == null && this.extraSafeFilters)
        ? _safeFilters
        : 0;
    final welcomePageValue =
        (exceptionAlerts != null && exceptionAlerts) ||
            (exceptionAlerts == null && this.exceptionAlerts)
        ? _exceptionAlerts
        : 0;
    final sampleValue =
        (sampleThumbnails != null && sampleThumbnails) ||
            (sampleThumbnails == null && this.sampleThumbnails)
        ? _sampleThumbnails
        : 0;
    final filesExtendedActionsValue =
        (filesExtendedActions != null && filesExtendedActions) ||
            (filesExtendedActions == null && this.filesExtendedActions)
        ? _filesExtendedActions
        : 0;

    return IsarSettings(
      flags:
          safeFiltersValue |
          welcomePageValue |
          sampleValue |
          filesExtendedActionsValue,
      path: (path as IsarSettingsPath?) ?? this.path,
      selectedBooru: selectedBooru ?? this.selectedBooru,
      quality: quality ?? this.quality,
      safeMode: safeMode ?? this.safeMode,
      themeType: themeType ?? this.themeType,
      randomVideosAddTags: randomVideosAddTags ?? this.randomVideosAddTags,
      randomVideosOrder: randomVideosOrder ?? this.randomVideosOrder,
    );
  }
}
