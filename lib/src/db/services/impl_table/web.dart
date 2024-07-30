// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/net/manga/manga_api.dart";

Future<DownloadManager> init(ServicesImplTable db, bool temporary) =>
    throw UnimplementedError();

ServicesImplTable getApi() => throw UnimplementedError();

class $SavedAnimeEntryData extends AnimeEntryDataImpl
    with DefaultSavedAnimeEntryPressable
    implements SavedAnimeEntryData {
  const $SavedAnimeEntryData({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.inBacklog,
    required this.relations,
    required this.explicit,
    required this.type,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.background,
    required this.trailerUrl,
    required this.episodes,
    required this.genres,
    required this.staff,
  });

  @override
  final bool inBacklog;

  @override
  final String background;

  @override
  final int episodes;

  @override
  final AnimeSafeMode explicit;

  @override
  final int id;

  @override
  final bool isAiring;

  @override
  final double score;

  @override
  final AnimeMetadata site;

  @override
  final String siteUrl;

  @override
  final String synopsis;

  @override
  final String thumbUrl;

  @override
  final String title;

  @override
  final String titleEnglish;

  @override
  final String titleJapanese;

  @override
  final List<String> titleSynonyms;

  @override
  final String trailerUrl;

  @override
  final String type;

  @override
  final List<AnimeGenre> genres;

  @override
  final List<AnimeRelation> relations;

  @override
  final List<AnimeRelation> staff;

  @override
  final DateTime? airedFrom;

  @override
  final DateTime? airedTo;

  @override
  final String imageUrl;

  @override
  SavedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) =>
      $SavedAnimeEntryData(
        imageUrl: e.imageUrl,
        genres: e.genres,
        relations: ignoreRelations ? relations : e.relations,
        staff: e.staff,
        inBacklog: inBacklog,
        site: e.site,
        type: e.type,
        thumbUrl: e.thumbUrl,
        title: e.title,
        titleJapanese: e.titleJapanese,
        titleEnglish: e.titleEnglish,
        score: e.score,
        synopsis: e.synopsis,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        airedFrom: e.airedFrom,
        airedTo: e.airedTo,
      );

  @override
  SavedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? siteUrl,
    String? imageUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    int? year,
    double? score,
    String? thumbUrl,
    String? synopsis,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  }) =>
      $SavedAnimeEntryData(
        imageUrl: imageUrl ?? this.imageUrl,
        airedFrom: airedFrom ?? this.airedFrom,
        airedTo: airedTo ?? this.airedTo,
        genres: genres ?? this.genres,
        relations: relations ?? this.relations,
        staff: staff ?? this.staff,
        inBacklog: inBacklog ?? this.inBacklog,
        site: site ?? this.site,
        type: type ?? this.type,
        thumbUrl: thumbUrl ?? this.thumbUrl,
        title: title ?? this.title,
        titleJapanese: titleJapanese ?? this.titleJapanese,
        titleEnglish: titleEnglish ?? this.titleEnglish,
        score: score ?? this.score,
        synopsis: synopsis ?? this.synopsis,
        id: id ?? this.id,
        siteUrl: siteUrl ?? this.siteUrl,
        isAiring: isAiring ?? this.isAiring,
        titleSynonyms: titleSynonyms ?? this.titleSynonyms,
        trailerUrl: trailerUrl ?? this.trailerUrl,
        episodes: episodes ?? this.episodes,
        background: background ?? this.background,
        explicit: explicit ?? this.explicit,
      );
}

class $AnimeCharacter extends AnimeCharacterImpl implements AnimeCharacter {
  const $AnimeCharacter({
    required this.imageUrl,
    required this.name,
    required this.role,
  });

  @override
  final String imageUrl;

  @override
  final String name;

  @override
  final String role;
}

class $BlacklistedDirectoryData extends BlacklistedDirectoryDataImpl
    implements BlacklistedDirectoryData {
  const $BlacklistedDirectoryData({
    required this.bucketId,
    required this.name,
  });

  @override
  final String bucketId;

  @override
  final String name;
}

class $DirectoryMetadataData extends DirectoryMetadata {
  const $DirectoryMetadataData({
    required this.categoryName,
    required this.time,
    required this.blur,
    required this.sticky,
    required this.requireAuth,
  });

  @override
  final bool blur;

  @override
  final String categoryName;

  @override
  final bool requireAuth;

  @override
  final bool sticky;

  @override
  final DateTime time;

  @override
  DirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) =>
      $DirectoryMetadataData(
        categoryName: categoryName,
        time: DateTime.now(),
        blur: blur ?? this.blur,
        sticky: sticky ?? this.sticky,
        requireAuth: requireAuth ?? this.requireAuth,
      );
}

class $ReadMangaChapterData extends ReadMangaChapterData {
  const $ReadMangaChapterData({
    required this.siteMangaId,
    required this.chapterId,
    required this.chapterProgress,
    required this.lastUpdated,
    required this.chapterName,
    required this.chapterNumber,
  });

  @override
  final String chapterId;

  @override
  final String chapterName;

  @override
  final String chapterNumber;

  @override
  final int chapterProgress;

  @override
  final DateTime lastUpdated;

  @override
  final String siteMangaId;
}

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

class $CompactMangaData extends CompactMangaDataImpl
    implements CompactMangaData {
  const $CompactMangaData({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
  });

  @override
  final String mangaId;

  @override
  final MangaMeta site;

  @override
  final String thumbUrl;

  @override
  final String title;
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

class $PinnedManga extends PinnedMangaImpl implements PinnedManga {
  const $PinnedManga({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
  });

  @override
  final String mangaId;

  @override
  final MangaMeta site;

  @override
  final String thumbUrl;

  @override
  final String title;
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

class $WatchedAnimeEntryData extends AnimeEntryDataImpl
    with DefaultWatchedAnimeEntryPressable
    implements WatchedAnimeEntryData {
  const $WatchedAnimeEntryData({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.date,
    required this.relations,
    required this.explicit,
    required this.type,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.background,
    required this.trailerUrl,
    required this.episodes,
    required this.genres,
    required this.staff,
  });

  @override
  final String background;

  @override
  final DateTime date;

  @override
  final int episodes;

  @override
  final AnimeSafeMode explicit;

  @override
  final int id;

  @override
  final bool isAiring;

  @override
  final double score;

  @override
  final AnimeMetadata site;

  @override
  final String siteUrl;

  @override
  final String synopsis;

  @override
  final String thumbUrl;

  @override
  final String title;

  @override
  final String titleEnglish;

  @override
  final String titleJapanese;

  @override
  final List<String> titleSynonyms;

  @override
  final String trailerUrl;

  @override
  final String type;

  @override
  final List<AnimeGenre> genres;

  @override
  final List<AnimeRelation> relations;

  @override
  final List<AnimeRelation> staff;

  @override
  final DateTime? airedFrom;

  @override
  final DateTime? airedTo;

  @override
  final String imageUrl;

  @override
  WatchedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? imageUrl,
    String? siteUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    int? year,
    double? score,
    String? thumbUrl,
    String? synopsis,
    DateTime? date,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  }) =>
      $WatchedAnimeEntryData(
        imageUrl: imageUrl ?? this.imageUrl,
        genres: genres ?? this.genres,
        relations: relations ?? this.relations,
        staff: staff ?? this.staff,
        site: site ?? this.site,
        type: type ?? this.type,
        thumbUrl: thumbUrl ?? this.thumbUrl,
        title: title ?? this.title,
        titleJapanese: titleJapanese ?? this.titleJapanese,
        titleEnglish: titleEnglish ?? this.titleEnglish,
        score: score ?? this.score,
        synopsis: synopsis ?? this.synopsis,
        id: id ?? this.id,
        siteUrl: siteUrl ?? this.siteUrl,
        isAiring: isAiring ?? this.isAiring,
        titleSynonyms: titleSynonyms ?? this.titleSynonyms,
        trailerUrl: trailerUrl ?? this.trailerUrl,
        episodes: episodes ?? this.episodes,
        background: background ?? this.background,
        explicit: explicit ?? this.explicit,
        date: date ?? this.date,
        airedFrom: airedFrom ?? this.airedFrom,
        airedTo: airedTo ?? this.airedTo,
      );

  @override
  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) =>
      $WatchedAnimeEntryData(
        imageUrl: e.imageUrl,
        genres: e.genres,
        relations: ignoreRelations ? relations : e.relations,
        staff: e.staff,
        site: e.site,
        type: e.type,
        thumbUrl: e.thumbUrl,
        title: e.title,
        titleJapanese: e.titleJapanese,
        titleEnglish: e.titleEnglish,
        score: e.score,
        synopsis: e.synopsis,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: date,
        airedFrom: e.airedFrom,
        airedTo: e.airedTo,
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

class $TagData implements TagData {
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
  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
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
      );
}

class $ChaptersSettingsData extends ChaptersSettingsData {
  const $ChaptersSettingsData({required super.hideRead});

  @override
  ChaptersSettingsData copy({bool? hideRead}) =>
      $ChaptersSettingsData(hideRead: hideRead ?? this.hideRead);
}

class $BooruTag extends BooruTag {
  const $BooruTag(super.tag, super.count);
}

class $AnimeGenre implements AnimeGenre {
  const $AnimeGenre({
    required this.id,
    required this.title,
    required this.unpressable,
    required this.explicit,
  });

  @override
  final bool explicit;

  @override
  final int id;

  @override
  final String title;

  @override
  final bool unpressable;
}

class $AnimeRelation implements AnimeRelation {
  const $AnimeRelation({
    required this.id,
    required this.thumbUrl,
    required this.title,
    required this.type,
  });

  @override
  final int id;

  @override
  final String thumbUrl;

  @override
  final String title;

  @override
  final String type;
}

class $HottestTag implements HottestTag {
  const $HottestTag({
    required this.tag,
    required this.thumbUrls,
    required this.count,
  });

  @override
  final int count;

  @override
  final String tag;

  @override
  final List<ThumbUrlRating> thumbUrls;
}

class $ThumbUrlRating implements ThumbUrlRating {
  const $ThumbUrlRating({
    required this.url,
    required this.rating,
  });

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
