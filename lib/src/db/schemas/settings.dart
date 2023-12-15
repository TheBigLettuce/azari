// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/booru.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../plugs/platform_functions.dart';
import '../initalize_db.dart';
import 'favorite_booru.dart';
import 'post.dart';

part 'settings.g.dart';

@collection
class Settings {
  final Id id = 0;

  final String path;
  @enumerated
  final Booru selectedBooru;
  @enumerated
  final DisplayQuality quality;
  @enumerated
  final SafeMode safeMode;

  final bool autoRefresh;
  final int autoRefreshMicroseconds;

  final GridSettings booru;
  final GridSettings galleryDirectories;
  final GridSettings galleryFiles;
  final GridSettings favorites;

  @enumerated
  final FilteringMode favoritesPageMode;

  const Settings({
    required this.path,
    required this.selectedBooru,
    required this.quality,
    required this.autoRefresh,
    required this.autoRefreshMicroseconds,
    required this.safeMode,
    required this.favoritesPageMode,
    required this.booru,
    required this.favorites,
    required this.galleryDirectories,
    required this.galleryFiles,
  });

  Settings copy({
    String? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    bool? booruListView,
    GridColumn? picturesPerRow,
    bool? autoRefresh,
    int? autoRefreshMicroseconds,
    bool? saveTagsOnlyOnDownload,
    FilteringMode? favoritesPageMode,
    bool? expensiveHash,
    SafeMode? safeMode,
    GridAspectRatio? ratio,
    GridSettings? galleryDirectories,
    GridSettings? galleryFiles,
    GridSettings? favorites,
    GridSettings? booru,
  }) {
    return Settings(
        path: path ?? this.path,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        favoritesPageMode: favoritesPageMode ?? this.favoritesPageMode,
        autoRefresh: autoRefresh ?? this.autoRefresh,
        autoRefreshMicroseconds:
            autoRefreshMicroseconds ?? this.autoRefreshMicroseconds,
        safeMode: safeMode ?? this.safeMode,
        galleryFiles: galleryFiles ?? this.galleryFiles,
        galleryDirectories: galleryDirectories ?? this.galleryDirectories,
        favorites: favorites ?? this.favorites,
        booru: booru ?? this.booru);
  }

  Settings.empty()
      : path = "",
        autoRefresh = false,
        autoRefreshMicroseconds = 1.hours.inMicroseconds,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        favoritesPageMode = FilteringMode.tag,
        safeMode = SafeMode.normal,
        booru = GridSettings(
          columns: (Platform.isAndroid || Platform.isIOS)
              ? GridColumn.two
              : GridColumn.six,
        ),
        galleryDirectories = GridSettings(
            columns: (Platform.isAndroid || Platform.isIOS)
                ? GridColumn.two
                : GridColumn.six),
        galleryFiles = GridSettings(
            columns: (Platform.isAndroid || Platform.isIOS)
                ? GridColumn.two
                : GridColumn.six),
        favorites = GridSettings(
            columns: (Platform.isAndroid || Platform.isIOS)
                ? GridColumn.two
                : GridColumn.six);

  static Settings fromDb() {
    return Dbs.g.main.settings.getSync(0) ?? Settings.empty();
  }

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.settings.putSync(this));
  }

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  static Future<bool> chooseDirectory(void Function(String) onError) async {
    late final String resp;

    if (Platform.isAndroid) {
      try {
        resp = (await PlatformFunctions.chooseDirectory())!;
      } catch (e) {
        onError((e as PlatformException).code);
        return false;
      }
    } else {
      final r = await FilePicker.platform
          .getDirectoryPath(dialogTitle: "Pick a directory for downloads");
      if (r == null) {
        onError("Please choose a valid directory");
        return false;
      }
      resp = r;
    }

    Settings.fromDb().copy(path: resp).save();

    return Future.value(true);
  }

  static void addRemoveFavorites(
      BuildContext context, List<PostBase> posts, bool showDeleteSnackbar) {
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

    final deleteCopy = toRemove.isEmpty
        ? null
        : Dbs.g.main.favoriteBoorus.getAllByFileUrlSync(toRemove);

    Dbs.g.main.writeTxnSync(() {
      Dbs.g.main.favoriteBoorus.putAllSync(toAdd);
      Dbs.g.main.favoriteBoorus
          .deleteAllByFileUrlSync(toRemove.map((e) => e).toList());
    });

    if (deleteCopy != null && showDeleteSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: 20.seconds,
        content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
        action: SnackBarAction(
            label: AppLocalizations.of(context)!.undoLabel,
            onPressed: () {
              Dbs.g.main.writeTxnSync(() =>
                  Dbs.g.main.favoriteBoorus.putAllSync(deleteCopy.cast()));
            }),
      ));
    }
  }

  static bool isFavorite(String fileUrl) {
    return Dbs.g.main.favoriteBoorus.getByFileUrlSync(fileUrl) != null;
  }

  static StreamSubscription<Settings?> watch(void Function(Settings? s) f,
      {bool fire = false}) {
    return Dbs.g.main.settings.watchObject(0, fireImmediately: fire).listen(f);
  }
}

@embedded
class GridSettings {
  final bool hideName;
  @enumerated
  final GridAspectRatio aspectRatio;
  @enumerated
  final GridColumn columns;
  final bool listView;

  GridSettings copy(
      {bool? hideName,
      GridAspectRatio? aspectRatio,
      GridColumn? columns,
      bool? listView}) {
    return GridSettings(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        hideName: hideName ?? this.hideName,
        columns: columns ?? this.columns,
        listView: listView ?? this.listView);
  }

  const GridSettings(
      {this.aspectRatio = GridAspectRatio.one,
      this.columns = GridColumn.three,
      this.listView = false,
      this.hideName = false});
}

enum SafeMode {
  normal("Normal"),
  none("None"),
  relaxed("Relaxed");

  final String string;

  const SafeMode(this.string);
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

enum GridAspectRatio {
  one(1.0),
  zeroFive(0.5),
  zeroSeven(0.7),
  oneTwo(1.2),
  oneFive(1.5);

  final double value;
  const GridAspectRatio(this.value);
}
