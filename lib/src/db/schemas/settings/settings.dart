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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../plugs/platform_functions.dart';
import '../../../interfaces/booru/display_quality.dart';
import '../../initalize_db.dart';
import '../../../interfaces/booru/safe_mode.dart';
import '../booru/favorite_booru.dart';

part 'settings.g.dart';

@embedded
class SettingsPath {
  const SettingsPath({
    this.path = "",
    this.pathDisplay = "",
  });

  final String path;
  final String pathDisplay;

  bool get isEmpty => path.isEmpty;
  bool get isNotEmpty => path.isNotEmpty;
}

@collection
class Settings {
  final Id id = 0;

  final SettingsPath path;
  @enumerated
  final Booru selectedBooru;
  @enumerated
  final DisplayQuality quality;
  @enumerated
  final SafeMode safeMode;

  final bool autoRefresh;
  final int autoRefreshMicroseconds;

  final bool showWelcomePage;

  const Settings({
    required this.path,
    required this.selectedBooru,
    required this.quality,
    required this.autoRefresh,
    required this.autoRefreshMicroseconds,
    required this.safeMode,
    required this.showWelcomePage,
  });

  Settings copy({
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    bool? booruListView,
    GridColumn? picturesPerRow,
    bool? autoRefresh,
    int? autoRefreshMicroseconds,
    bool? saveTagsOnlyOnDownload,
    bool? expensiveHash,
    SafeMode? safeMode,
    GridAspectRatio? ratio,
    bool? showWelcomePage,
  }) {
    return Settings(
      showWelcomePage: showWelcomePage ?? this.showWelcomePage,
      path: path ?? this.path,
      selectedBooru: selectedBooru ?? this.selectedBooru,
      quality: quality ?? this.quality,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      autoRefreshMicroseconds:
          autoRefreshMicroseconds ?? this.autoRefreshMicroseconds,
      safeMode: safeMode ?? this.safeMode,
    );
  }

  Settings.empty()
      : showWelcomePage = true,
        path = const SettingsPath(),
        autoRefresh = false,
        autoRefreshMicroseconds = 1.hours.inMicroseconds,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        safeMode = SafeMode.normal;

  static Settings fromDb() {
    return Dbs.g.main.settings.getSync(0) ?? Settings.empty();
  }

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.settings.putSync(this));
  }

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  static Future<bool> chooseDirectory(void Function(String) onError) async {
    late final SettingsPath resp;

    if (Platform.isAndroid) {
      try {
        resp = (await PlatformFunctions.chooseDirectory())!;
      } catch (e) {
        onError("Empty result"); // TODO: change
        return false;
      }
    } else {
      final r = await FilePicker.platform.getDirectoryPath(
          dialogTitle: "Pick a directory for downloads"); // TODO: change
      if (r == null) {
        onError("Please choose a valid directory"); // TODO: change
        return false;
      }
      resp = SettingsPath(path: r, pathDisplay: r);
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
