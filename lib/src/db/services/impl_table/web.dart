// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";

Future<DownloadManager> init(ServicesImplTable db, bool temporary) =>
    throw UnimplementedError();

ServicesImplTable getApi() => throw UnimplementedError();

class $PinnedThumbnailData implements PinnedThumbnailData {
  const $PinnedThumbnailData({
    required this.id,
    required this.differenceHash,
    required this.path,
  });

  @override
  final int differenceHash;

  @override
  final int id;

  @override
  final String path;
}

class $ThumbnailData implements ThumbnailData {
  const $ThumbnailData({
    required this.id,
    required this.updatedAt,
    required this.path,
    required this.differenceHash,
  });

  @override
  final int differenceHash;

  @override
  final int id;

  @override
  final String path;

  @override
  final DateTime updatedAt;
}

class $SettingsData extends SettingsData {
  const $SettingsData({
    required this.path,
    required this.selectedBooru,
    required this.quality,
    required this.safeMode,
    required this.showWelcomePage,
    required this.extraSafeFilters,
  });

  @override
  final bool extraSafeFilters;

  @override
  final DisplayQuality quality;

  @override
  final SafeMode safeMode;

  @override
  final Booru selectedBooru;

  @override
  final bool showWelcomePage;

  @override
  final SettingsPath path;

  @override
  SettingsData copy({
    bool? extraSafeFilters,
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
  }) =>
      $SettingsData(
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        safeMode: safeMode ?? this.safeMode,
        showWelcomePage: showWelcomePage ?? this.showWelcomePage,
        path: this.path,
        extraSafeFilters: extraSafeFilters ?? this.extraSafeFilters,
      );
}

class $LocalTagsData implements LocalTagsData {
  const $LocalTagsData({
    required this.filename,
    required this.tags,
  });

  @override
  final String filename;

  @override
  final List<String> tags;
}

class $HiddenBooruPostData extends HiddenBooruPostDataImpl
    implements HiddenBooruPostData {
  const $HiddenBooruPostData({
    required this.booru,
    required this.postId,
    required this.thumbUrl,
  });

  @override
  final Booru booru;

  @override
  final int postId;

  @override
  final String thumbUrl;
}

class $DownloadFileData extends DownloadFileDataImpl
    implements DownloadFileData {
  const $DownloadFileData({
    required this.status,
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.date,
  });

  @override
  final DateTime date;

  @override
  final String name;

  @override
  final String site;

  @override
  final DownloadStatus status;

  @override
  final String thumbUrl;

  @override
  final String url;

  @override
  DownloadFileData toFailed() => $DownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.failed,
      );

  @override
  DownloadFileData toInProgress() => $DownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.inProgress,
      );

  @override
  DownloadFileData toOnHold() => $DownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.onHold,
      );
}

class $GridBookmarkThumbnail implements GridBookmarkThumbnail {
  const $GridBookmarkThumbnail({
    required this.url,
    required this.rating,
  });

  @override
  final PostRating rating;

  @override
  final String url;
}

class $GridBookmark extends GridBookmarkImpl implements GridBookmark {
  const $GridBookmark({
    required this.name,
    required this.time,
    required this.tags,
    required this.booru,
    required this.thumbnails,
  });

  @override
  final Booru booru;

  @override
  final String name;

  @override
  final String tags;

  @override
  final DateTime time;

  @override
  final List<GridBookmarkThumbnail> thumbnails;

  @override
  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
    List<GridBookmarkThumbnail>? thumbnails,
  }) =>
      $GridBookmark(
        thumbnails: thumbnails?.cast() ?? this.thumbnails,
        tags: tags ?? this.tags,
        booru: booru ?? this.booru,
        name: name ?? this.name,
        time: time ?? this.time,
      );
}

class $FavoritePost extends PostImpl
    with DefaultPostPressable<FavoritePost>
    implements FavoritePost {
  const $FavoritePost({
    required this.height,
    required this.id,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    required this.type,
  });

  @override
  final Booru booru;

  @override
  final DateTime createdAt;

  @override
  final String fileUrl;

  @override
  final int height;

  @override
  final int id;

  @override
  final String md5;

  @override
  final String previewUrl;

  @override
  final PostRating rating;

  @override
  final String sampleUrl;

  @override
  final int score;

  @override
  final String sourceUrl;

  @override
  final List<String> tags;

  @override
  final PostContentType type;

  @override
  final int width;
}

class $GridState implements GridState {
  const $GridState({
    required this.tags,
    required this.safeMode,
    required this.offset,
    required this.name,
  });

  @override
  final String name;

  @override
  final double offset;

  @override
  final SafeMode safeMode;

  @override
  final String tags;

  @override
  GridState copy({
    String? name,
    String? tags,
    double? offset,
    SafeMode? safeMode,
  }) =>
      $GridState(
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        offset: offset ?? this.offset,
        name: name ?? this.name,
      );
}

class $StatisticsBooruData extends StatisticsBooruData {
  const $StatisticsBooruData({
    required super.booruSwitches,
    required super.downloaded,
    required super.swiped,
    required super.viewed,
  });

  @override
  StatisticsBooruData add({
    int? viewed,
    int? downloaded,
    int? swiped,
    int? booruSwitches,
  }) =>
      $StatisticsBooruData(
        booruSwitches: booruSwitches ?? this.booruSwitches,
        downloaded: downloaded ?? this.downloaded,
        swiped: swiped ?? this.swiped,
        viewed: viewed ?? this.viewed,
      );
}

class $StatisticsDailyData extends StatisticsDailyData {
  const $StatisticsDailyData({
    required super.swipedBoth,
    required super.durationMillis,
    required super.date,
  });

  @override
  StatisticsDailyData add({required int swipedBoth}) => $StatisticsDailyData(
        swipedBoth: this.swipedBoth + swipedBoth,
        durationMillis: durationMillis,
        date: date,
      );

  @override
  StatisticsDailyData copy({
    int? durationMillis,
    int? swipedBoth,
    DateTime? date,
  }) =>
      $StatisticsDailyData(
        swipedBoth: swipedBoth ?? this.swipedBoth,
        durationMillis: durationMillis ?? this.durationMillis,
        date: date ?? this.date,
      );
}

class $TagData extends TagDataImpl implements TagData {
  const $TagData({
    required this.time,
    required this.tag,
    required this.type,
  });

  @override
  final String tag;

  @override
  final DateTime time;

  @override
  final TagType type;

  @override
  TagData copy({String? tag, TagType? type}) => $TagData(
        time: time,
        tag: tag ?? this.tag,
        type: type ?? this.type,
      );
}

class MemoryTagManager implements TagManager {
  MemoryTagManager();

  @override
  final BooruTagging excluded = throw UnimplementedError();

  @override
  final BooruTagging latest = throw UnimplementedError();

  @override
  final BooruTagging pinned = throw UnimplementedError();
}

class $SettingsPath extends SettingsPath {
  const $SettingsPath(this.path, this.pathDisplay);

  @override
  final String path;

  @override
  final String pathDisplay;

  @override
  SettingsPath copy({String? path, String? pathDisplay}) {
    return $SettingsPath(path ?? this.path, pathDisplay ?? this.pathDisplay);
  }
}

class $MiscSettingsData extends MiscSettingsData {
  const $MiscSettingsData({
    required this.filesExtendedActions,
    required this.animeAlwaysLoadFromNet,
    required this.favoritesThumbId,
    required this.themeType,
    required this.favoritesPageMode,
    required this.animeWatchingOrderReversed,
    required this.randomVideosAddTags,
    required this.randomVideosOrder,
  });

  @override
  final bool animeAlwaysLoadFromNet;

  @override
  final bool animeWatchingOrderReversed;

  @override
  final FilteringMode favoritesPageMode;

  @override
  final int favoritesThumbId;

  @override
  final bool filesExtendedActions;

  @override
  final ThemeType themeType;

  @override
  final String randomVideosAddTags;

  @override
  final RandomPostsOrder randomVideosOrder;

  @override
  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
    String? randomVideosAddTags,
    RandomPostsOrder? randomVideosOrder,
  }) =>
      $MiscSettingsData(
        filesExtendedActions: filesExtendedActions ?? this.filesExtendedActions,
        animeAlwaysLoadFromNet:
            animeAlwaysLoadFromNet ?? this.animeAlwaysLoadFromNet,
        favoritesThumbId: favoritesThumbId ?? this.favoritesThumbId,
        themeType: themeType ?? this.themeType,
        favoritesPageMode: favoritesPageMode ?? this.favoritesPageMode,
        animeWatchingOrderReversed:
            animeWatchingOrderReversed ?? this.animeWatchingOrderReversed,
        randomVideosAddTags: randomVideosAddTags ?? this.randomVideosAddTags,
        randomVideosOrder: randomVideosOrder ?? this.randomVideosOrder,
      );
}

class $BooruTag extends BooruTag {
  const $BooruTag(super.tag, super.count);
}

class $HottestTag implements HottestTag {
  const $HottestTag({
    required this.tag,
    required this.thumbUrls,
    required this.count,
    required this.booru,
  });

  @override
  final int count;

  @override
  final String tag;

  @override
  final List<ThumbUrlRating> thumbUrls;

  @override
  final Booru booru;

  @override
  HottestTag copy({
    String? tag,
    int? count,
    Booru? booru,
    List<ThumbUrlRating>? thumbUrls,
  }) =>
      $HottestTag(
        tag: tag ?? this.tag,
        thumbUrls: thumbUrls ?? this.thumbUrls,
        count: count ?? this.count,
        booru: booru ?? this.booru,
      );
}

class $ThumbUrlRating implements ThumbUrlRating {
  const $ThumbUrlRating({
    required this.postId,
    required this.url,
    required this.rating,
  });

  @override
  final int postId;

  @override
  final PostRating rating;

  @override
  final String url;
}

class $Post extends PostImpl with DefaultPostPressable<Post> implements Post {
  const $Post({
    required this.height,
    required this.id,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    required this.type,
  });

  @override
  final Booru booru;

  @override
  final DateTime createdAt;

  @override
  final String fileUrl;

  @override
  final int height;

  @override
  final int id;

  @override
  final String md5;

  @override
  final String previewUrl;

  @override
  final PostRating rating;

  @override
  final String sampleUrl;

  @override
  final int score;

  @override
  final String sourceUrl;

  @override
  final List<String> tags;

  @override
  final PostContentType type;

  @override
  final int width;
}
