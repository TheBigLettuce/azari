// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  @enumerated
  GridColumn picturesPerRow;
  bool listViewBooru;

  String path;
  @enumerated
  Booru selectedBooru;
  @enumerated
  DisplayQuality quality;
  @enumerated
  AspectRatio ratio;
  bool safeMode;

  GallerySettings gallerySettings;

  Settings(
      {required this.path,
      required this.selectedBooru,
      required this.quality,
      required this.listViewBooru,
      required this.picturesPerRow,
      required this.safeMode,
      required this.gallerySettings,
      required this.ratio});
  Settings copy(
      {String? path,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? listViewBooru,
      GridColumn? picturesPerRow,
      bool? safeMode,
      AspectRatio? ratio,
      GallerySettings? gallerySettings}) {
    return Settings(
        path: path ?? this.path,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        ratio: ratio ?? this.ratio,
        listViewBooru: listViewBooru ?? this.listViewBooru,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow,
        safeMode: safeMode ?? this.safeMode,
        gallerySettings: gallerySettings ?? this.gallerySettings);
  }

  Settings.empty()
      : path = "",
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        picturesPerRow = (Platform.isAndroid || Platform.isIOS)
            ? GridColumn.two
            : GridColumn.six,
        listViewBooru = false,
        safeMode = false,
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

const _kDanbooruPrefix = "d";
const _kGelbooruPrefix = "g";

enum Booru {
  gelbooru(string: "Gelbooru", prefix: _kGelbooruPrefix),
  danbooru(string: "Danbooru", prefix: _kDanbooruPrefix);

  final String string;
  final String prefix;

  const Booru({required this.string, required this.prefix});
}

Booru? chooseBooruPrefix(String prefix) => switch (prefix) {
      _kGelbooruPrefix => Booru.gelbooru,
      _kDanbooruPrefix => Booru.danbooru,
      String() => null,
    };

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
