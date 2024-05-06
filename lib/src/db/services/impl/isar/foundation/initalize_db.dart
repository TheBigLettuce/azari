// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

Future<void> initalizeDb(bool temporary) async {
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

  final anime = Isar.openSync(
    [
      IsarSavedAnimeEntrySchema,
      IsarWatchedAnimeEntrySchema,
      IsarSavedAnimeCharactersSchema,
      IsarReadMangaChapterSchema,
      IsarCompactMangaDataSchema,
      IsarSavedMangaChaptersSchema,
      IsarChapterSettingsSchema,
      IsarPinnedMangaSchema,
    ],
    name: "anime",
    directory: directoryPath,
    inspector: false,
  );

  final main = Isar.openSync(
    [
      IsarSettingsSchema,
      IsarFavoriteBooruSchema,
      LocalTagDictionarySchema,
      GridStateBooruSchema,
      IsarDownloadFileSchema,
      IsarHiddenBooruPostSchema,
      IsarStatisticsGallerySchema,
      IsarStatisticsGeneralSchema,
      IsarStatisticsBooruSchema,
      IsarDailyStatisticsSchema,
      IsarVideoSettingsSchema,
      IsarMiscSettingsSchema,
      IsarGridSettingsBooruSchema,
      IsarGridSettingsDirectoriesSchema,
      IsarGridSettingsFavoritesSchema,
      IsarGridSettingsFilesSchema,
      IsarGridSettingsAnimeDiscoverySchema,
    ],
    directory: directoryPath,
    inspector: false,
  );

  final blacklistedDirIsar = Isar.openSync(
    [
      IsarBlacklistedDirectorySchema,
      IsarFavoriteFileSchema,
      IsarDirectoryMetadataSchema,
    ],
    directory: directoryPath,
    inspector: false,
    name: "androidBlacklistedDir",
  );

  Isar? thumbnailIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync(
      [IsarThumbnailSchema, PinnedThumbnailSchema],
      directory: directoryPath,
      inspector: false,
      name: "androidThumbnails",
    );
    thumbnailIsar.writeTxnSync(() {
      thumbnailIsar!.isarThumbnails
          .where()
          .differenceHashEqualTo(0)
          .or()
          .pathEqualTo("")
          .deleteAllSync();
    });
  }

  _dbs = _Dbs._(
    directory: directoryPath,
    main: main,
    anime: anime,
    temporaryDbDir: temporaryDbPath,
    temporaryImagesDir: temporaryImagesPath,
    blacklisted: blacklistedDirIsar,
    thumbnail: thumbnailIsar,
  );
}
