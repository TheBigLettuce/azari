// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/db/schemas/booru/favorite_booru.dart";
import "package:gallery/src/db/services/impl/isar/settings.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:isar/isar.dart";

part "settings.g.dart";

@embedded
class IsarSettingsPath implements SettingsPath {
  const IsarSettingsPath({
    this.path = "",
    this.pathDisplay = "",
  });
  @override
  final String path;
  @override
  final String pathDisplay;

  @override
  @ignore
  bool get isEmpty => path.isEmpty;

  @override
  @ignore
  bool get isNotEmpty => path.isNotEmpty;
}

@collection
class IsarSettings extends SettingsData {
  const IsarSettings({
    required this.path,
    required super.selectedBooru,
    required super.quality,
    required super.safeMode,
    required super.showWelcomePage,
  });

  Id get id => 0;

  @override
  final IsarSettingsPath path;

  @override
  IsarSettings copy({
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
  }) {
    return IsarSettings(
      showWelcomePage: showWelcomePage ?? this.showWelcomePage,
      path: (path as IsarSettingsPath?) ?? this.path,
      selectedBooru: selectedBooru ?? this.selectedBooru,
      quality: quality ?? this.quality,
      safeMode: safeMode ?? this.safeMode,
    );
  }

  @override
  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.isarSettings.putSync(this));
  }

  @override
  @ignore
  SettingsService get s => const IsarSettingsService();

  static void addRemoveFavorites(
    BuildContext context,
    List<PostBase> posts,
    bool showDeleteSnackbar,
  ) {
    final toAdd = <FavoriteBooru>[];
    final toRemoveInts = <int>[];
    final toRemoveBoorus = <Booru>[];

    for (final post in posts) {
      if (!isFavorite(post.id, post.booru)) {
        toAdd.add(
          FavoriteBooru(
            height: post.height,
            id: post.id,
            md5: post.md5,
            tags: post.tags,
            width: post.width,
            fileUrl: post.fileUrl,
            booru: post.booru,
            previewUrl: post.previewUrl,
            sampleUrl: post.sampleUrl,
            ext: post.ext,
            sourceUrl: post.sourceUrl,
            rating: post.rating,
            score: post.score,
            createdAt: post.createdAt,
          ),
        );
      } else {
        toRemoveInts.add(post.id);
        toRemoveBoorus.add(post.booru);
      }
    }

    if (toAdd.isEmpty && toRemoveInts.isEmpty) {
      return;
    }

    final deleteCopy = toRemoveInts.isEmpty
        ? null
        : Dbs.g.main.favoriteBoorus
            .getAllByIdBooruSync(toRemoveInts, toRemoveBoorus);

    Dbs.g.main.writeTxnSync(() {
      Dbs.g.main.favoriteBoorus.putAllByIdBooruSync(toAdd);
      Dbs.g.main.favoriteBoorus
          .deleteAllByIdBooruSync(toRemoveInts, toRemoveBoorus);
    });

    if (deleteCopy != null && showDeleteSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: 20.seconds,
          content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undoLabel,
            onPressed: () {
              Dbs.g.main.writeTxnSync(
                () => Dbs.g.main.favoriteBoorus.putAllSync(deleteCopy.cast()),
              );
            },
          ),
        ),
      );
    }
  }

  static bool isFavorite(int id, Booru booru) {
    return Dbs.g.main.favoriteBoorus.getByIdBooruSync(id, booru) != null;
  }
}
