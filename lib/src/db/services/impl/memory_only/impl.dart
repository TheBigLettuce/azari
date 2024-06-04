// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:async/async.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";

final _futures = <(int, AnimeMetadata), Future<void>>{};

class MemoryOnlyServicesImplTable
    with MemoryOnlyServicesImplTableObjInstExt
    implements ServicesImplTable {
  Future<DownloadManager> init() => Future.value(_downloadManager);

  @override
  final DownloadFileService downloads = MemoryDownloadFileService();
  late final DownloadManager _downloadManager = DownloadManager(downloads);

  @override
  final SettingsService settings = MemorySettingsService();
  @override
  final MiscSettingsService miscSettings = MemoryMiscSettingsService();

  @override
  final SavedAnimeEntriesService savedAnimeEntries =
      MemorySavedAnimeEntriesService();
  @override
  final SavedAnimeCharactersService savedAnimeCharacters =
      MemorySavedAnimeCharactersService();
  @override
  final WatchedAnimeEntryService watchedAnime =
      MemoryWatchedAnimeEntryService();
  @override
  VideoSettingsService get videoSettings => throw UnimplementedError();
  @override
  final HiddenBooruPostService hiddenBooruPost = MemoryHiddenBooruPostService();
  @override
  final FavoritePostSourceService favoritePosts = MemoryFavoritePostService();

  @override
  final StatisticsGeneralService statisticsGeneral =
      MemoryStatisticsGeneralService();
  @override
  final StatisticsGalleryService statisticsGallery =
      MemoryStatisticsGalleryService();
  @override
  final StatisticsBooruService statisticsBooru = MemoryStatisticsBooruService();
  @override
  final StatisticsDailyService statisticsDaily = MemoryStatisticsDailyService();

  @override
  final DirectoryMetadataService directoryMetadata =
      MemoryDirectoryMetadataService();
  @override
  final ChaptersSettingsService chaptersSettings =
      MemoryChaptersSettingsService();
  @override
  final SavedMangaChaptersService savedMangaChapters =
      MemorySavedMangaChaptersService();
  @override
  final ReadMangaChaptersService readMangaChapters =
      MemoryReadMangaChaptersService();
  @override
  final PinnedMangaService pinnedManga = MemoryPinnedMangaService();
  @override
  final ThumbnailService thumbnails = MemoryThumbnailService();
  @override
  final PinnedThumbnailService pinnedThumbnails =
      MemoryPinnedThumbnailService();

  @override
  final LocalTagsService localTags = MemoryLocalTagsService();
  @override
  final LocalTagDictionaryService localTagDictionary =
      MemoryLocalTagDictionaryService();

  @override
  final CompactMangaDataService compactManga = MemoryCompactMangaDataService();
  @override
  final GridBookmarkService gridBookmarks = MemoryGridStateBooruService();
  @override
  final FavoriteFileService favoriteFiles = MemoryFavoriteFileService();
  @override
  final DirectoryTagService directoryTags = MemoryDirectoryTagService();
  @override
  final BlacklistedDirectoryService blacklistedDirectories =
      MemoryBlacklistedDirectoryService();

  @override
  final GridSettingsService gridSettings = MemoryGridSettingsService();

  final Map<Booru, MainGridService> _gridServices = {};

  @override
  TagManager makeTagManager(Booru booru) => mainGrid(booru).tagManager;

  @override
  MainGridService mainGrid(Booru booru) =>
      _gridServices.putIfAbsent(booru, () => MemoryMainGridService(booru));
  @override
  SecondaryGridService secondaryGrid(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]) =>
      throw UnimplementedError();
}

mixin MemoryOnlyServicesImplTableObjInstExt implements ServicesObjFactoryExt {
  @override
  GridBookmark makeGridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
  }) =>
      PlainGridBookmark(
        tags: tags,
        booru: booru,
        name: name,
        time: time,
      );

  @override
  LocalTagsData makeLocalTagsData(
    String filename,
    List<String> tags,
  ) =>
      PlainLocalTagsData(filename, tags);

  @override
  CompactMangaData makeCompactMangaData({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) =>
      PlainCompactMangaData(
        mangaId: mangaId,
        site: site,
        thumbUrl: thumbUrl,
        title: title,
      );

  @override
  SettingsPath makeSettingsPath({
    required String path,
    required String pathDisplay,
  }) =>
      PlainSettingsPath(path, pathDisplay);

  @override
  DownloadFileData makeDownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) =>
      PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.inProgress,
      );

  @override
  HiddenBooruPostData makeHiddenBooruPostData(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      PlainHiddenBooruPostData(booru, postId, thumbUrl);

  @override
  PinnedManga makePinnedManga({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  }) =>
      PlainPinnedManga(
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
      PlainBlacklistedDirectoryData(bucketId, name);

  @override
  AnimeGenre makeAnimeGenre({
    required String title,
    required int id,
    required bool unpressable,
    required bool explicit,
  }) =>
      throw UnimplementedError();

  @override
  AnimeRelation makeAnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  }) {
    // TODO: implement makeAnieRelation
    throw UnimplementedError();
  }

  @override
  AnimeCharacter makeAnimeCharacter({
    required String imageUrl,
    required String name,
    required String role,
  }) {
    // TODO: implement makeAnimeCharacter
    throw UnimplementedError();
  }
}

class MemoryDownloadFileService implements DownloadFileService {
  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  void deleteAll(List<String> urls) {
    // TODO: implement deleteAll
  }

  @override
  bool exist(String url) => false;

  @override
  List<DownloadFileData> get failedAll => const [];

  @override
  DownloadFileData? get(String url) => null;

  @override
  List<DownloadFileData> get inProgressAll => const [];

  @override
  DownloadFileData? next() => null;

  @override
  List<DownloadFileData> nextNumber(int minus) => const [];

  @override
  bool notExist(String url) => false;

  @override
  void saveAll(List<DownloadFileData> l) {
    // TODO: implement saveAll
  }

  @override
  void markInProgressAsFailed() {
    // TODO: implement markInProgressAsFailed
  }
}

class MemoryBooruTagging implements BooruTagging {
  MemoryBooruTagging(this.type);

  final _val = <String, void>{};
  final _events = StreamController<void>.broadcast();

  final TagType type;

  @override
  void add(String tag) {
    _val[tag] = null;
    _events.add(null);
  }

  @override
  void clear() {
    _val.clear();
    _events.add(null);
  }

  @override
  void delete(String tag) {
    _val.remove(tag);
    _events.add(null);
  }

  @override
  bool exists(String tag) => _val.containsKey(tag);

  @override
  List<TagData> get(int limit) => limit.isNegative
      ? _val.keys.map((e) => PlainTagData(tag: e, type: type)).toList()
      : _val.keys
          .take(limit)
          .map((e) => PlainTagData(tag: e, type: type))
          .toList();

  @override
  StreamSubscription<void> watch(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.listen(f);

  @override
  StreamSubscription<List<ImageTag>> watchImage(
    List<String> tags,
    void Function(List<ImageTag> p1) f, {
    bool fire = false,
  }) =>
      _events.stream
          .map(
            (e) => tags
                .map(
                  (e) => ImageTag(
                    e,
                    type == TagType.pinned && _val.containsKey(e),
                  ),
                )
                .toList(),
          )
          .listen(f);

  @override
  StreamSubscription<List<ImageTag>> watchImageLocal(
    String filename,
    void Function(List<ImageTag> p1) f, {
    required LocalTagsService localTag,
    bool fire = false,
  }) =>
      StreamGroup.merge<void>([
        (localTag as MemoryLocalTagsService)._watchForFilename(filename),
        _events.stream.map((e) => e),
      ]).map<List<ImageTag>>((_) {
        final f = localTag.get(filename);

        return f
            .map(
              (e) => ImageTag(
                e,
                type == TagType.pinned && _val.containsKey(e),
              ),
            )
            .toList();
      }).listen(f);
}

class PlainTagData extends TagData {
  const PlainTagData({required super.tag, required super.type});

  @override
  TagData copy({String? tag, TagType? type}) => PlainTagData(
        tag: tag ?? this.tag,
        type: type ?? this.type,
      );
}

class MemoryTagManager implements TagManager {
  MemoryTagManager();

  @override
  final BooruTagging excluded = MemoryBooruTagging(TagType.excluded);

  @override
  final BooruTagging latest = MemoryBooruTagging(TagType.normal);

  @override
  final BooruTagging pinned = MemoryBooruTagging(TagType.pinned);
}

class PlainSettingsPath extends SettingsPath {
  const PlainSettingsPath(this.path, this.pathDisplay);

  @override
  final String path;

  @override
  final String pathDisplay;
}

class PlainSettingsData extends SettingsData {
  const PlainSettingsData({
    required this.path,
    required super.selectedBooru,
    required super.quality,
    required super.safeMode,
    required super.showWelcomePage,
    required super.showAnimeMangaPages,
    required super.extraSafeFilters,
  });

  @override
  final SettingsPath path;

  @override
  SettingsData copy({
    bool? extraSafeFilters,
    bool? showAnimeMangaPages,
    SettingsPath? path,
    Booru? selectedBooru,
    DisplayQuality? quality,
    SafeMode? safeMode,
    bool? showWelcomePage,
  }) =>
      PlainSettingsData(
        showAnimeMangaPages: showAnimeMangaPages ?? this.showAnimeMangaPages,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        safeMode: safeMode ?? this.safeMode,
        showWelcomePage: showWelcomePage ?? this.showWelcomePage,
        path: this.path,
        extraSafeFilters: extraSafeFilters ?? this.extraSafeFilters,
      );
}

class MemorySettingsService implements SettingsService {
  MemorySettingsService();

  SettingsData? _current;
  final StreamController<SettingsData> _events = StreamController.broadcast();

  @override
  void add(SettingsData data) {
    _current = data;
    _events.add(data);
  }

  @override
  Future<bool> chooseDirectory(
    void Function(String s) onError, {
    required String emptyResult,
    required String pickDirectory,
    required String validDirectory,
  }) =>
      Future.value(true);

  @override
  SettingsData get current =>
      _current ??
      const PlainSettingsData(
        extraSafeFilters: true,
        showAnimeMangaPages: false,
        path: PlainSettingsPath("_", "*not supported on web*"),
        selectedBooru: Booru.danbooru,
        quality: DisplayQuality.sample,
        safeMode: SafeMode.relaxed,
        showWelcomePage: true,
      );

  @override
  StreamSubscription<SettingsData?> watch(
    void Function(SettingsData? s) f, [
    bool fire = false,
  ]) =>
      _events.stream.listen(f);
}

class MemoryMiscSettingsData extends MiscSettingsData {
  const MemoryMiscSettingsData({
    required super.filesExtendedActions,
    required super.animeAlwaysLoadFromNet,
    required super.favoritesThumbId,
    required super.themeType,
    required super.favoritesPageMode,
    required super.animeWatchingOrderReversed,
  });

  @override
  MiscSettingsData copy({
    bool? filesExtendedActions,
    int? favoritesThumbId,
    ThemeType? themeType,
    bool? animeAlwaysLoadFromNet,
    bool? animeWatchingOrderReversed,
    FilteringMode? favoritesPageMode,
  }) =>
      MemoryMiscSettingsData(
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

class MemoryMiscSettingsService implements MiscSettingsService {
  final StreamController<MiscSettingsData> _events =
      StreamController.broadcast();

  @override
  void add(MiscSettingsData data) {
    current = data;
    _events.add(data);
  }

  @override
  MiscSettingsData current = const MemoryMiscSettingsData(
    filesExtendedActions: false,
    animeAlwaysLoadFromNet: true,
    favoritesThumbId: -1,
    themeType: ThemeType.systemAccent,
    favoritesPageMode: FilteringMode.tag,
    animeWatchingOrderReversed: false,
  );

  @override
  StreamSubscription<MiscSettingsData?> watch(
    void Function(MiscSettingsData? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.listen(f);
}

class PlainLocalTagsData extends LocalTagsData {
  const PlainLocalTagsData(super.filename, super.tags);
}

class PlainCompactMangaData extends CompactMangaDataBase with CompactMangaData {
  const PlainCompactMangaData({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });
}

class PlainHiddenBooruPostData extends HiddenBooruPostData {
  const PlainHiddenBooruPostData(super.booru, super.postId, super.thumbUrl);
}

class PlainPinnedManga extends CompactMangaDataBase with PinnedManga {
  const PlainPinnedManga({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });
}

class PlainDownloadFileData extends DownloadFileData {
  const PlainDownloadFileData({
    required super.name,
    required super.url,
    required super.thumbUrl,
    required super.site,
    required super.date,
    required super.status,
  });

  @override
  DownloadFileData toFailed() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.failed,
      );

  @override
  DownloadFileData toInProgress() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.inProgress,
      );

  @override
  DownloadFileData toOnHold() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.onHold,
      );
}

class PlainWatchedAnimeEntryData extends WatchedAnimeEntryData {
  const PlainWatchedAnimeEntryData({
    required this.genres,
    required this.relations,
    required this.staff,
    required super.site,
    required super.type,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.trailerUrl,
    required super.episodes,
    required super.background,
    required super.explicit,
    required super.date,
  });

  @override
  final List<AnimeGenre> genres;

  @override
  final List<AnimeRelation> relations;

  @override
  final List<AnimeRelation> staff;

  @override
  WatchedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
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
  }) =>
      PlainWatchedAnimeEntryData(
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
        year: year ?? this.year,
        id: id ?? this.id,
        siteUrl: siteUrl ?? this.siteUrl,
        isAiring: isAiring ?? this.isAiring,
        titleSynonyms: titleSynonyms ?? this.titleSynonyms,
        trailerUrl: trailerUrl ?? this.trailerUrl,
        episodes: episodes ?? this.episodes,
        background: background ?? this.background,
        explicit: explicit ?? this.explicit,
        date: date ?? this.date,
      );

  @override
  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) =>
      PlainWatchedAnimeEntryData(
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
        year: e.year,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: date,
      );
}

class MemoryWatchedAnimeEntryService implements WatchedAnimeEntryService {
  final _val = <(int, AnimeMetadata), WatchedAnimeEntryData>{};
  final _eventsVoid = StreamController<void>.broadcast();
  final _events = StreamController<(int, AnimeMetadata)>.broadcast();

  @override
  List<WatchedAnimeEntryData> get all => _val.values.toList();

  @override
  int get count => _val.length;

  @override
  bool watched(int id, AnimeMetadata site) => _val.containsKey((id, site));

  @override
  void add(WatchedAnimeEntryData entry) {
    _val[(entry.id, entry.site)] = entry;
    _events.add((entry.id, entry.site));

    _eventsVoid.add(null);
  }

  @override
  void delete(int id, AnimeMetadata site) {
    final n = _val.remove((id, site));
    if (n != null) {
      _events.add((id, site));

      _eventsVoid.add(null);
    }
  }

  @override
  void deleteAll(List<(int, AnimeMetadata)> ids) {
    for (final e in ids) {
      final n = _val.remove(e);
      if (n != null) {
        _events.add(e);
      }
    }

    _eventsVoid.add(null);
  }

  @override
  WatchedAnimeEntryData? maybeGet(int id, AnimeMetadata site) =>
      _val[(id, site)];

  @override
  void moveAllReversed(
    List<WatchedAnimeEntryData> entries,
    SavedAnimeEntriesService s,
  ) {
    deleteAll(entries.toIds);

    s.addAll(entries, this);
  }

  @override
  void moveAll(List<AnimeEntryData> entries, SavedAnimeEntriesService s) {
    s.deleteAll(entries.toIds);

    for (final e in entries) {
      _val[(e.id, e.site)] = PlainWatchedAnimeEntryData(
        genres: e.genres,
        relations: e.relations,
        staff: e.staff,
        site: e.site,
        type: e.type,
        thumbUrl: e.thumbUrl,
        title: e.title,
        titleJapanese: e.titleJapanese,
        titleEnglish: e.titleEnglish,
        score: e.score,
        synopsis: e.synopsis,
        year: e.year,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: DateTime.now(),
      );
    }

    for (final e in entries) {
      _events.add((e.id, e.site));
    }

    _eventsVoid.add(null);
  }

  @override
  void reAdd(List<WatchedAnimeEntryData> entries) {
    for (final e in entries) {
      _val[(e.id, e.site)] = e;
    }

    for (final e in entries) {
      _events.add((e.id, e.site));
    }

    _eventsVoid.add(null);
  }

  @override
  void update(AnimeEntryData e) {
    final n = _val[(e.id, e.site)];
    if (n != null) {
      _val[(e.id, e.site)] = n.copySuper(e);
    } else {
      _val[(e.id, e.site)] = PlainWatchedAnimeEntryData(
        genres: e.genres,
        relations: e.relations,
        staff: e.staff,
        site: e.site,
        type: e.type,
        thumbUrl: e.thumbUrl,
        title: e.title,
        titleJapanese: e.titleJapanese,
        titleEnglish: e.titleEnglish,
        score: e.score,
        synopsis: e.synopsis,
        year: e.year,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: DateTime.now(),
      );
    }
    _events.add((e.id, e.site));

    _eventsVoid.add(null);
  }

  @override
  StreamSubscription<void> watchAll(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      _eventsVoid.stream.listen(f);

  @override
  StreamSubscription<int> watchCount(
    void Function(int p1) f, [
    bool fire = false,
  ]) =>
      _eventsVoid.stream.map((e) => count).listen(f);

  @override
  StreamSubscription<WatchedAnimeEntryData?> watchSingle(
    int id,
    AnimeMetadata site,
    void Function(WatchedAnimeEntryData? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<WatchedAnimeEntryData?>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (data.$1 == id && data.$2 == site) {
              sink.add(_val[data]);
            }
          },
        ),
      ).listen(f);
}

class MemorySavedAnimeCharactersService implements SavedAnimeCharactersService {
  final _val = <(int id, AnimeMetadata site), List<AnimeCharacter>>{};
  final _events = StreamController<(int, AnimeMetadata)>.broadcast();

  @override
  bool addAsync(AnimeEntryData entry, AnimeAPI api) {
    if (_futures.containsKey((entry.id, entry.site))) {
      return true;
    }

    _futures[(entry.id, entry.site)] = api.characters(entry)
      ..then((value) {
        _val[(entry.id, entry.site)] = value;
        _events.add((entry.id, entry.site));
      }).whenComplete(() => _futures.remove((entry.id, entry.site)));

    return false;
  }

  @override
  List<AnimeCharacter> load(int id, AnimeMetadata site) =>
      _val[(id, site)] ?? [];

  @override
  StreamSubscription<List<AnimeCharacter>?> watch(
    int id,
    AnimeMetadata site,
    void Function(List<AnimeCharacter>? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<List<AnimeCharacter>?>(
        StreamTransformer.fromHandlers(
          handleData: (e, sink) {
            if (e.$1 == id && e.$2 == site) {
              sink.add(_val[e]);
            }
          },
        ),
      ).listen(f);
}

class PlainSavedAnimeEntryData extends SavedAnimeEntryData {
  const PlainSavedAnimeEntryData({
    required this.genres,
    required this.relations,
    required this.staff,
    required super.inBacklog,
    required super.site,
    required super.type,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.trailerUrl,
    required super.episodes,
    required super.background,
    required super.explicit,
  });

  @override
  final List<AnimeGenre> genres;

  @override
  final List<AnimeRelation> relations;

  @override
  final List<AnimeRelation> staff;

  @override
  SavedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) =>
      PlainSavedAnimeEntryData(
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
        year: e.year,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
      );

  @override
  SavedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
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
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
  }) =>
      PlainSavedAnimeEntryData(
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
        year: year ?? this.year,
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

class MemorySavedAnimeEntriesService implements SavedAnimeEntriesService {
  final _val = <(int, AnimeMetadata), SavedAnimeEntryData>{};
  final _eventsVoid = StreamController<void>.broadcast();
  final _events = StreamController<(int, AnimeMetadata)>.broadcast();

  @override
  int get count => _val.length;

  @override
  List<SavedAnimeEntryData> get backlogAll =>
      _val.values.where((e) => e.inBacklog).toList();

  @override
  List<SavedAnimeEntryData> get currentlyWatchingAll =>
      _val.values.where((e) => !e.inBacklog).toList();

  @override
  void addAll(
    List<AnimeEntryData> entries,
    WatchedAnimeEntryService watchedAnime,
  ) {
    final n = entries.where((e) => !watchedAnime.watched(e.id, e.site));
    for (final e in n) {
      _val[(e.id, e.site)] = PlainSavedAnimeEntryData(
        genres: e.genres,
        relations: e.relations,
        staff: e.staff,
        inBacklog: true,
        site: e.site,
        type: e.type,
        thumbUrl: e.thumbUrl,
        title: e.title,
        titleJapanese: e.titleJapanese,
        titleEnglish: e.titleEnglish,
        score: e.score,
        synopsis: e.synopsis,
        year: e.year,
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
      );
    }

    for (final e in n) {
      _events.add((e.id, e.site));
    }

    _eventsVoid.add(null);
  }

  @override
  void deleteAll(List<(int, AnimeMetadata)> ids) {
    for (final e in ids) {
      final n = _val.remove(e);
      if (n != null) {
        _events.add(e);
      }
    }

    _eventsVoid.add(null);
  }

  @override
  (bool, bool) isWatchingBacklog(int id, AnimeMetadata site) {
    final n = _val[(id, site)];

    return (n != null, n?.inBacklog ?? false);
  }

  @override
  SavedAnimeEntryData? maybeGet(int id, AnimeMetadata site) => _val[(id, site)];

  @override
  void reAdd(List<SavedAnimeEntryData> entries) {
    for (final e in entries) {
      _val[(e.id, e.site)] = e;
    }

    for (final e in entries) {
      _events.add((e.id, e.site));
    }

    _eventsVoid.add(null);
  }

  @override
  void unsetIsWatchingAll(List<SavedAnimeEntryData> entries) {
    for (final e in entries) {
      _val[(e.id, e.site)] = e.copy(inBacklog: false);
    }

    for (final e in entries) {
      _events.add((e.id, e.site));
    }

    _eventsVoid.add(null);
  }

  @override
  void update(AnimeEntryData e) {
    final n = _val[(e.id, e.site)];
    _val[(e.id, e.site)] = n?.copySuper(e) ??
        PlainSavedAnimeEntryData(
          genres: e.genres,
          relations: e.relations,
          staff: e.staff,
          inBacklog: true,
          site: e.site,
          type: e.type,
          thumbUrl: e.thumbUrl,
          title: e.title,
          titleJapanese: e.titleJapanese,
          titleEnglish: e.titleEnglish,
          score: e.score,
          synopsis: e.synopsis,
          year: e.year,
          id: e.id,
          siteUrl: e.siteUrl,
          isAiring: e.isAiring,
          titleSynonyms: e.titleSynonyms,
          trailerUrl: e.trailerUrl,
          episodes: e.episodes,
          background: e.background,
          explicit: e.explicit,
        );
    _events.add((e.id, e.site));

    _eventsVoid.add(null);
  }

  @override
  StreamSubscription<SavedAnimeEntryData?> watch(
    int id,
    AnimeMetadata site,
    void Function(SavedAnimeEntryData? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<SavedAnimeEntryData?>(
        StreamTransformer.fromHandlers(
          handleData: (e, sink) {
            if (e.$1 == id && e.$2 == site) {
              sink.add(_val[e]);
            }
          },
        ),
      ).listen(f);

  @override
  StreamSubscription<void> watchAll(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      _eventsVoid.stream.listen(f);

  @override
  StreamSubscription<int> watchCount(
    void Function(int p1) f, [
    bool fire = false,
  ]) =>
      _eventsVoid.stream.map((e) => count).listen(f);
}

class PlainThumbnailData extends ThumbnailData {
  const PlainThumbnailData(
    super.id,
    super.updatedAt,
    super.path,
    super.differenceHash,
  );
}

class MemoryThumbnailService implements ThumbnailService {
  final _val = <int, ThumbnailData>{};

  @override
  void addAll(List<ThumbId> l) {
    for (final e in l) {
      _val[e.id] =
          PlainThumbnailData(e.id, DateTime.now(), e.path, e.differenceHash);
    }
  }

  @override
  void clear() {
    _val.clear();
  }

  @override
  void delete(int id) {
    _val.remove(id);
  }

  @override
  ThumbnailData? get(int id) => _val[id];
}

class PlainPinnedThumbnailData extends PinnedThumbnailData {
  const PlainPinnedThumbnailData(super.id, super.differenceHash, super.path);
}

class MemoryPinnedThumbnailService implements PinnedThumbnailService {
  final _val = <int, PlainPinnedThumbnailData>{};

  @override
  void add(int id, String path, int differenceHash) {
    _val[id] = PlainPinnedThumbnailData(id, differenceHash, path);
  }

  @override
  void clear() {
    _val.clear();
  }

  @override
  bool delete(int id) => _val.remove(id) != null;

  @override
  PinnedThumbnailData? get(int id) => _val[id];
}

class PlainChaptersSettingsData extends ChaptersSettingsData {
  const PlainChaptersSettingsData({required super.hideRead});

  @override
  ChaptersSettingsData copy({bool? hideRead}) =>
      PlainChaptersSettingsData(hideRead: hideRead ?? this.hideRead);
}

class MemoryChaptersSettingsService implements ChaptersSettingsService {
  final _events = StreamController<ChaptersSettingsData>.broadcast();

  @override
  ChaptersSettingsData current =
      const PlainChaptersSettingsData(hideRead: false);

  @override
  void add(ChaptersSettingsData data) {
    current = data;
    _events.add(data);
  }

  @override
  StreamSubscription<ChaptersSettingsData?> watch(
    void Function(ChaptersSettingsData? c) f,
  ) =>
      _events.stream.listen(f);
}

class MemoryReadMangaChaptersService implements ReadMangaChaptersService {
  final _val = <(String siteMangaId, String chapterId), ReadMangaChapterData>{};
  final _events = StreamController<(String, String)>.broadcast();
  final _eventsVoid = StreamController<void>.broadcast();

  @override
  int get countDistinct => _val.length;

  @override
  void delete({required String siteMangaId, required String chapterId}) {
    _val.remove((siteMangaId, chapterId));
    _events.add((siteMangaId, chapterId));
    _eventsVoid.add(null);
  }

  @override
  void deleteAllById(String siteMangaId, bool silent) {
    _val.removeWhere((e, data) {
      final toRemove = e.$1 == siteMangaId;
      if (toRemove) {
        _events.add(e);
      }

      return toRemove;
    });

    _eventsVoid.add(null);
  }

  @override
  ReadMangaChapterData? firstForId(String siteMangaId) {
    final l = _val.entries.toList();
    final i = l.lastIndexWhere((e) => e.key.$1 == siteMangaId);

    return i.isNegative ? null : l[i].value;
  }

  @override
  List<ReadMangaChapterData> lastRead(int limit) {
    return _val.values.toList().reversed.take(limit).toList();
  }

  @override
  int? progress({required String siteMangaId, required String chapterId}) =>
      _val[(siteMangaId, chapterId)]?.chapterProgress;

  @override
  void setProgress(
    int progress, {
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    _val[(siteMangaId, chapterId)] = PlainReadMangaChapterData(
      siteMangaId: siteMangaId,
      chapterId: chapterId,
      chapterProgress: progress,
      lastUpdated: DateTime.now(),
      chapterName: chapterName,
      chapterNumber: chapterNumber,
    );

    _events.add((siteMangaId, chapterId));
    _eventsVoid.add(null);
  }

  @override
  void touch({
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    final n = _val[(siteMangaId, chapterId)];
    _val[(siteMangaId, chapterId)] = PlainReadMangaChapterData(
      siteMangaId: siteMangaId,
      chapterId: chapterId,
      chapterProgress: n?.chapterProgress ?? 0,
      lastUpdated: DateTime.now(),
      chapterName: chapterName,
      chapterNumber: chapterNumber,
    );

    _events.add((siteMangaId, chapterId));
    _eventsVoid.add(null);
  }

  @override
  StreamSubscription<void> watch(void Function(void p1) f) =>
      _eventsVoid.stream.listen(f);

  @override
  StreamSubscription<int?> watchChapter(
    void Function(int? p1) f, {
    required String siteMangaId,
    required String chapterId,
  }) {
    return _events.stream.transform<int?>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data.$1 == siteMangaId && data.$2 == chapterId) {
            sink.add(_val[data]?.chapterProgress);
          }
        },
      ),
    ).listen(f);
  }

  @override
  StreamSubscription<int> watchReading(void Function(int p1) f) =>
      _eventsVoid.stream.map((_) => countDistinct).listen(f);
}

class PlainReadMangaChapterData extends ReadMangaChapterData {
  const PlainReadMangaChapterData({
    required super.siteMangaId,
    required super.chapterId,
    required super.chapterProgress,
    required super.lastUpdated,
    required super.chapterName,
    required super.chapterNumber,
  });
}

class MemorySavedMangaChaptersService implements SavedMangaChaptersService {
  final _val = <(String mangaId, MangaMeta site), (List<MangaChapter>, int)>{};

  @override
  void add(
    String mangaId,
    MangaMeta site,
    List<MangaChapter> chapters,
    int page,
  ) =>
      _val[(mangaId, site)] = (chapters, page);

  @override
  void clear(String mangaId, MangaMeta site) {
    _val.remove((mangaId, site));
  }

  @override
  int count(String mangaId, MangaMeta site) =>
      _val[(mangaId, site)]?.$1.length ?? 0;

  @override
  (List<MangaChapter>, int)? get(
    String mangaId,
    MangaMeta site,
    ChaptersSettingsData? settings,
    ReadMangaChaptersService readManga,
  ) {
    final prev = _val[(mangaId, site)];
    if (prev == null) {
      return null;
    }

    if (settings != null && settings.hideRead) {
      return (
        prev.$1.where((element) {
          final p = readManga.progress(
            siteMangaId: mangaId,
            chapterId: element.id,
          );
          if (p == null) {
            return true;
          }

          return p != element.pages;
        }).toList(),
        prev.$2
      );
    }

    return (prev.$1, prev.$2);
  }
}

class MemoryPinnedMangaService implements PinnedMangaService {
  final _val = <(String, MangaMeta), PinnedManga>{};
  final _events = StreamController<void>.broadcast();

  @override
  int get count => _val.length;

  @override
  void addAll(List<MangaEntry> l) {
    for (final e in l) {
      _val[(e.id.toString(), e.site)] = e is PinnedManga
          ? e as PinnedManga
          : PlainPinnedManga(
              mangaId: e.id.toString(),
              site: e.site,
              thumbUrl: e.thumbUrl,
              title: e.title,
            );
    }

    _events.add(null);
  }

  @override
  List<PinnedManga> deleteAll(List<(MangaId, MangaMeta)> ids) {
    final l = <PinnedManga>[];

    for (final e in ids) {
      final n = _val.remove((e.$1.toString(), e.$2));
      if (n != null) {
        l.add(n);
      }
    }

    _events.add(null);

    return l;
  }

  @override
  void deleteSingle(String mangaId, MangaMeta site) {
    _val.remove((mangaId, site));
    _events.add(null);
  }

  @override
  bool exist(String mangaId, MangaMeta site) =>
      _val.containsKey((mangaId, site));

  @override
  List<PinnedManga> getAll(int limit) => limit.isNegative
      ? _val.values.toList()
      : _val.values.take(limit).toList();

  @override
  void reAdd(List<PinnedManga> l) {
    for (final e in l) {
      _val[(e.mangaId, e.site)] = e;
    }

    _events.add(null);
  }

  @override
  StreamSubscription<void> watch(void Function(void p1) f) =>
      _events.stream.listen(f);
}

class PlainDirectoryMetadataData extends DirectoryMetadataData {
  const PlainDirectoryMetadataData(
    super.categoryName,
    super.time, {
    required super.blur,
    required super.sticky,
    required super.requireAuth,
  });

  @override
  DirectoryMetadataData copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) =>
      PlainDirectoryMetadataData(
        categoryName,
        DateTime.now(),
        blur: blur ?? this.blur,
        sticky: sticky ?? this.sticky,
        requireAuth: requireAuth ?? this.requireAuth,
      );
}

class MemoryDirectoryMetadataService implements DirectoryMetadataService {
  final _val = <String, DirectoryMetadataData>{};

  @override
  void add(DirectoryMetadataData data) {
    _val[data.categoryName] = data;
  }

  @override
  Future<bool> canAuth(String id, String reason) => Future.value(true);

  @override
  SegmentCapability caps(String specialLabel) => SegmentCapability.empty();

  @override
  DirectoryMetadataData? get(String id) => _val[id];

  @override
  DirectoryMetadataData getOrCreate(String id) => _val.putIfAbsent(
        id,
        () => PlainDirectoryMetadataData(
          id,
          DateTime.now(),
          blur: false,
          sticky: false,
          requireAuth: false,
        ),
      );

  @override
  void put(
    String id, {
    required bool blur,
    required bool auth,
    required bool sticky,
  }) =>
      _val[id] = PlainDirectoryMetadataData(
        id,
        DateTime.now(),
        blur: blur,
        sticky: sticky,
        requireAuth: auth,
      );

  @override
  StreamSubscription<void> watch(
    void Function(void p1) f, [
    bool fire = false,
  ]) {
    // TODO: implement watch
    throw UnimplementedError();
  }
}

class MemoryFavoriteFileService implements FavoriteFileService {
  final _events = StreamController<int>.broadcast();

  @override
  final Map<int, void> cachedValues = {};

  @override
  int get thumbnail => cachedValues.keys.last;

  @override
  int get count => cachedValues.length;

  @override
  bool isEmpty() => cachedValues.isEmpty;

  @override
  bool isNotEmpty() => cachedValues.isNotEmpty;

  @override
  bool isFavorite(int id) => cachedValues.containsKey(id);

  @override
  List<int> getAll({required int offset, required int limit}) {
    return cachedValues.keys.skip(offset).take(limit).toList();
  }

  @override
  void addAll(List<int> ids) {
    for (final e in ids) {
      cachedValues[e] = null;
    }

    _events.add(count);
  }

  @override
  void deleteAll(List<int> ids) {
    for (final e in ids) {
      cachedValues.remove(e);
    }

    _events.add(count);
  }

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _events.stream.transform<int>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<int>(sync: true);
          controller.onListen = () {
            final subscription = input.listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
              cancelOnError: cancelOnError,
            );
            controller
              ..onPause = subscription.pause
              ..onResume = subscription.resume
              ..onCancel = subscription.cancel;
          };

          if (fire) {
            Timer.run(() {
              controller.add(count);
            });
          }

          return controller.stream.listen(null);
        }),
      ).listen(f);

  @override
  Stream<bool> streamSingle(int id, [bool fire = false]) {
    // TODO: implement streamSingle
    throw UnimplementedError();
  }
}

class MemoryDirectoryTagService implements DirectoryTagService {
  final _val = <String, String>{};

  @override
  void add(Iterable<String> bucketIds, String tag) {
    for (final e in bucketIds) {
      _val[e] = tag;
    }
  }

  @override
  void delete(Iterable<String> buckedIds) {
    for (final e in buckedIds) {
      _val.remove(e);
    }
  }

  @override
  String? get(String bucketId) => _val[bucketId];
}

class PlainBlacklistedDirectoryData extends BlacklistedDirectoryData {
  const PlainBlacklistedDirectoryData(super.bucketId, super.name);
}

class MemoryBlacklistedDirectoryService implements BlacklistedDirectoryService {
  final _val = <String, PlainBlacklistedDirectoryData>{};
  final _events = StreamController<void>.broadcast();

  void addAll(List<GalleryDirectory> directories) {
    for (final e in directories) {
      _val[e.bucketId] = PlainBlacklistedDirectoryData(e.bucketId, e.name);
    }
    _events.add(null);
  }

  void clear() {
    _val.clear();
    _events.add(null);
  }

  void deleteAll(List<String> bucketIds) {
    for (final e in bucketIds) {
      _val.remove(e);
    }
    _events.add(null);
  }

  @override
  List<BlacklistedDirectoryData> getAll(List<String> bucketIds) {
    final l = <BlacklistedDirectoryData>[];

    for (final e in bucketIds) {
      final n = _val[e];
      if (n != null) {
        l.add(n);
      }
    }

    return l;
  }

  StreamSubscription<void> watch(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.listen(f);

  @override
  // TODO: implement backingStorage
  SourceStorage<String, BlacklistedDirectoryData> get backingStorage =>
      throw UnimplementedError();

  @override
  Future<int> clearRefresh() {
    // TODO: implement clearRefresh
    throw UnimplementedError();
  }

  @override
  // TODO: implement count
  int get count => throw UnimplementedError();

  @override
  void destroy() {
    // TODO: implement destroy
  }

  @override
  // TODO: implement hasNext
  bool get hasNext => throw UnimplementedError();

  @override
  Future<int> next() {
    // TODO: implement next
    throw UnimplementedError();
  }

  @override
  // TODO: implement progress
  RefreshingProgress get progress => throw UnimplementedError();
}

class MemoryLocalTagDictionaryService implements LocalTagDictionaryService {
  final _val = <String, int>{};

  @override
  void add(List<String> tags) {
    for (final e in tags) {
      _val.update(e, (i) => i += 1, ifAbsent: () => 1);
    }
  }

  @override
  Future<List<BooruTag>> complete(String string) async {
    return _val.entries
        .take(15)
        .map((e) => PlainBooruTag(e.key, e.value))
        .toList()
      ..sort((e1, e2) => e2.count.compareTo(e2.count));
  }
}

class PlainBooruTag extends BooruTag {
  const PlainBooruTag(super.tag, super.count);
}

class MemoryLocalTagsService implements LocalTagsService {
  final Map<String, String> cachedValues = {};

  final _events = StreamController<String>.broadcast();

  @override
  void add(String filename, List<String> tags) {
    cachedValues[filename] = tags.join(" ");
    _events.add(filename);
  }

  @override
  void addAll(List<LocalTagsData> tags) {
    for (final e in tags) {
      cachedValues[e.filename] = e.tags.join(" ");
    }

    for (final e in tags) {
      _events.add(e.filename);
    }
  }

  @override
  void addMultiple(List<String> filenames, String tag) {
    for (final e in filenames) {
      final prev = (cachedValues[e]?.split(" ") ?? []).toList()
        ..remove(tag)
        ..add(tag);
      cachedValues[e] = prev.join(" ");
    }

    for (final e in filenames) {
      _events.add(e);
    }
  }

  @override
  int get count => cachedValues.length;

  @override
  void delete(String filename) {
    cachedValues.remove(filename);
    _events.add(filename);
  }

  @override
  List<String> get(String filename) =>
      cachedValues[filename]?.split(" ") ?? const [];

  @override
  void removeSingle(List<String> filenames, String tag) {
    for (final e in filenames) {
      final prev = (cachedValues[e]?.split(" ") ?? []).toList()..remove(tag);
      cachedValues[e] = prev.join(" ");
    }
    for (final e in filenames) {
      _events.add(e);
    }
  }

  Stream<LocalTagsData> _watchForFilename(String filename) =>
      _events.stream.transform<LocalTagsData>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (data == filename) {
              sink.add(
                PlainLocalTagsData(
                  filename,
                  cachedValues[filename]?.split(" ") ?? const [],
                ),
              );
            }
          },
        ),
      );

  @override
  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData p1) f,
  ) =>
      _watchForFilename(filename).listen(f);
}

class MemoryCompactMangaDataService implements CompactMangaDataService {
  final _val = <(String, MangaMeta), CompactMangaData>{};

  @override
  void addAll(List<CompactMangaData> l) {
    for (final e in l) {
      _val[(e.mangaId, e.site)] = e;
    }
  }

  @override
  CompactMangaData? get(String mangaId, MangaMeta site) =>
      _val[(mangaId, site)];
}

class MemoryGridStateBooruService implements GridBookmarkService {
  final Map<String, GridBookmark> _val = {};

  final _events = StreamController<int>.broadcast();

  @override
  List<GridBookmark> get all => _val.values.toList();

  @override
  int get count => all.length;

  @override
  void add(GridBookmark state) {
    _val.containsKey(state.name);
    _events.add(count);
  }

  @override
  void delete(String name) {
    final n = _val.remove(name);
    if (n != null) {
      _events.add(count);
    }
  }

  @override
  GridBookmark? get(String name) => _val[name];

  @override
  StreamSubscription<int> watch(
    void Function(int p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.listen(f);
}

class PlainGridBookmark extends GridBookmark {
  const PlainGridBookmark({
    required super.name,
    required super.time,
    required super.tags,
    required super.booru,
  });

  @override
  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
  }) =>
      PlainGridBookmark(
        tags: tags ?? this.tags,
        booru: booru ?? this.booru,
        name: name ?? this.name,
        time: time ?? this.time,
      );
}

class PlainFavoritePostData extends FavoritePostData {
  PlainFavoritePostData({
    required super.group,
    required super.id,
    required super.height,
    required super.md5,
    required super.tags,
    required super.width,
    required super.fileUrl,
    required super.booru,
    required super.previewUrl,
    required super.sampleUrl,
    required super.sourceUrl,
    required super.rating,
    required super.score,
    required super.createdAt,
    required super.type,
  });
}

class MemoryFavoritePostService implements FavoritePostSourceService {
  final _eventsCount = StreamController<int>.broadcast();

  @override
  int get count => backingStorage.length;

  @override
  bool isFavorite(int id, Booru booru) =>
      backingStorage.map_.containsKey((id, booru));

  @override
  List<Post> addRemove(List<Post> posts) {
    final deleted = <Post>[];

    for (final e in posts) {
      final p = backingStorage.get((e.id, e.booru));
      if (p == null) {
        backingStorage.add(
          e is FavoritePostData
              ? e
              : PlainFavoritePostData(
                  group: null,
                  id: e.id,
                  height: e.height,
                  md5: e.md5,
                  tags: e.tags,
                  width: e.width,
                  fileUrl: e.fileUrl,
                  booru: e.booru,
                  previewUrl: e.previewUrl,
                  sampleUrl: e.sampleUrl,
                  sourceUrl: e.sourceUrl,
                  rating: e.rating,
                  score: e.score,
                  createdAt: e.createdAt,
                  type: e.type,
                ),
          true,
        );
      } else {
        final d = backingStorage.removeAll([(e.id, e.booru)]);
        if (d.isNotEmpty) {
          deleted.add(d.first);
        }
      }
    }

    _eventsCount.add(count);

    return deleted;
  }

  @override
  final MapStorage<(int, Booru), FavoritePostData> backingStorage =
      MapStorage((v) => (v.id, v.booru));

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  Future<int> next() => Future.value(count);

  @override
  bool get hasNext => false;

  @override
  ClosableRefreshProgress get progress => ClosableRefreshProgress();

  @override
  void destroy() {
    progress.close();
    backingStorage.destroy();
  }

  @override
  StreamSubscription<T> watchSingle<T>(
    int id,
    Booru booru,
    T Function(bool p1) transform,
    void Function(T p1) f, [
    bool fire = false,
  ]) =>
      throw UnimplementedError();
}

class MemoryHiddenBooruPostService implements HiddenBooruPostService {
  @override
  final Map<(int, Booru), String> cachedValues = {};

  final StreamController<void> _events = StreamController.broadcast();

  @override
  void addAll(List<HiddenBooruPostData> booru) {
    cachedValues.addEntries(
      booru.map((e) => MapEntry((e.postId, e.booru), e.thumbUrl)),
    );

    _events.add(null);
  }

  @override
  void removeAll(List<(int, Booru)> booru) {
    for (final e in booru) {
      cachedValues.remove(e);
    }

    _events.add(null);
  }

  @override
  StreamSubscription<void> watch(void Function(void p1) f) =>
      _events.stream.listen(f);

  @override
  Stream<bool> streamSingle(int id, Booru booru, [bool fire = false]) {
    // TODO: implement streamSingle
    throw UnimplementedError();
  }
}

class MemoryGridSettingsService implements GridSettingsService {
  @override
  final WatchableGridSettingsData animeDiscovery = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData booru = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.gridQuilted,
  );

  @override
  final WatchableGridSettingsData directories = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData favoritePosts = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.five,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData files = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );
}

class PlainGridState extends GridState {
  const PlainGridState({
    required super.name,
    required super.offset,
    required super.tags,
    required super.safeMode,
  });

  @override
  GridState copy({
    String? name,
    String? tags,
    double? offset,
    SafeMode? safeMode,
  }) =>
      PlainGridState(
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        offset: offset ?? this.offset,
        name: name ?? this.name,
      );
}

class MapPostsOptimizedStorage extends MapStorage<(int, Booru), Post>
    implements PostsOptimizedStorage {
  MapPostsOptimizedStorage() : super(PostsOptimizedStorage.postTransformKey);

  Post? currentlyLast;

  @override
  List<Post> get firstFiveAll => map_.values
      .where((p) => p.rating.asSafeMode == SafeMode.none)
      .take(5)
      .toList();

  @override
  List<Post> get firstFiveNormal => map_.values
      .where((p) => p.rating.asSafeMode == SafeMode.normal)
      .take(5)
      .toList();

  @override
  List<Post> get firstFiveRelaxed => map_.values
      .where((p) => p.rating.asSafeMode == SafeMode.relaxed)
      .take(5)
      .toList();
}

class MemoryPostSource extends GridPostSource with GridPostSourceRefreshNext {
  MemoryPostSource(
    this.api,
    this.entry,
    this.excluded,
    this.filters,
  );

  @override
  final BooruAPI api;

  @override
  final PagingEntry entry;

  @override
  final BooruTagging excluded;

  @override
  String tags = "";

  @override
  final List<FilterFnc<Post>> filters;

  @override
  bool get hasNext => true;

  @override
  // TODO: implement backingStorage
  SourceStorage<int, Post> get backingStorage => throw UnimplementedError();

  @override
  // TODO: implement count
  int get count => throw UnimplementedError();

  @override
  // TODO: implement currentlyLast
  Post? get currentlyLast => throw UnimplementedError();

  @override
  void destroy() {
    // TODO: implement destroy
  }

  @override
  // TODO: implement safeMode
  SafeMode get safeMode => throw UnimplementedError();
}

class MemoryMainGridService implements MainGridService {
  MemoryMainGridService(this.booru);

  final Booru booru;

  @override
  late GridState currentState = PlainGridState(
    name: booru.string,
    offset: 0,
    tags: "",
    safeMode: SafeMode.none,
  );

  @override
  int page = 0;

  @override
  DateTime time = DateTime.now();

  @override
  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    HiddenBooruPostService hiddenBooruPosts,
  ) =>
      MemoryPostSource(
        api,
        entry,
        excluded,
        [(p) => !hiddenBooruPosts.isHidden(p.id, p.booru)],
      );

  final _storage = MapPostsOptimizedStorage();

  @override
  PostsOptimizedStorage get savedPosts => _storage;

  @override
  late final TagManager tagManager = MemoryTagManager();
}

class MemoryStatisticsGeneralData extends StatisticsGeneralData {
  const MemoryStatisticsGeneralData({
    required super.refreshes,
    required super.scrolledUp,
    required super.timeDownload,
    required super.timeSpent,
  });

  @override
  StatisticsGeneralData add({
    int? timeSpent,
    int? timeDownload,
    int? scrolledUp,
    int? refreshes,
  }) =>
      MemoryStatisticsGeneralData(
        refreshes: refreshes ?? this.refreshes,
        scrolledUp: scrolledUp ?? this.scrolledUp,
        timeDownload: timeDownload ?? this.timeDownload,
        timeSpent: timeSpent ?? this.timeSpent,
      );
}

class MemoryStatisticsGeneralService implements StatisticsGeneralService {
  @override
  void add(StatisticsGeneralData data) {
    current = data;
  }

  @override
  StatisticsGeneralData current = const MemoryStatisticsGeneralData(
    refreshes: 0,
    scrolledUp: 0,
    timeDownload: 0,
    timeSpent: 0,
  );
}

class MemoryStatisticsGalleryData extends StatisticsGalleryData {
  const MemoryStatisticsGalleryData({
    required super.copied,
    required super.deleted,
    required super.joined,
    required super.moved,
    required super.filesSwiped,
    required super.sameFiltered,
    required super.viewedDirectories,
    required super.viewedFiles,
  });

  @override
  StatisticsGalleryData add({
    int? viewedDirectories,
    int? viewedFiles,
    int? joined,
    int? filesSwiped,
    int? sameFiltered,
    int? deleted,
    int? copied,
    int? moved,
  }) =>
      MemoryStatisticsGalleryData(
        copied: copied ?? this.copied,
        deleted: deleted ?? this.deleted,
        joined: joined ?? this.joined,
        moved: moved ?? this.moved,
        filesSwiped: filesSwiped ?? this.filesSwiped,
        sameFiltered: sameFiltered ?? this.sameFiltered,
        viewedDirectories: viewedDirectories ?? this.viewedDirectories,
        viewedFiles: viewedFiles ?? this.viewedFiles,
      );
}

class MemoryStatisticsGalleryService implements StatisticsGalleryService {
  @override
  void add(StatisticsGalleryData data) {
    current = data;
  }

  @override
  StatisticsGalleryData current = const MemoryStatisticsGalleryData(
    copied: 0,
    deleted: 0,
    joined: 0,
    moved: 0,
    filesSwiped: 0,
    sameFiltered: 0,
    viewedDirectories: 0,
    viewedFiles: 0,
  );

  @override
  StreamSubscription<StatisticsGalleryData> watch(
    void Function(StatisticsGalleryData p1) f, [
    bool fire = false,
  ]) {
    // TODO: implement watch
    throw UnimplementedError();
  }
}

class PlainStatisticsBooruData extends StatisticsBooruData {
  const PlainStatisticsBooruData({
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
      PlainStatisticsBooruData(
        booruSwitches: booruSwitches ?? this.booruSwitches,
        downloaded: downloaded ?? this.downloaded,
        swiped: swiped ?? this.swiped,
        viewed: viewed ?? this.viewed,
      );
}

class MemoryStatisticsBooruService implements StatisticsBooruService {
  @override
  void add(StatisticsBooruData data) {
    current = data;
  }

  @override
  StatisticsBooruData current = const PlainStatisticsBooruData(
    booruSwitches: 0,
    downloaded: 0,
    swiped: 0,
    viewed: 0,
  );

  @override
  StreamSubscription<StatisticsBooruData> watch(
    void Function(StatisticsBooruData p1) f, [
    bool fire = false,
  ]) {
    // TODO: implement watch
    throw UnimplementedError();
  }
}

class PlainStatisticsDailyData extends StatisticsDailyData {
  const PlainStatisticsDailyData({
    required super.swipedBoth,
    required super.durationMillis,
    required super.date,
  });

  @override
  StatisticsDailyData add({required int swipedBoth}) =>
      PlainStatisticsDailyData(
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
      PlainStatisticsDailyData(
        swipedBoth: swipedBoth ?? this.swipedBoth,
        durationMillis: durationMillis ?? this.durationMillis,
        date: date ?? this.date,
      );
}

class MemoryStatisticsDailyService implements StatisticsDailyService {
  @override
  StatisticsDailyData current = PlainStatisticsDailyData(
    date: DateTime.now(),
    swipedBoth: 0,
    durationMillis: 0,
  );

  @override
  void add(StatisticsDailyData data) {
    current = data;
  }
}
