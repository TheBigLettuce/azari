// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:async/async.dart";
import "package:gallery/src/db/services/impl_table/web.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/net/booru/display_quality.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/net/manga/manga_api.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";

final _futures = <(int, AnimeMetadata), Future<void>>{};

class MemoryOnlyServicesImplTable implements ServicesImplTable {
  Future<DownloadManager> init() => Future.value(_downloadManager);

  @override
  final DownloadFileService downloads = MemoryDownloadFileService();
  late final DownloadManager _downloadManager = MemoryOnlyDownloadManager("");

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

  @override
  final TagManager tagManager = MemoryTagManager();

  final Map<Booru, MainGridService> _gridServices = {};

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

  final _val = <String, DateTime>{};
  final _events = StreamController<void>.broadcast();

  final TagType type;

  @override
  void add(String tag) {
    _val[tag] = DateTime.now();
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
      ? _val.entries
          .map((e) => $TagData(tag: e.key, type: type, time: e.value))
          .toList()
      : _val.entries
          .take(limit)
          .map((e) => $TagData(tag: e.key, type: type, time: e.value))
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
                    favorite: type == TagType.pinned && _val.containsKey(e),
                    excluded: type == TagType.excluded && _val.containsKey(e),
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
                favorite: type == TagType.pinned && _val.containsKey(e),
                excluded: type == TagType.excluded && _val.containsKey(e),
              ),
            )
            .toList();
      }).listen(f);
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
    void Function(String s) onError,
    _,
  ) =>
      Future.value(true);

  @override
  SettingsData get current =>
      _current ??
      const $SettingsData(
        extraSafeFilters: true,
        showAnimeMangaPages: false,
        path: $SettingsPath("_", "*not supported on web*"),
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

class MemoryMiscSettingsService implements MiscSettingsService {
  final StreamController<MiscSettingsData> _events =
      StreamController.broadcast();

  @override
  void add(MiscSettingsData data) {
    current = data;
    _events.add(data);
  }

  @override
  MiscSettingsData current = const $MiscSettingsData(
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
      _val[(e.id, e.site)] = $WatchedAnimeEntryData(
        imageUrl: e.imageUrl,
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
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: DateTime.now(),
        airedFrom: e.airedTo,
        airedTo: e.airedFrom,
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
      _val[(e.id, e.site)] = $WatchedAnimeEntryData(
        imageUrl: e.imageUrl,
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
        id: e.id,
        siteUrl: e.siteUrl,
        isAiring: e.isAiring,
        titleSynonyms: e.titleSynonyms,
        trailerUrl: e.trailerUrl,
        episodes: e.episodes,
        background: e.background,
        explicit: e.explicit,
        date: DateTime.now(),
        airedFrom: e.airedFrom,
        airedTo: e.airedTo,
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
      _val[(e.id, e.site)] = $SavedAnimeEntryData(
        imageUrl: e.imageUrl,
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
        $SavedAnimeEntryData(
          imageUrl: e.imageUrl,
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

class MemoryThumbnailService implements ThumbnailService {
  final _val = <int, ThumbnailData>{};

  @override
  void addAll(List<ThumbId> l) {
    for (final e in l) {
      _val[e.id] = $ThumbnailData(
        id: e.id,
        updatedAt: DateTime.now(),
        path: e.path,
        differenceHash: e.differenceHash,
      );
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

class MemoryPinnedThumbnailService implements PinnedThumbnailService {
  final _val = <int, $PinnedThumbnailData>{};

  @override
  void add(int id, String path, int differenceHash) {
    _val[id] = $PinnedThumbnailData(
      id: id,
      differenceHash: differenceHash,
      path: path,
    );
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

class MemoryChaptersSettingsService implements ChaptersSettingsService {
  final _events = StreamController<ChaptersSettingsData>.broadcast();

  @override
  ChaptersSettingsData current = const $ChaptersSettingsData(hideRead: false);

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
    _val[(siteMangaId, chapterId)] = $ReadMangaChapterData(
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
    _val[(siteMangaId, chapterId)] = $ReadMangaChapterData(
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
          : $PinnedManga(
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

class MemoryDirectoryMetadataService implements DirectoryMetadataService {
  final _val = <String, DirectoryMetadata>{};

  @override
  void add(DirectoryMetadata data) {
    _val[data.categoryName] = data;
  }

  @override
  Future<bool> canAuth(String id, String reason) => Future.value(true);

  @override
  SegmentCapability caps(String specialLabel) => SegmentCapability.empty();

  @override
  DirectoryMetadata? get(String id) => _val[id];

  @override
  DirectoryMetadata getOrCreate(String id) => _val.putIfAbsent(
        id,
        () => $DirectoryMetadataData(
          categoryName: id,
          time: DateTime.now(),
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
      _val[id] = $DirectoryMetadataData(
        categoryName: id,
        time: DateTime.now(),
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

  @override
  List<int> getAllIds(List<int> ids) {
    // TODO: implement getAllIds
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

  @override
  bool searchByTag(String tag) {
    // TODO: implement searchByTag
    throw UnimplementedError();
  }
}

class MemoryBlacklistedDirectoryService implements BlacklistedDirectoryService {
  final _val = <String, $BlacklistedDirectoryData>{};
  final _events = StreamController<void>.broadcast();

  void addAll(List<GalleryDirectory> directories) {
    for (final e in directories) {
      _val[e.bucketId] =
          $BlacklistedDirectoryData(bucketId: e.bucketId, name: e.name);
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
    return _val.entries.take(15).map((e) => $BooruTag(e.key, e.value)).toList()
      ..sort((e1, e2) => e2.count.compareTo(e2.count));
  }
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
                $LocalTagsData(
                  filename: filename,
                  tags: cachedValues[filename]?.split(" ") ?? const [],
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

  @override
  List<GridBookmark> firstNumber(int n) {
    // TODO: implement firstNumber
    throw UnimplementedError();
  }

  @override
  GridBookmark? getFirstByTags(String tags) {
    // TODO: implement getFirstByTags
    throw UnimplementedError();
  }
}

class MemoryFavoritePostService implements FavoritePostSourceService {
  final _eventsCount = StreamController<int>.broadcast();

  @override
  bool isFavorite(int id, Booru booru) =>
      backingStorage.map_.containsKey((id, booru));

  @override
  List<PostBase> addRemove(List<PostBase> posts) {
    final deleted = <PostBase>[];

    for (final e in posts) {
      final p = backingStorage.get((e.id, e.booru));
      if (p == null) {
        backingStorage.add(
          e is FavoritePost
              ? e
              : $FavoritePost(
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
  final MapStorage<(int, Booru), FavoritePost> backingStorage =
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
  final WatchableGridSettingsData animeDiscovery =
      CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData booru =
      CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.gridQuilted,
  );

  @override
  final WatchableGridSettingsData directories =
      CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData favoritePosts =
      CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.five,
    layoutType: GridLayoutType.grid,
  );

  @override
  final WatchableGridSettingsData files =
      CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );
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
  // TODO: implement currentlyLast
  Post? get currentlyLast => throw UnimplementedError();

  @override
  void destroy() {
    // TODO: implement destroy
  }

  @override
  // TODO: implement updatesAvailable
  UpdatesAvailable get updatesAvailable => throw UnimplementedError();

  @override
  // TODO: implement safeMode
  SafeMode get safeMode => throw UnimplementedError();

  @override
  // TODO: implement lastFive
  List<Post> get lastFive => throw UnimplementedError();
}

class MemoryMainGridService implements MainGridService {
  MemoryMainGridService(this.booru);

  final Booru booru;

  @override
  late GridState currentState = $GridState(
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

class MemoryStatisticsBooruService implements StatisticsBooruService {
  @override
  void add(StatisticsBooruData data) {
    current = data;
  }

  @override
  StatisticsBooruData current = const $StatisticsBooruData(
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

class MemoryStatisticsDailyService implements StatisticsDailyService {
  @override
  StatisticsDailyData current = $StatisticsDailyData(
    date: DateTime.now(),
    swipedBoth: 0,
    durationMillis: 0,
  );

  @override
  void add(StatisticsDailyData data) {
    current = data;
  }
}
