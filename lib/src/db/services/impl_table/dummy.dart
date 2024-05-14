// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";

Future<DownloadManager> init(ServicesImplTable db) =>
    throw UnimplementedError();

class ServicesImplTable implements ServiceMarker {
  SettingsService get settings => throw UnimplementedError();
  MiscSettingsService get miscSettings => throw UnimplementedError();
  SavedAnimeEntriesService get savedAnimeEntries => throw UnimplementedError();
  SavedAnimeCharactersService get savedAnimeCharacters =>
      throw UnimplementedError();
  WatchedAnimeEntryService get watchedAnime => throw UnimplementedError();
  VideoSettingsService get videoSettings => throw UnimplementedError();
  HiddenBooruPostService get hiddenBooruPost => throw UnimplementedError();
  DownloadFileService get downloads => throw UnimplementedError();
  FavoritePostService get favoritePosts => throw UnimplementedError();
  StatisticsGeneralService get statisticsGeneral => throw UnimplementedError();
  StatisticsGalleryService get statisticsGallery => throw UnimplementedError();
  StatisticsBooruService get statisticsBooru => throw UnimplementedError();
  StatisticsDailyService get statisticsDaily => throw UnimplementedError();
  DirectoryMetadataService get directoryMetadata => throw UnimplementedError();
  ChaptersSettingsService get chaptersSettings => throw UnimplementedError();
  SavedMangaChaptersService get savedMangaChapters =>
      throw UnimplementedError();
  ReadMangaChaptersService get readMangaChapters => throw UnimplementedError();
  PinnedMangaService get pinnedManga => throw UnimplementedError();
  ThumbnailService get thumbnails => throw UnimplementedError();
  PinnedThumbnailService get pinnedThumbnails => throw UnimplementedError();
  LocalTagsService get localTags => throw UnimplementedError();
  LocalTagDictionaryService get localTagDictionary =>
      throw UnimplementedError();
  CompactMangaDataService get compactManga => throw UnimplementedError();
  GridStateBooruService get gridStateBooru => throw UnimplementedError();
  FavoriteFileService get favoriteFiles => throw UnimplementedError();
  DirectoryTagService get directoryTags => throw UnimplementedError();
  BlacklistedDirectoryService get blacklistedDirectories =>
      throw UnimplementedError();
  GridSettingsService get gridSettings => throw UnimplementedError();
  MainGridService mainGrid(Booru booru) => throw UnimplementedError();
  SecondaryGridService secondaryGrid(Booru booru, String name) =>
      throw UnimplementedError();
}

extension ServicesImplTableObjInstExt on ServicesImplTable {
  TagManager tagManager(Booru booru) => throw UnimplementedError();

  LocalTagsData localTagsDataForDb(
    String filename,
    List<String> tags,
  ) =>
      throw UnimplementedError();

  CompactMangaData compactMangaDataForDb({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) =>
      throw UnimplementedError();

  SettingsPath settingsPathForCurrent({
    required String path,
    required String pathDisplay,
  }) =>
      throw UnimplementedError();

  DownloadFileData downloadFileDataForDbFormat({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) =>
      throw UnimplementedError();

  HiddenBooruPostData hiddenBooruPostDataForDb(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      throw UnimplementedError();

  PinnedManga pinnedMangaForDb({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  }) =>
      throw UnimplementedError();
}
