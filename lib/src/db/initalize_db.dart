// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io' as io;

import 'package:gallery/src/db/schemas/anime/saved_anime_characters.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/grid_settings/directories.dart';
import 'package:gallery/src/db/schemas/grid_settings/favorites.dart';
import 'package:gallery/src/db/schemas/grid_settings/files.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/tags/local_tag_dictionary.dart';
import 'package:gallery/src/db/schemas/tags/local_tags.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/db/schemas/gallery/note_gallery.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_directories.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_thumbnail.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/db/schemas/gallery/thumbnail.dart';
import 'package:gallery/src/db/schemas/settings/video_settings.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/logging/logging.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'schemas/gallery/system_gallery_directory.dart';
import 'schemas/gallery/system_gallery_directory_file.dart';
import 'schemas/gallery/directory_tags.dart';
import 'schemas/gallery/favorite_booru_post.dart';
import 'schemas/grid_state/grid_state.dart';
import 'schemas/grid_state/grid_state_booru.dart';
import 'schemas/booru/post.dart';
import 'schemas/settings/settings.dart';

import 'package:path/path.dart' as path;

import 'schemas/tags/tags.dart';

part 'dbs.dart';
part 'dbs_open.dart';

bool _initalized = false;

Future initalizeDb(bool temporary) async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  final directoryPath = (await getApplicationSupportDirectory()).path;

  final d = io.Directory(path.joinAll([directoryPath, "temporary"]));
  d.createSync();
  if (!temporary) {
    d.deleteSync(recursive: true);
    d.createSync();
  }
  final temporaryDbPath = d.path;

  final dimages = io.Directory(path.joinAll([directoryPath, "temp_images"]));
  dimages.createSync();
  if (!temporary) {
    dimages.deleteSync(recursive: true);
    dimages.createSync();
  }

  final temporaryImagesPath = dimages.path;

  final anime = Isar.openSync([
    SavedAnimeEntrySchema,
    WatchedAnimeEntrySchema,
    SavedAnimeCharactersSchema,
  ], name: "anime", directory: directoryPath, inspector: false);

  final main = Isar.openSync([
    SettingsSchema,
    FavoriteBooruSchema,
    LocalTagDictionarySchema,
    GridStateBooruSchema,
    DownloadFileSchema,
    NoteGallerySchema,
    HiddenBooruPostSchema,
    StatisticsGallerySchema,
    StatisticsGeneralSchema,
    StatisticsBooruSchema,
    VideoSettingsSchema,
    MiscSettingsSchema,
    GridSettingsBooruSchema,
    GridSettingsDirectoriesSchema,
    GridSettingsFavoritesSchema,
    GridSettingsFilesSchema,
    GridSettingsAnimeDiscoverySchema,
  ], directory: directoryPath, inspector: false);

  final blacklistedDirIsar = Isar.openSync([
    BlacklistedDirectorySchema,
    PinnedDirectoriesSchema,
    FavoriteBooruPostSchema,
    NoteBooruSchema
  ], directory: directoryPath, inspector: false, name: "androidBlacklistedDir");

  Isar? thumbnailIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync([ThumbnailSchema, PinnedThumbnailSchema],
        directory: directoryPath, inspector: false, name: "androidThumbnails");
    thumbnailIsar.writeTxnSync(() {
      thumbnailIsar!.thumbnails
          .where()
          .differenceHashEqualTo(0)
          .or()
          .pathEqualTo("")
          .deleteAllSync();
    });
  }

  _dbs = Dbs._(
      directory: directoryPath,
      main: main,
      anime: anime,
      temporaryDbDir: temporaryDbPath,
      temporaryImagesDir: temporaryImagesPath,
      blacklisted: blacklistedDirIsar,
      thumbnail: thumbnailIsar);

  LogTarget.init.logDefault(
      "DB${temporary ? '(temporary)' : ''}".messageInit, LogSeverity.init);
}
