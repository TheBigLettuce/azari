// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/impl/isar/impl.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/visited_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/hottest_tag.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
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
  factory IoServicesImplTable() {
    if (_instance != null) {
      return _instance!;
    }

    return _instance = IoServicesImplTable._();
  }
  IoServicesImplTable._();

  static IoServicesImplTable? _instance;

  @override
  final IsarSettingsService settings = IsarSettingsService();
  @override
  IsarMiscSettingsService get miscSettings => const IsarMiscSettingsService();
  @override
  VideoSettingsService get videoSettings => const IsarVideoService();
  @override
  HiddenBooruPostService get hiddenBooruPost =>
      const IsarHiddenBooruPostService();
  @override
  DownloadFileService get downloads => const IsarDownloadFileService();
  @override
  final FavoritePostSourceService favoritePosts = IsarFavoritePostService();
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
  ThumbnailService get thumbnails => const IsarThumbnailService();
  @override
  // PinnedThumbnailService get pinnedThumbnails =>
  //     const IsarPinnedThumbnailService();
  @override
  LocalTagsService get localTags => const IsarLocalTagsService();
  @override
  LocalTagDictionaryService get localTagDictionary =>
      const IsarLocalTagDictionaryService();
  @override
  GridBookmarkService get gridBookmarks => const IsarGridStateBooruService();
  @override
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  @override
  final BlacklistedDirectoryService blacklistedDirectories =
      IsarBlacklistedDirectoryService();
  @override
  GridSettingsService get gridSettings => const IsarGridSettinsService();

  @override
  final TagManager tagManager = const IsarTagManager();

  @override
  VisitedPostsService get visitedPosts => const IsarVisitedPostsService();

  @override
  HottestTagsService get hottestTags => const IsarHottestTagsService();

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
    required int count,
    required Booru booru,
  }) = IsarHottestTag.noIdList;
}

abstract class $ThumbUrlRating extends ThumbUrlRating {
  const factory $ThumbUrlRating({
    required int postId,
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
  }) = IsarBookmark.noIdList;
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
    required int size,
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
    required int size,
  }) = IsarFavoritePost.noId;
}

abstract class $VisitedPost extends VisitedPost {
  const factory $VisitedPost({
    required Booru booru,
    required int id,
    required String thumbUrl,
    required DateTime date,
    required PostRating rating,
  }) = IsarVisitedPost.noId;
}
