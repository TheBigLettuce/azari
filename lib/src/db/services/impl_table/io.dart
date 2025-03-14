// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:azari/src/db/services/impl/isar/impl.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/visited_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/directory_metadata.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/hottest_tag.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:azari/src/db/services/obj_impls/directory_impl.dart";
import "package:azari/src/db/services/obj_impls/file_impl.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/platform/gallery/android/android_gallery.dart";
import "package:azari/src/platform/gallery/io.dart";
import "package:azari/src/platform/gallery/linux/impl.dart";
import "package:path_provider/path_provider.dart";

Future<DownloadManager?> init(
  Services db,
  AppInstanceType appType,
) async {
  initApi();
  return await initalizeIsarDb(
    appType,
    db,
    (await getApplicationSupportDirectory()).path,
    (await getTemporaryDirectory()).path,
  );
}

Services getApi() => IoServices();

class IoServices implements Services {
  factory IoServices() {
    if (_instance != null) {
      return _instance!;
    }

    return _instance = IoServices._();
  }

  IoServices._();

  static IoServices? _instance;

  @override
  T? get<T extends ServiceMarker>() {
    // dart doesn't support switch on types
    if (T == StatisticsBooruService) {
      return statisticsBooru as T;
    } else if (T == StatisticsGeneralService) {
      return statisticsGeneral as T;
    } else if (T == StatisticsGalleryService) {
      return statisticsGallery as T;
    } else if (T == StatisticsDailyService) {
      return statisticsDaily as T;
    } else if (T == DirectoryMetadataService) {
      return directoryMetadata as T;
    } else if (T == ThumbnailService) {
      return thumbnails as T;
    } else if (T == VisitedPostsService) {
      return visitedPosts as T;
    } else if (T == GalleryService) {
      return galleryService as T;
    } else if (T == LocalTagsService) {
      return localTags as T;
    } else if (T == HottestTagsService) {
      return hottestTags as T;
    } else if (T == GridBookmarkService) {
      return gridBookmarks as T;
    } else if (T == DirectoryTagService) {
      return directoryTags as T;
    } else if (T == BlacklistedDirectoryService) {
      return blacklistedDirectories as T;
    } else if (T == GridSettingsService) {
      return gridSettings as T;
    } else if (T == TagManagerService) {
      return tagManager as T;
    } else if (T == GridDbService) {
      return gridDbs as T;
    } else if (T == FavoritePostSourceService) {
      return favoritePosts as T;
    } else if (T == DownloadFileService) {
      return downloads as T;
    } else if (T == HiddenBooruPostsService) {
      return hiddenBooruPosts as T;
    } else if (T == VideoSettingsService) {
      return videoSettings as T;
    } else {
      return this as T;
    }
  }

  @override
  T require<T extends RequiredService>() {
    if (T == SettingsService) {
      return settings as T;
    }

    throw "unimplemented";
  }

  final IsarSettingsService settings = IsarSettingsService();
  VideoSettingsService get videoSettings => const IsarVideoService();
  HiddenBooruPostsService get hiddenBooruPosts =>
      const IsarHiddenBooruPostService();
  DownloadFileService get downloads => const IsarDownloadFileService();
  final FavoritePostSourceService favoritePosts = IsarFavoritePostService();
  StatisticsGeneralService get statisticsGeneral =>
      const IsarStatisticsGeneralService();
  StatisticsGalleryService get statisticsGallery =>
      const IsarStatisticsGalleryService();
  StatisticsBooruService get statisticsBooru =>
      const IsarStatisticsBooruService();
  StatisticsDailyService get statisticsDaily =>
      const IsarDailyStatisticsService();
  final IsarDirectoryMetadataService directoryMetadata =
      IsarDirectoryMetadataService();
  ThumbnailService get thumbnails => const IsarThumbnailService();
  LocalTagsService get localTags => const IsarLocalTagsService();
  GridBookmarkService get gridBookmarks => const IsarGridStateBooruService();
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  final BlacklistedDirectoryService blacklistedDirectories =
      IsarBlacklistedDirectoryService();
  GridSettingsService get gridSettings => const IsarGridSettinsService();
  final TagManagerService tagManager = const IsarTagManager();

  VisitedPostsService get visitedPosts => const IsarVisitedPostsService();

  HottestTagsService get hottestTags => const IsarHottestTagsService();

  IsarGridDbsService get gridDbs => const IsarGridDbsService();

  late final GalleryService galleryService = Platform.isAndroid
      ? AndroidGalleryApi(localTagsService: localTags)
      : const LinuxGalleryApi();
}

class IsarGridDbsService implements GridDbService {
  const IsarGridDbsService();

  @override
  MainGridHandle openMain(Booru booru) => IsarMainGridService.booru(booru);

  @override
  SecondaryGridHandle openSecondary(
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
    required FavoriteStars stars,
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

abstract class $DirectoryMetadata extends DirectoryMetadata {
  const factory $DirectoryMetadata({
    required String categoryName,
    required DateTime time,
  }) = IsarDirectoryMetadata.noIdFlags;
}

class $Directory extends DirectoryImpl
    with PigeonDirectoryPressable
    implements Directory {
  const $Directory({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  @override
  final String bucketId;

  @override
  final int lastModified;

  @override
  final String name;

  @override
  final String relativeLoc;

  @override
  final String tag;

  @override
  final int thumbFileId;

  @override
  final String volumeName;
}

class $File extends FileImpl with PigeonFilePressable implements File {
  const $File({
    required this.bucketId,
    required this.height,
    required this.id,
    required this.isDuplicate,
    required this.isGif,
    required this.isVideo,
    required this.lastModified,
    required this.name,
    required this.originalUri,
    required this.res,
    required this.size,
    required this.tags,
    required this.width,
  });

  @override
  final String bucketId;

  @override
  final int height;

  @override
  final int id;

  @override
  final bool isDuplicate;

  @override
  final bool isGif;

  @override
  final bool isVideo;

  @override
  final int lastModified;

  @override
  final String name;

  @override
  final String originalUri;

  @override
  final (int, Booru)? res;

  @override
  final int size;

  @override
  final Map<String, void> tags;

  @override
  final int width;
}
