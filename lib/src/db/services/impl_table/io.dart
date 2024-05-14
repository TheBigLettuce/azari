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
  final ret = await initalizeIsarDb(false);

  return DownloadManager(db.downloads);
}

class ServicesImplTable implements ServiceMarker {
  SettingsService get settings => const IsarSettingsService();
  MiscSettingsService get miscSettings => const IsarMiscSettingsService();
  SavedAnimeEntriesService get savedAnimeEntries =>
      const IsarSavedAnimeEntriesService();
  SavedAnimeCharactersService get savedAnimeCharacters =>
      const IsarSavedAnimeCharatersService();
  WatchedAnimeEntryService get watchedAnime =>
      const IsarWatchedAnimeEntryService();
  VideoSettingsService get videoSettings => const IsarVideoService();
  HiddenBooruPostService get hiddenBooruPost =>
      const IsarHiddenBooruPostService();
  DownloadFileService get downloads => const IsarDownloadFileService();
  FavoritePostService get favoritePosts => const IsarFavoritePostService();
  StatisticsGeneralService get statisticsGeneral =>
      const IsarStatisticsGeneralService();
  StatisticsGalleryService get statisticsGallery =>
      const IsarStatisticsGalleryService();
  StatisticsBooruService get statisticsBooru =>
      const IsarStatisticsBooruService();
  StatisticsDailyService get statisticsDaily =>
      const IsarDailyStatisticsService();
  DirectoryMetadataService get directoryMetadata =>
      const IsarDirectoryMetadataService();
  ChaptersSettingsService get chaptersSettings =>
      const IsarChapterSettingsService();
  SavedMangaChaptersService get savedMangaChapters =>
      const IsarSavedMangaChaptersService();
  ReadMangaChaptersService get readMangaChapters =>
      const IsarReadMangaChapterService();
  PinnedMangaService get pinnedManga => const IsarPinnedMangaService();
  ThumbnailService get thumbnails => const IsarThumbnailService();
  PinnedThumbnailService get pinnedThumbnails =>
      const IsarPinnedThumbnailService();
  LocalTagsService get localTags => const IsarLocalTagsService();
  LocalTagDictionaryService get localTagDictionary =>
      const IsarLocalTagDictionaryService();
  CompactMangaDataService get compactManga =>
      const IsarCompactMangaDataService();
  GridStateBooruService get gridStateBooru => const IsarGridStateBooruService();
  FavoriteFileService get favoriteFiles => const IsarFavoriteFileService();
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  BlacklistedDirectoryService get blacklistedDirectories =>
      const IsarBlacklistedDirectoryService();
  GridSettingsService get gridSettings => const IsarGridSettinsService();

  MainGridService mainGrid(Booru booru) => IsarMainGridService.booru(booru);
  SecondaryGridService secondaryGrid(Booru booru, String name) =>
      IsarSecondaryGridService.booru(booru, name);
}

extension ServicesImplTableObjInstExt on ServicesImplTable {
  TagManager tagManager(Booru booru) => IsarTagManager(booru);

  LocalTagsData localTagsDataForDb(
    String filename,
    List<String> tags,
  ) =>
      IsarLocalTags(filename, tags);

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

  SettingsPath settingsPathForCurrent({
    required String path,
    required String pathDisplay,
  }) =>
      IsarSettingsPath(
        path: path,
        pathDisplay: pathDisplay,
      );

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

  HiddenBooruPostData hiddenBooruPostDataForDb(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      IsarHiddenBooruPost(booru, postId, thumbUrl);

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
