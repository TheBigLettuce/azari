// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_characters.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/bookmark.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";

Future<DownloadManager> init(ServicesImplTable db) async {
  return await initalizeIsarDb(false, db);
}

ServicesImplTable getApi() => IoServicesImplTable();

class IoServicesImplTable
    with IoServicesImplTableObjInstExt
    implements ServicesImplTable {
  IoServicesImplTable();

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
  FavoritePostSourceService favoritePosts = IsarFavoritePostService();
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
  GridBookmarkService get gridBookmarks => const IsarGridStateBooruService();
  @override
  FavoriteFileService get favoriteFiles => const IsarFavoriteFileService();
  @override
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  @override
  BlacklistedDirectoryService blacklistedDirectories =
      IsarBlacklistedDirectoryService();
  @override
  GridSettingsService get gridSettings => const IsarGridSettinsService();

  @override
  MainGridService mainGrid(Booru booru) => IsarMainGridService.booru(booru);
  @override
  SecondaryGridService secondaryGrid(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]) {
    final api = IsarSecondaryGridService.booru(booru, name, create);
    if (safeMode != null) {
      api.currentState.copy(safeMode: safeMode).saveSecondary(api);
    }

    return api;
  }
}

mixin IoServicesImplTableObjInstExt implements ServicesObjFactoryExt {
  @override
  GridBookmark makeGridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
    required List<GridBookmarkThumbnail> thumbnails,
  }) =>
      IsarBookmark(
        thumbnails: thumbnails.cast(),
        booru: booru,
        tags: tags,
        name: name,
        time: time,
      );

  @override
  GridBookmarkThumbnail makeGridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) =>
      IsarGridBookmarkThumbnail(url: url, rating: rating);

  @override
  TagManager makeTagManager(Booru booru) => IsarTagManager(booru);

  @override
  LocalTagsData makeLocalTagsData(
    String filename,
    List<String> tags,
  ) =>
      IsarLocalTags(filename, tags);

  @override
  CompactMangaData makeCompactMangaData({
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
  DownloadFileData makeDownloadFileData({
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
  HiddenBooruPostData makeHiddenBooruPostData(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      IsarHiddenBooruPost(booru, postId, thumbUrl);

  @override
  PinnedManga makePinnedManga({
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

  @override
  BlacklistedDirectoryData makeBlacklistedDirectoryData(
    String bucketId,
    String name,
  ) =>
      IsarBlacklistedDirectory(bucketId, name);

  @override
  AnimeGenre makeAnimeGenre({
    required String title,
    required int id,
    required bool unpressable,
    required bool explicit,
  }) =>
      IsarAnimeGenre(
        title: title,
        id: id,
        unpressable: unpressable,
        explicit: explicit,
      );

  @override
  AnimeRelation makeAnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  }) =>
      IsarAnimeRelation(
        thumbUrl: thumbUrl,
        title: title,
        type: type,
        id: id,
      );

  @override
  AnimeCharacter makeAnimeCharacter({
    required String imageUrl,
    required String name,
    required String role,
  }) =>
      IsarAnimeCharacter(
        imageUrl: imageUrl,
        name: name,
        role: role,
      );
}
