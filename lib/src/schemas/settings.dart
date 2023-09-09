// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';

import '../booru/interface.dart';
import '../db/isar.dart';
import 'favorite_booru.dart';
import 'post.dart';

part 'settings.g.dart';

@collection
class Settings {
  final Id id = 0;

  @enumerated
  final GridColumn picturesPerRow;
  final bool booruListView;

  final String path;
  @enumerated
  final Booru selectedBooru;
  @enumerated
  final DisplayQuality quality;
  @enumerated
  final AspectRatio ratio;
  final bool safeMode;

  final bool autoRefresh;
  final int autoRefreshMicroseconds;
  final GallerySettings gallerySettings;

  const Settings(
      {required this.path,
      required this.selectedBooru,
      required this.quality,
      required this.autoRefresh,
      required this.autoRefreshMicroseconds,
      required this.booruListView,
      required this.picturesPerRow,
      required this.safeMode,
      required this.gallerySettings,
      required this.ratio});
  Settings copy(
      {String? path,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? booruListView,
      GridColumn? picturesPerRow,
      bool? autoRefresh,
      int? autoRefreshMicroseconds,
      bool? saveTagsOnlyOnDownload,
      bool? expensiveHash,
      bool? safeMode,
      AspectRatio? ratio,
      GallerySettings? gallerySettings}) {
    return Settings(
        path: path ?? this.path,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        ratio: ratio ?? this.ratio,
        autoRefresh: autoRefresh ?? this.autoRefresh,
        autoRefreshMicroseconds:
            autoRefreshMicroseconds ?? this.autoRefreshMicroseconds,
        booruListView: booruListView ?? this.booruListView,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow,
        safeMode: safeMode ?? this.safeMode,
        gallerySettings: gallerySettings ?? this.gallerySettings);
  }

  Settings.empty()
      : path = "",
        autoRefresh = false,
        autoRefreshMicroseconds = 1.hours.inMicroseconds,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        picturesPerRow = (Platform.isAndroid || Platform.isIOS)
            ? GridColumn.two
            : GridColumn.six,
        booruListView = false,
        safeMode = true,
        gallerySettings = Platform.isAndroid || Platform.isIOS
            ? const GallerySettings()
            : const GallerySettings.desktop(),
        ratio = AspectRatio.one;

  static Settings fromDb() {
    return settingsIsar().settings.getSync(0) ?? Settings.empty();
  }

  static void saveToDb(Settings instance) {
    settingsIsar()
        .writeTxnSync(() => settingsIsar().settings.putSync(instance));
  }

  static void addRemoveFavorites(List<PostBase> posts) {
    final toAdd = <FavoriteBooru>[];
    final toRemove = <String>[];

    for (final post in posts) {
      if (!isFavorite(post.fileUrl)) {
        toAdd.add(FavoriteBooru(
            height: post.height,
            id: post.id,
            md5: post.md5,
            tags: post.tags,
            width: post.width,
            fileUrl: post.fileUrl,
            prefix: post.prefix,
            previewUrl: post.previewUrl,
            sampleUrl: post.sampleUrl,
            ext: post.ext,
            sourceUrl: post.sourceUrl,
            rating: post.rating,
            score: post.score,
            createdAt: post.createdAt));
      } else {
        toRemove.add(post.fileUrl);
      }
    }

    if (toAdd.isEmpty && toRemove.isEmpty) {
      return;
    }

    settingsIsar().writeTxnSync(() {
      settingsIsar().favoriteBoorus.putAllSync(toAdd);
      settingsIsar().favoriteBoorus.deleteAllByFileUrlSync(toRemove);
    });
  }

  static bool isFavorite(String fileUrl) {
    return settingsIsar().favoriteBoorus.getByFileUrlSync(fileUrl) != null;
  }

  static StreamSubscription<Settings?> watch(void Function(Settings? s) f,
      {bool fire = false}) {
    return settingsIsar()
        .settings
        .watchObject(0, fireImmediately: fire)
        .listen(f);
  }
}

@embedded
class GallerySettings {
  final bool hideDirectoryName;
  @enumerated
  final AspectRatio directoryAspectRatio;
  @enumerated
  final GridColumn directoryColumns;

  final bool hideFileName;
  @enumerated
  final AspectRatio filesAspectRatio;
  @enumerated
  final GridColumn filesColumns;
  final bool filesListView;

  GallerySettings copy(
          {bool? hideDirectoryName,
          bool? hideFileName,
          bool? filesListView,
          AspectRatio? filesAspectRatio,
          AspectRatio? directoryAspectRatio,
          GridColumn? filesColumns,
          GridColumn? directoryColumns}) =>
      GallerySettings(
          hideDirectoryName: hideDirectoryName ?? this.hideDirectoryName,
          hideFileName: hideFileName ?? this.hideFileName,
          filesListView: filesListView ?? this.filesListView,
          directoryAspectRatio:
              directoryAspectRatio ?? this.directoryAspectRatio,
          filesAspectRatio: filesAspectRatio ?? this.filesAspectRatio,
          filesColumns: filesColumns ?? this.filesColumns,
          directoryColumns: directoryColumns ?? this.directoryColumns);

  const GallerySettings(
      {this.directoryAspectRatio = AspectRatio.zeroSeven,
      this.directoryColumns = GridColumn.two,
      this.hideDirectoryName = false,
      this.filesAspectRatio = AspectRatio.oneFive,
      this.filesColumns = GridColumn.three,
      this.filesListView = false,
      this.hideFileName = true});

  const GallerySettings.desktop()
      : directoryAspectRatio = AspectRatio.zeroSeven,
        directoryColumns = GridColumn.six,
        hideDirectoryName = false,
        filesListView = false,
        filesAspectRatio = AspectRatio.oneFive,
        filesColumns = GridColumn.six,
        hideFileName = true;
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
