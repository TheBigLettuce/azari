// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";

Future<DownloadManager> init(ServicesImplTable db) async {
  await initalizeIsarDb(false);

  return DownloadManager(db.downloads);
}

ServicesImplTable getApi() => const IoServicesImplTable();

class IoServicesImplTable
    with IoServicesImplTableObjInstExt
    implements ServicesImplTable {
  const IoServicesImplTable();

  @override
  SettingsService get settings => const IsarSettingsService();
  @override
  MiscSettingsService get miscSettings => const IsarMiscSettingsService();
  @override
  SavedAnimeEntriesService get savedAnimeEntries =>
      const IsarSavedAnimeEntriesService();
  @override
  SavedAnimeCharactersService get savedAnimeCharacters =>
      const IsarSavedAnimeCharatersService();
  @override
  WatchedAnimeEntryService get watchedAnime =>
      const IsarWatchedAnimeEntryService();
  @override
  VideoSettingsService get videoSettings => const IsarVideoService();
  @override
  HiddenBooruPostService get hiddenBooruPost =>
      const IsarHiddenBooruPostService();
  @override
  DownloadFileService get downloads => const IsarDownloadFileService();
  @override
  FavoritePostService get favoritePosts => const IsarFavoritePostService();
  @override
  StatisticsGeneralService get statisticsGeneral =>
      const IsarStatisticsGeneralService();
  @override
  StatisticsGalleryService get statisticsGallery =>
      const IsarStatisticsGalleryService();
  @override
  StatisticsBooruService get statisticsBooru =>
      const IsarStatisticsBooruService();
  @override
  StatisticsDailyService get statisticsDaily =>
      const IsarDailyStatisticsService();
  @override
  DirectoryMetadataService get directoryMetadata =>
      const IsarDirectoryMetadataService();
  @override
  ChaptersSettingsService get chaptersSettings =>
      const IsarChapterSettingsService();
  @override
  SavedMangaChaptersService get savedMangaChapters =>
      const IsarSavedMangaChaptersService();
  @override
  ReadMangaChaptersService get readMangaChapters =>
      const IsarReadMangaChapterService();
  @override
  PinnedMangaService get pinnedManga => const IsarPinnedMangaService();
  @override
  ThumbnailService get thumbnails => const IsarThumbnailService();
  @override
  PinnedThumbnailService get pinnedThumbnails =>
      const IsarPinnedThumbnailService();
  @override
  LocalTagsService get localTags => const IsarLocalTagsService();
  @override
  LocalTagDictionaryService get localTagDictionary =>
      const IsarLocalTagDictionaryService();
  @override
  CompactMangaDataService get compactManga =>
      const IsarCompactMangaDataService();
  @override
  GridStateBooruService get gridStateBooru => const IsarGridStateBooruService();
  @override
  FavoriteFileService get favoriteFiles => const IsarFavoriteFileService();
  @override
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  @override
  BlacklistedDirectoryService get blacklistedDirectories =>
      const IsarBlacklistedDirectoryService();
  @override
  GridSettingsService get gridSettings => const IsarGridSettinsService();

  @override
  MainGridService mainGrid(Booru booru) => IsarMainGridService.booru(booru);
  @override
  SecondaryGridService secondaryGrid(Booru booru, String name) =>
      IsarSecondaryGridService.booru(booru, name);
}

mixin IoServicesImplTableObjInstExt implements ServicesImplTableObjInstExt {
  @override
  TagManager tagManager(Booru booru) => IsarTagManager(booru);

  @override
  LocalTagsData localTagsDataForDb(
    String filename,
    List<String> tags,
  ) =>
      IsarLocalTags(filename, tags);

  @override
  CompactMangaData compactMangaDataForDb({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) =>
      IsarCompactMangaData(
        mangaId: mangaId,
        site: site,
        thumbUrl: thumbUrl,
        title: title,
      );

  @override
  SettingsPath settingsPathForCurrent({
    required String path,
    required String pathDisplay,
  }) =>
      IsarSettingsPath(
        path: path,
        pathDisplay: pathDisplay,
      );

  @override
  DownloadFileData downloadFileDataForDbFormat({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) =>
      IsarDownloadFile(
        status: status,
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
      );

  @override
  HiddenBooruPostData hiddenBooruPostDataForDb(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      IsarHiddenBooruPost(booru, postId, thumbUrl);

  @override
  PinnedManga pinnedMangaForDb({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  }) =>
      IsarPinnedManga(
        mangaId: mangaId,
        site: site,
        thumbUrl: thumbUrl,
        title: title,
      );
}
