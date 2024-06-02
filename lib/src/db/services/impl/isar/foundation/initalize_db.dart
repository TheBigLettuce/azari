// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

Future<DownloadManager> initalizeIsarDb(
  bool temporary,
  ServicesImplTable db,
) async {
  if (_initalized) {
    return throw "already initalized";
  }

  _initalized = true;

  final directoryPath = (await getApplicationSupportDirectory()).path;

  final d = Directory(path.joinAll([directoryPath, "temporary"]));
  d.createSync();
  if (!temporary) {
    d.deleteSync(recursive: true);
    d.createSync();
  }
  final temporaryDbPath = d.path;

  final dimages = Directory(path.joinAll([directoryPath, "temp_images"]));
  dimages.createSync();
  if (!temporary) {
    dimages.deleteSync(recursive: true);
    dimages.createSync();
  }

  final temporaryImagesPath = dimages.path;

  final secondaryDir = path.join(directoryPath, "secondaryGrid");
  {
    Directory(secondaryDir).createSync();
  }

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

  final localTags = Isar.openSync(
    [
      IsarLocalTagsSchema,
      IsarLocalTagDictionarySchema,
      DirectoryTagSchema,
    ],
    directory: directoryPath,
    inspector: false,
    name: "localTags",
  );

  final main = Isar.openSync(
    [
      IsarSettingsSchema,
      IsarFavoriteBooruSchema,
      IsarLocalTagDictionarySchema,
      IsarBookmarkSchema,
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

  if (Platform.isAndroid) {
    thumbnailIsar = Isar.openSync(
      [IsarThumbnailSchema, IsarPinnedThumbnailSchema],
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
    secondaryGridDbDir: secondaryDir,
    blacklisted: blacklistedDirIsar,
    thumbnail: thumbnailIsar,
    localTags: localTags,
  );

  for (final e in _IsarCollectionReverseIterable(
    _IsarCollectionIterator(_Dbs.g.main.isarFavoriteBoorus, reversed: false),
  )) {
    db.favoritePosts.backingStorage.add(e, true);
  }

  for (final e in _IsarCollectionReverseIterable(
    _IsarCollectionIterator(_Dbs.g.main.isarHiddenBooruPosts, reversed: false),
  )) {
    _dbs._hiddenBooruPostCachedValues[(e.postId, e.booru)] = e.thumbUrl;
  }

  for (final e in _IsarCollectionReverseIterable(
    _IsarCollectionIterator(
      _Dbs.g.blacklisted.isarFavoriteFiles,
      reversed: false,
    ),
  )) {
    _dbs._favoriteFilesCachedValues[e.id] = null;
  }

  final downloader = DownloadManager(db.downloads);

  db.downloads.markInProgressAsFailed();

  for (final e in _IsarCollectionReverseIterable(
    _IsarCollectionIterator(
      _Dbs.g.main.isarDownloadFiles,
      reversed: false,
    ),
  )) {
    downloader.restoreFile(e);
  }

  await _removeTempContentsDownloads();

  return downloader;
}

Future<void> _removeTempContentsDownloads() async {
  try {
    final tempd = await getTemporaryDirectory();
    final downld = Directory(path.join(tempd.path, "downloads"));
    if (!downld.existsSync()) {
      return;
    }

    await for (final e in downld.list()) {
      e.deleteSync(recursive: true);
    }
  } catch (e, trace) {
    LogTarget.unknown.logDefaultImportant(
      "deleting temp directories".errorMessage(e),
      trace,
    );
  }
}
