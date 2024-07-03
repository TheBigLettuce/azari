// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/net/manga/manga_api.dart";

Future<DownloadManager> init(ServicesImplTable db, bool temporary) =>
    throw UnimplementedError();

ServicesImplTable getApi() => DummyServicesImplTable();

class DummyServicesImplTable
    with ServicesObjFactoryExt
    implements ServicesImplTable {
  @override
  SettingsService get settings => throw UnimplementedError();
  @override
  MiscSettingsService get miscSettings => throw UnimplementedError();
  @override
  SavedAnimeEntriesService get savedAnimeEntries => throw UnimplementedError();
  @override
  SavedAnimeCharactersService get savedAnimeCharacters =>
      throw UnimplementedError();
  @override
  WatchedAnimeEntryService get watchedAnime => throw UnimplementedError();
  @override
  VideoSettingsService get videoSettings => throw UnimplementedError();
  @override
  HiddenBooruPostService get hiddenBooruPost => throw UnimplementedError();
  @override
  DownloadFileService get downloads => throw UnimplementedError();
  @override
  FavoritePostSourceService get favoritePosts => throw UnimplementedError();
  @override
  StatisticsGeneralService get statisticsGeneral => throw UnimplementedError();
  @override
  StatisticsGalleryService get statisticsGallery => throw UnimplementedError();
  @override
  StatisticsBooruService get statisticsBooru => throw UnimplementedError();
  @override
  StatisticsDailyService get statisticsDaily => throw UnimplementedError();
  @override
  DirectoryMetadataService get directoryMetadata => throw UnimplementedError();
  @override
  ChaptersSettingsService get chaptersSettings => throw UnimplementedError();
  @override
  SavedMangaChaptersService get savedMangaChapters =>
      throw UnimplementedError();
  @override
  ReadMangaChaptersService get readMangaChapters => throw UnimplementedError();
  @override
  PinnedMangaService get pinnedManga => throw UnimplementedError();
  @override
  ThumbnailService get thumbnails => throw UnimplementedError();
  @override
  PinnedThumbnailService get pinnedThumbnails => throw UnimplementedError();
  @override
  LocalTagsService get localTags => throw UnimplementedError();
  @override
  LocalTagDictionaryService get localTagDictionary =>
      throw UnimplementedError();
  @override
  CompactMangaDataService get compactManga => throw UnimplementedError();
  @override
  GridBookmarkService get gridBookmarks => throw UnimplementedError();
  @override
  FavoriteFileService get favoriteFiles => throw UnimplementedError();
  @override
  DirectoryTagService get directoryTags => throw UnimplementedError();
  @override
  BlacklistedDirectoryService get blacklistedDirectories =>
      throw UnimplementedError();
  @override
  GridSettingsService get gridSettings => throw UnimplementedError();
  @override
  MainGridService mainGrid(Booru booru) => throw UnimplementedError();
  @override
  SecondaryGridService secondaryGrid(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]) =>
      throw UnimplementedError();

  @override
  TagManager makeTagManager(Booru booru) => throw UnimplementedError();

  @override
  LocalTagsData makeLocalTagsData(
    String filename,
    List<String> tags,
  ) =>
      throw UnimplementedError();

  @override
  CompactMangaData makeCompactMangaData({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) =>
      throw UnimplementedError();

  @override
  DownloadFileData makeDownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) =>
      throw UnimplementedError();

  @override
  HiddenBooruPostData makeHiddenBooruPostData(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      throw UnimplementedError();

  @override
  PinnedManga makePinnedManga({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  }) =>
      throw UnimplementedError();

  @override
  GridBookmark makeGridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
    required List<GridBookmarkThumbnail> thumbnails,
  }) {
    throw UnimplementedError();
  }

  @override
  BlacklistedDirectoryData makeBlacklistedDirectoryData(
    String bucketId,
    String name,
  ) =>
      throw UnimplementedError();

  @override
  AnimeGenre makeAnimeGenre({
    required String title,
    required int id,
    required bool unpressable,
    required bool explicit,
  }) {
    throw UnimplementedError();
  }

  @override
  AnimeRelation makeAnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  }) {
    throw UnimplementedError();
  }

  @override
  AnimeCharacter makeAnimeCharacter({
    required String imageUrl,
    required String name,
    required String role,
  }) {
    throw UnimplementedError();
  }

  @override
  GridBookmarkThumbnail makeGridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) =>
      throw UnimplementedError();
}
