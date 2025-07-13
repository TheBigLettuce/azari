// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/services/impl/io/isar/foundation/favorite_posts_isolate.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/post.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/visited_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/downloader/download_file.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/directory_metadata.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/directory_tags.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/thumbnail.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/booru.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/directories.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/favorites.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/files.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_booru_paging.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_time.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/updates_available.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/accounts.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/colors_names.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/settings.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/video_settings.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/daily_statistics.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_booru.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_gallery.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_general.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/hottest_tag.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/hottest_tag_refresh_date.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/local_tag_dictionary.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/local_tags.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/tags.dart";
import "package:isar/isar.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;

const primaryGridSchemas = [
  IsarUpdatesAvailableSchema,
  IsarGridTimeSchema,
  IsarGridStateSchema,
  PostIsarSchema,
  IsarGridBooruPagingSchema,
];

const mainSchemas = [
  IsarAccountsSchema,
  IsarColorsNamesDataSchema,
  IsarVisitedPostSchema,
  IsarSettingsSchema,
  IsarLocalTagDictionarySchema,
  IsarBookmarkSchema,
  IsarDownloadFileSchema,
  IsarHiddenBooruPostSchema,
  IsarStatisticsGallerySchema,
  IsarStatisticsGeneralSchema,
  IsarStatisticsBooruSchema,
  IsarDailyStatisticsSchema,
  IsarVideoSettingsSchema,
  IsarGridSettingsBooruSchema,
  IsarGridSettingsDirectoriesSchema,
  IsarGridSettingsFavoritesSchema,
  IsarGridSettingsFilesSchema,
];

class DbPaths {
  factory DbPaths() => _instance!;

  const DbPaths._({
    required this.rootDirectory,
    required this.temporaryDir,
    required this.temporaryImagesDir,
    required this.secondaryGridDir,
  });

  static void init({
    required String rootDirectory,
    required String temporaryDir,
    required String temporaryImagesDir,
    required String secondaryGridDir,
  }) {
    if (_instance != null) {
      return;
    }

    _instance = DbPaths._(
      rootDirectory: rootDirectory,
      temporaryDir: temporaryDir,
      temporaryImagesDir: temporaryImagesDir,
      secondaryGridDir: secondaryGridDir,
    );
  }

  static DbPaths? _instance;

  final String rootDirectory;

  final String temporaryDir;
  final String temporaryImagesDir;
  final String secondaryGridDir;

  String get appStorageDir => rootDirectory;

  void clearTemporaryImages() {
    io.Directory(temporaryImagesDir)
      ..createSync()
      ..deleteSync(recursive: true)
      ..createSync();
  }

  void ensurePathsExist(bool temporary) {
    {
      final d = io.Directory(temporaryDir)..createSync();
      if (!temporary) {
        d.deleteSync(recursive: true);
        d.createSync();
      }
    }

    {
      final d = io.Directory(temporaryImagesDir)..createSync();
      if (!temporary) {
        d.deleteSync(recursive: true);
        d.createSync();
      }
    }

    io.Directory(secondaryGridDir).createSync();
  }

  Future<void> removeTempContentsDownloads(String dir) async {
    try {
      final downld = io.Directory(path.join(dir, "downloads"));
      if (!downld.existsSync()) {
        return;
      }

      await for (final e in downld.list()) {
        e.deleteSync(recursive: true);
      }
    } catch (e, trace) {
      Logger.root.severe("deleting temp download directory", e, trace);
    }
  }
}

class Dbs {
  factory Dbs() => Dbs._dbs;

  Dbs._({
    required this.localTags,
    required this.blacklisted,
    required this.main,
    required this.thumbnail,
    required this.favorites,
  });

  static void init(DbPaths paths) {
    final localTags = Isar.openSync(
      const [
        IsarTagSchema,
        IsarLocalTagsSchema,
        IsarLocalTagDictionarySchema,
        DirectoryTagSchema,
        IsarHottestTagSchema,
        IsarHottestTagDateSchema,
      ],
      directory: paths.rootDirectory,
      inspector: false,
      name: "localTags",
    );

    final main = Isar.openSync(
      mainSchemas,
      directory: paths.rootDirectory,
      inspector: false,
    );

    final blacklistedDb = Isar.openSync(
      const [IsarBlacklistedDirectorySchema, IsarDirectoryMetadataSchema],
      directory: paths.rootDirectory,
      inspector: false,
      name: "androidBlacklistedDir",
    );

    Isar? thumbnailDb;

    if (io.Platform.isAndroid) {
      thumbnailDb = Isar.openSync(
        const [IsarThumbnailSchema],
        directory: paths.rootDirectory,
        inspector: false,
        name: "androidThumbnails",
      );
      thumbnailDb.writeTxnSync(() {
        thumbnailDb!.isarThumbnails
            .where()
            // .differenceHashEqualTo(0)
            // .or()
            .pathEqualTo("")
            .deleteAllSync();
      });
    }

    final favorites = FavoritePostsIsolate(paths.rootDirectory);

    _dbs = Dbs._(
      localTags: localTags,
      blacklisted: blacklistedDb,
      main: main,
      thumbnail: thumbnailDb,
      favorites: favorites,
    );
  }

  static late final Dbs _dbs;

  final hiddenBooruPostCachedValues = <(int, Booru), String>{};

  final _openBooruDbs = <Booru, Isar>{};

  final Isar main;
  final Isar localTags;
  final Isar? thumbnail;
  final Isar blacklisted;

  final FavoritePostsIsolate favorites;

  Isar openPrimaryGrid(Booru booru, DbPaths paths) =>
      _openBooruDbs.putIfAbsent(booru, () => _openPrimaryGrid(booru, paths));

  Isar _openPrimaryGrid(Booru booru, DbPaths paths) {
    final instance = Isar.getInstance(booru.string);
    if (instance != null) {
      return instance;
    }

    return Isar.openSync(
      primaryGridSchemas,
      directory: paths.rootDirectory,
      inspector: false,
      name: booru.string,
    );
  }

  Isar openSecondaryGridName(String name, bool create, DbPaths paths) {
    if (!create &&
        !io.File(
          path.join(paths.secondaryGridDir, "$name.isar"),
        ).existsSync()) {
      throw "$name doesn't exist on disk";
    }

    return Isar.openSync(
      const [
        PostIsarSchema,
        IsarGridBooruPagingSchema,
        IsarUpdatesAvailableSchema,
      ],
      directory: paths.secondaryGridDir,
      inspector: false,
      name: name,
    );
  }
}
