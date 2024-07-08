// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_characters.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/watched_anime_entry.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/favorite_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/bookmark.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_state.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/hottest_tag.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/net/manga/manga_api.dart";
import "package:path_provider/path_provider.dart";

Future<DownloadManager> init(ServicesImplTable db, bool temporary) async {
  return await initalizeIsarDb(
    temporary,
    db,
    (await getApplicationSupportDirectory()).path,
    (await getTemporaryDirectory()).path,
  );
}

ServicesImplTable getApi() => IoServicesImplTable();

class IoServicesImplTable implements ServicesImplTable {
  IoServicesImplTable();

  @override
  IsarSettingsService get settings => const IsarSettingsService();
  @override
  IsarMiscSettingsService get miscSettings => const IsarMiscSettingsService();
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
  final TagManager tagManager = const IsarTagManager();

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

abstract class $HottestTag extends HottestTag {
  const factory $HottestTag({
    required String tag,
    required List<ThumbUrlRating> thumbUrls,
    required int count,
  }) = IsarHottestTag.noId;
}

abstract class $ThumbUrlRating extends ThumbUrlRating {
  const factory $ThumbUrlRating({
    required String url,
    required PostRating rating,
  }) = IsarThumbUrlRating.required;
}

abstract class $GridState extends GridState {
  const factory $GridState({
    required String name,
    required double offset,
    required String tags,
    required SafeMode safeMode,
  }) = IsarGridState.noId;
}

abstract class $GridBookmarkThumbnail extends GridBookmarkThumbnail {
  const factory $GridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) = IsarGridBookmarkThumbnail.required;
}

abstract class $GridBookmark extends GridBookmark {
  const factory $GridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
    required List<GridBookmarkThumbnail> thumbnails,
  }) = IsarBookmark.noId;
}

abstract class $LocalTagsData extends LocalTagsData {
  const factory $LocalTagsData({
    required String filename,
    required List<String> tags,
  }) = IsarLocalTags.noId;
}

abstract class $TagData extends TagData {
  const factory $TagData({
    required String tag,
    required TagType type,
    required DateTime time,
  }) = IsarTag.noId;
}

abstract class $AnimeGenre extends AnimeGenre {
  const factory $AnimeGenre({
    required int id,
    required String title,
    required bool unpressable,
    required bool explicit,
  }) = IsarAnimeGenre.required;
}

abstract class $AnimeRelation extends AnimeRelation {
  const factory $AnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  }) = IsarAnimeRelation.required;
}

abstract class $AnimeCharacter extends AnimeCharacter {
  const factory $AnimeCharacter({
    required String imageUrl,
    required String name,
    required String role,
  }) = IsarAnimeCharacter;
}

abstract class $HiddenBooruPostData extends HiddenBooruPostData {
  const factory $HiddenBooruPostData({
    required Booru booru,
    required int postId,
    required String thumbUrl,
  }) = IsarHiddenBooruPost.noId;
}

abstract class $DownloadFileData extends DownloadFileData {
  const factory $DownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) = IsarDownloadFile.noId;
}

abstract class $BlacklistedDirectoryData extends BlacklistedDirectoryData {
  const factory $BlacklistedDirectoryData({
    required String bucketId,
    required String name,
  }) = IsarBlacklistedDirectory.noId;
}

abstract class $CompactMangaData extends CompactMangaData {
  const factory $CompactMangaData({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) = IsarCompactMangaData.noId;
}

abstract class $PinnedManga extends PinnedManga {
  const factory $PinnedManga({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) = IsarPinnedManga.noId;
}

abstract class $WatchedAnimeEntryData extends WatchedAnimeEntryData {
  const factory $WatchedAnimeEntryData({
    required DateTime date,
    required AnimeMetadata site,
    required String type,
    required String thumbUrl,
    required String title,
    required String titleJapanese,
    required String titleEnglish,
    required double score,
    required String synopsis,
    required int year,
    required int id,
    required String siteUrl,
    required bool isAiring,
    required List<String> titleSynonyms,
    required String trailerUrl,
    required int episodes,
    required String background,
    required AnimeSafeMode explicit,
    required List<AnimeRelation> relations,
    required List<AnimeRelation> staff,
    required List<AnimeGenre> genres,
  }) = IsarWatchedAnimeEntry.noId;
}

abstract class $SavedAnimeEntryData extends SavedAnimeEntryData {
  const factory $SavedAnimeEntryData({
    required bool inBacklog,
    required AnimeMetadata site,
    required String type,
    required String thumbUrl,
    required String title,
    required String titleJapanese,
    required String titleEnglish,
    required double score,
    required String synopsis,
    required int year,
    required int id,
    required String siteUrl,
    required bool isAiring,
    required List<String> titleSynonyms,
    required String trailerUrl,
    required int episodes,
    required String background,
    required AnimeSafeMode explicit,
    required List<AnimeRelation> relations,
    required List<AnimeRelation> staff,
    required List<AnimeGenre> genres,
  }) = IsarSavedAnimeEntry.noId;
}

abstract class $Post extends Post {
  const factory $Post({
    required int id,
    required String md5,
    required List<String> tags,
    required int width,
    required int height,
    required String fileUrl,
    required String previewUrl,
    required String sampleUrl,
    required String sourceUrl,
    required PostRating rating,
    required int score,
    required DateTime createdAt,
    required Booru booru,
    required PostContentType type,
  }) = PostIsar.noId;
}

abstract class $FavoritePost extends FavoritePost {
  const factory $FavoritePost({
    required int id,
    required String md5,
    required List<String> tags,
    required int width,
    required int height,
    required String fileUrl,
    required String previewUrl,
    required String sampleUrl,
    required String sourceUrl,
    required PostRating rating,
    required int score,
    required DateTime createdAt,
    required Booru booru,
    required PostContentType type,
  }) = IsarFavoritePost.noId;
}
