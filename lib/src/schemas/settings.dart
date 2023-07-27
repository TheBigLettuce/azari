// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';

import '../booru/interface.dart';

part 'settings.g.dart';

@collection
class Settings {
  final Id id = 0;

  @enumerated
  final GridColumn picturesPerRow;
  final bool listViewBooru;

  final String path;
  @enumerated
  final Booru selectedBooru;
  @enumerated
  final DisplayQuality quality;
  @enumerated
  final AspectRatio ratio;
  final bool safeMode;

  final bool expensiveHash;

  final bool saveTagsOnlyOnDownload;

  final bool autoRefresh;
  final int autoRefreshMicroseconds;
  final GallerySettings gallerySettings;

  const Settings(
      {required this.path,
      required this.selectedBooru,
      required this.quality,
      required this.autoRefresh,
      required this.autoRefreshMicroseconds,
      required this.listViewBooru,
      required this.picturesPerRow,
      required this.safeMode,
      required this.expensiveHash,
      required this.saveTagsOnlyOnDownload,
      required this.gallerySettings,
      required this.ratio});
  Settings copy(
      {String? path,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? listViewBooru,
      GridColumn? picturesPerRow,
      bool? autoRefresh,
      int? autoRefreshMicroseconds,
      bool? saveTagsOnlyOnDownload,
      bool? expensiveHash,
      bool? safeMode,
      AspectRatio? ratio,
      GallerySettings? gallerySettings}) {
    return Settings(
        expensiveHash: expensiveHash ?? this.expensiveHash,
        path: path ?? this.path,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        saveTagsOnlyOnDownload:
            saveTagsOnlyOnDownload ?? this.saveTagsOnlyOnDownload,
        ratio: ratio ?? this.ratio,
        autoRefresh: autoRefresh ?? this.autoRefresh,
        autoRefreshMicroseconds:
            autoRefreshMicroseconds ?? this.autoRefreshMicroseconds,
        listViewBooru: listViewBooru ?? this.listViewBooru,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow,
        safeMode: safeMode ?? this.safeMode,
        gallerySettings: gallerySettings ?? this.gallerySettings);
  }

  Settings.empty()
      : path = "",
        expensiveHash = false,
        autoRefresh = false,
        saveTagsOnlyOnDownload = true,
        autoRefreshMicroseconds = 1.hours.inMicroseconds,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        picturesPerRow = (Platform.isAndroid || Platform.isIOS)
            ? GridColumn.two
            : GridColumn.six,
        listViewBooru = false,
        safeMode = true,
        gallerySettings = GallerySettings()
          ..directoryAspectRatio = AspectRatio.zeroSeven
          ..directoryColumns = Platform.isAndroid || Platform.isIOS
              ? GridColumn.two
              : GridColumn.six
          ..hideDirectoryName = false
          ..filesAspectRatio = AspectRatio.oneFive
          ..filesColumns = Platform.isAndroid || Platform.isIOS
              ? GridColumn.three
              : GridColumn.six
          ..hideFileName = true,
        ratio = AspectRatio.one;
}

@embedded
class GallerySettings {
  bool? hideDirectoryName;
  @Enumerated(EnumType.ordinal32)
  AspectRatio? directoryAspectRatio;
  @Enumerated(EnumType.ordinal32)
  GridColumn? directoryColumns;
  bool? hideFileName;
  @Enumerated(EnumType.ordinal32)
  AspectRatio? filesAspectRatio;
  @Enumerated(EnumType.ordinal32)
  GridColumn? filesColumns;

  GallerySettings copy(
          {bool? hideDirectoryName,
          bool? hideFileName,
          AspectRatio? filesAspectRatio,
          AspectRatio? directoryAspectRatio,
          GridColumn? filesColumns,
          GridColumn? directoryColumns}) =>
      GallerySettings()
        ..hideDirectoryName = hideDirectoryName ?? this.hideDirectoryName
        ..hideFileName = hideFileName ?? this.hideFileName
        ..directoryAspectRatio =
            directoryAspectRatio ?? this.directoryAspectRatio
        ..filesAspectRatio = filesAspectRatio ?? this.filesAspectRatio
        ..filesColumns = filesColumns ?? this.filesColumns
        ..directoryColumns = directoryColumns ?? this.directoryColumns;
}

enum DisplayQuality {
  original("Original"),
  sample("Sample");

  final String string;

  const DisplayQuality(this.string);
}

enum GridColumn {
  two(2),
  three(3),
  four(4),
  five(5),
  six(6);

  final int number;

  const GridColumn(this.number);
}

enum AspectRatio {
  one(1.0),
  zeroFive(0.5),
  zeroSeven(0.7),
  oneTwo(1.2),
  oneFive(1.5);

  final double value;
  const AspectRatio(this.value);
}
