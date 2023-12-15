// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io' as io;

import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/download_file.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/db/schemas/local_tags.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/db/schemas/note_gallery.dart';
import 'package:gallery/src/db/schemas/pinned_directories.dart';
import 'package:gallery/src/db/schemas/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics_gallery.dart';
import 'package:gallery/src/db/schemas/statistics_general.dart';
import 'package:gallery/src/db/schemas/thumbnail.dart';
import 'package:gallery/src/db/schemas/video_settings.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../interfaces/booru.dart';
import 'schemas/system_gallery_directory.dart';
import 'schemas/system_gallery_directory_file.dart';
import 'schemas/directory_tags.dart';
import 'schemas/favorite_media.dart';
import 'schemas/grid_state.dart';
import 'schemas/grid_state_booru.dart';
import 'schemas/post.dart';
import 'schemas/settings.dart';

import 'package:path/path.dart' as path;

import 'schemas/tags.dart';

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
  ], directory: directoryPath, inspector: false);

  final blacklistedDirIsar = Isar.openSync([
    BlacklistedDirectorySchema,
    PinnedDirectoriesSchema,
    FavoriteMediaSchema,
    NoteBooruSchema
  ], directory: directoryPath, inspector: false, name: "androidBlacklistedDir");

  Isar? thumbnailIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync([ThumbnailSchema],
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
      temporaryDbDir: temporaryDbPath,
      temporaryImagesDir: temporaryImagesPath,
      blacklisted: blacklistedDirIsar,
      thumbnail: thumbnailIsar);
}
