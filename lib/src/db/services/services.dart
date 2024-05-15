// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/base/system_gallery_thumbnail_provider.dart";
import "package:gallery/src/db/services/impl_table/dummy.dart"
    if (dart.library.io) "package:gallery/src/db/services/impl_table/io.dart"
    if (dart.library.html) "package:gallery/src/db/services/impl_table/web.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/manga/manga_info_page.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/pages/manga/next_chapter_button.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:isar/isar.dart";

part "blacklisted_directory.dart";
part "chapters_settings.dart";
part "compact_manga_data.dart";
part "directory_metadata.dart";
part "download_file.dart";
part "favorite_file.dart";
part "favorite_post.dart";
part "grid_settings.dart";
part "hidden_booru_post.dart";
part "misc_settings.dart";
part "pinned_manga.dart";
part "pinned_thumbnail.dart";
part "read_manga_chapters.dart";
part "saved_anime_characters.dart";
part "saved_anime_entry.dart";
part "saved_manga_chapters.dart";
part "settings.dart";
part "statistics_booru.dart";
part "statistics_daily.dart";
part "statistics_gallery.dart";
part "statistics_general.dart";
part "thumbnail.dart";
part "video_settings.dart";
part "watched_anime_entry.dart";

Future<void> initServices() async {
  _downloadManager ??= await init(_currentDb);

  return Future.value();
}

int numberOfElementsPerRefresh() {
  final booruSettings = _currentDb.gridSettings.booru.current;
  if (booruSettings.layoutType == GridLayoutType.list) {
    return 40;
  }

  return 15 * booruSettings.columns.number;
}

DownloadManager? _downloadManager;

abstract interface class ServicesImplTable
    with ServicesImplTableObjInstExt
    implements ServiceMarker {
  SettingsService get settings;
  MiscSettingsService get miscSettings;
  SavedAnimeEntriesService get savedAnimeEntries;
  SavedAnimeCharactersService get savedAnimeCharacters;
  WatchedAnimeEntryService get watchedAnime;
  VideoSettingsService get videoSettings;
  HiddenBooruPostService get hiddenBooruPost;
  DownloadFileService get downloads;
  FavoritePostService get favoritePosts;
  StatisticsGeneralService get statisticsGeneral;
  StatisticsGalleryService get statisticsGallery;
  StatisticsBooruService get statisticsBooru;
  StatisticsDailyService get statisticsDaily;
  DirectoryMetadataService get directoryMetadata;
  ChaptersSettingsService get chaptersSettings;
  SavedMangaChaptersService get savedMangaChapters;
  ReadMangaChaptersService get readMangaChapters;
  PinnedMangaService get pinnedManga;
  ThumbnailService get thumbnails;
  PinnedThumbnailService get pinnedThumbnails;
  LocalTagsService get localTags;
  LocalTagDictionaryService get localTagDictionary;
  CompactMangaDataService get compactManga;
  GridStateBooruService get gridStateBooru;
  FavoriteFileService get favoriteFiles;
  DirectoryTagService get directoryTags;
  BlacklistedDirectoryService get blacklistedDirectories;
  GridSettingsService get gridSettings;

  MainGridService mainGrid(Booru booru);
  SecondaryGridService secondaryGrid(Booru booru, String name);
}

mixin ServicesImplTableObjInstExt {
  TagManager tagManager(Booru booru);

  LocalTagsData localTagsDataForDb(
    String filename,
    List<String> tags,
  );

  CompactMangaData compactMangaDataForDb({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  });

  SettingsPath settingsPathForCurrent({
    required String path,
    required String pathDisplay,
  });

  DownloadFileData downloadFileDataForDbFormat({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  });

  HiddenBooruPostData hiddenBooruPostDataForDb(
    String thumbUrl,
    int postId,
    Booru booru,
  );

  PinnedManga pinnedMangaForDb({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  });
}

final ServicesImplTable _currentDb = getApi();
typedef DbConn = ServicesImplTable;

class DatabaseConnectionNotifier extends InheritedWidget {
  const DatabaseConnectionNotifier._({
    super.key,
    required this.downloadManager,
    required this.db,
    required super.child,
  });

  factory DatabaseConnectionNotifier.current(Widget child) =>
      DatabaseConnectionNotifier._(
        db: _currentDb,
        downloadManager: _downloadManager!,
        child: child,
      );

  final DbConn db;
  final DownloadManager downloadManager;

  static DownloadManager downloadManagerOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<DatabaseConnectionNotifier>();

    return widget!.downloadManager;
  }

  static DbConn of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<DatabaseConnectionNotifier>();

    return widget!.db;
  }

  @override
  bool updateShouldNotify(DatabaseConnectionNotifier oldWidget) =>
      db != oldWidget.db;
}

abstract interface class ServiceMarker {}

mixin DbConnHandle<T extends ServiceMarker> implements StatefulWidget {
  T get db;
}

mixin DbScope<T extends ServiceMarker, W extends DbConnHandle<T>> on State<W> {}

typedef FilterFnc<T> = bool Function(T);

abstract class FilteringResourceSource<T> implements ResourceSource<T> {
  const FilteringResourceSource();

  List<FilterFnc<T>> get filters;

  List<T> filter(List<T> l) => l.where((element) {
        for (final e in filters) {
          final res = e(element);
          if (!res) {
            return false;
          }
        }

        return true;
      }).toList();
}

abstract class ReadOnlyStorage<T> with Iterable<T> {
  int get count;

  T? get(int idx);

  T operator [](int index);

  StreamSubscription<int> watch(void Function(int) f);
}

abstract class SourceStorage<T> extends ReadOnlyStorage<T> {
  Iterable<T> get reversed;

  void add(T e, [bool silent = false]);

  void addAll(List<T> l, [bool silent = false]);

  void removeAll(List<int> idx);

  void clear();

  void destroy();

  void operator []=(int index, T value);
}

class ListStorage<T> extends SourceStorage<T> {
  ListStorage();

  final StreamController<int> _events = StreamController.broadcast();

  final List<T> list = [];

  @override
  int get count => list.length;

  @override
  Iterator<T> get iterator => list.iterator;

  @override
  Iterable<T> get reversed => list.reversed;

  @override
  T? get(int idx) => idx >= count ? null : list[idx];

  @override
  void add(T e, [bool silent = false]) {
    list.add(e);

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void addAll(List<T> l, [bool silent = false]) {
    list.addAll(l);

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void clear() {
    list.clear();
    _events.add(count);
  }

  @override
  void removeAll(List<int> idx) {
    idx.forEach(list.removeAt);

    _events.add(count);
  }

  @override
  T operator [](int index) => get(index)!;

  @override
  void operator []=(int index, T value) => list[index] = value;

  @override
  void destroy() {
    clear();

    _events.close();
  }

  @override
  StreamSubscription<int> watch(void Function(int p1) f) =>
      _events.stream.listen(f);
}

class ChainedFilterResourceSource<T> implements ResourceSource<T> {
  ChainedFilterResourceSource(
    this._original,
    this._filterStorage, {
    required this.fn,
    required this.allowedFilteringModes,
    required this.allowedSortingModes,
    required FilteringMode initialFilteringMode,
    required SortingMode initialSortingMode,
  })  : assert(
          allowedFilteringModes.isEmpty
              ? true
              : allowedFilteringModes.contains(initialFilteringMode),
        ),
        assert(
          allowedSortingModes.isEmpty
              ? true
              : allowedSortingModes.contains(initialSortingMode),
        ),
        _mode = initialFilteringMode,
        _sorting = initialSortingMode {
    _originalSubscr = _original.backingStorage.watch((c) {
      clearRefresh();
    });
  }

  factory ChainedFilterResourceSource.basic(
    ResourceSource<T> original,
    SourceStorage<T> filterStorage, {
    required bool Function(
      T e,
      FilteringMode filteringMode,
      SortingMode sortingMode,
    ) fn,
  }) =>
      ChainedFilterResourceSource(
        original,
        filterStorage,
        fn: fn,
        allowedFilteringModes: const {},
        allowedSortingModes: const {},
        initialFilteringMode: FilteringMode.noFilter,
        initialSortingMode: SortingMode.none,
      );

  final ResourceSource<T> _original;
  final SourceStorage<T> _filterStorage;

  @override
  SourceStorage<T> get backingStorage => _filterStorage;

  late final StreamSubscription<int> _originalSubscr;

  final Set<FilteringMode> allowedFilteringModes;
  final Set<SortingMode> allowedSortingModes;

  FilteringMode _mode;
  SortingMode _sorting;

  FilteringMode get filteringMode => _mode;
  SortingMode get sortingMode => _sorting;

  @override
  RefreshingProgress get progress => _original.progress;

  set filteringMode(FilteringMode f) {
    if (allowedFilteringModes.isEmpty) {
      return;
    }

    if (!allowedFilteringModes.contains(f)) {
      assert(() {
        throw "filteringMode setter called with unknown value";
      }());

      return;
    }

    _mode = f;

    clearRefresh();
  }

  set sortingMode(SortingMode s) {
    if (allowedSortingModes.isEmpty) {
      return;
    }

    if (!allowedSortingModes.contains(s)) {
      assert(() {
        throw "sortingMode setter called with unknown value";
      }());

      return;
    }

    _sorting = s;

    clearRefresh();
  }

  final bool Function(T e, FilteringMode filteringMode, SortingMode sortingMode)
      fn;

  @override
  int get count => backingStorage.count;

  @override
  bool get hasNext => false;

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }

    backingStorage.clear();

    if (_original.backingStorage.count == 0) {
      return 0;
    }

    final origCount_ = _original.count;
    for (final (i, e) in _original.backingStorage.indexed) {
      final keep = fn(e, _mode, _sorting);
      if (keep) {
        backingStorage.add(e, i != origCount_ - 1);
      }
    }

    return count;
  }

  @override
  Future<int> next() {
    assert(() {
      throw "ChainedFilterResourceSource is currently whole pass only";
    }());

    return Future.value(count);
  }

  @override
  T? forIdx(int idx) => backingStorage.get(idx);

  @override
  T forIdxUnsafe(int idx) => backingStorage[idx];

  @override
  void destroy() {
    backingStorage.destroy();
    _originalSubscr.cancel();
  }
}

class _EmptyProgress implements RefreshingProgress {
  const _EmptyProgress();

  @override
  Object? get error => null;

  @override
  bool get inRefreshing => false;

  @override
  bool get canLoadMore => false;

  @override
  StreamSubscription<bool> watch(void Function(bool p1) f) =>
      const Stream<bool>.empty().listen(f);
}

class _EmptyResourceSource<T> extends ResourceSource<T> {
  @override
  int get count => backingStorage.count;

  @override
  bool get hasNext => false;

  @override
  final SourceStorage<T> backingStorage = ListStorage();

  @override
  T? forIdx(int idx) => backingStorage.get(idx);

  @override
  T forIdxUnsafe(int idx) => backingStorage[idx];

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    backingStorage.destroy();
  }

  @override
  RefreshingProgress get progress => const _EmptyProgress();
}

class ClosableRefreshProgress implements RefreshingProgress {
  ClosableRefreshProgress({
    this.canLoadMore = true,
  });

  final _events = StreamController<bool>.broadcast();

  bool _refresh = false;

  @override
  Object? error;

  @override
  bool get inRefreshing => _refresh;

  @override
  bool canLoadMore;

  set inRefreshing(bool b) {
    _refresh = b;
    _events.add(b);
  }

  @override
  StreamSubscription<bool> watch(void Function(bool p1) f) =>
      _events.stream.listen(f);

  void close() {
    _events.close();
  }
}

abstract class RefreshingProgress {
  const factory RefreshingProgress.empty() = _EmptyProgress;

  Object? get error;

  bool get inRefreshing;
  bool get canLoadMore;

  StreamSubscription<bool> watch(void Function(bool) f);
}

abstract interface class ResourceSource<T> {
  const ResourceSource();

  factory ResourceSource.empty() = _EmptyResourceSource;

  SourceStorage<T> get backingStorage;

  RefreshingProgress get progress;
  bool get hasNext;

  int get count;

  T? forIdx(int idx);
  T forIdxUnsafe(int idx);

  Future<int> clearRefresh();

  Future<int> next();

  void destroy();
}

class GenericListSource<T> implements ResourceSource<T> {
  GenericListSource(this._clearRefresh, [this._next]);

  final Future<List<T>> Function() _clearRefresh;
  final Future<List<T>> Function()? _next;

  @override
  final ListStorage<T> backingStorage = ListStorage();

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  int get count => backingStorage.count;

  @override
  bool get hasNext => _next != null;

  @override
  T? forIdx(int idx) => backingStorage.get(idx);

  @override
  T forIdxUnsafe(int idx) => backingStorage[idx];

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    backingStorage.clear();

    try {
      final ret = await _clearRefresh();
      if (ret.isEmpty) {
        progress.canLoadMore = false;
      } else {
        backingStorage.addAll(ret);
      }
    } catch (e) {
      progress.error = e;
    }

    progress.inRefreshing = false;

    return count;
  }

  @override
  Future<int> next() async {
    if (_next == null || progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    try {
      final ret = await _next();
      if (ret.isEmpty) {
        progress.canLoadMore = false;
      } else {
        backingStorage.addAll(ret);
      }
    } catch (e) {
      progress.error = e;
    }

    progress.inRefreshing = false;

    return count;
  }

  @override
  void destroy() {
    backingStorage.destroy();
    progress.close();
  }
}

abstract interface class LocalTagDictionaryService {
  void add(List<String> tags);

  Future<List<BooruTag>> complete(String string);
}

abstract class LocalTagsData {
  const LocalTagsData(this.filename, this.tags);

  factory LocalTagsData.forDb(
    String filename,
    List<String> tags,
  ) =>
      _currentDb.localTagsDataForDb(filename, tags);

  @Index(unique: true, replace: true)
  final String filename;

  @Index(caseSensitive: false, type: IndexType.hashElements)
  final List<String> tags;
}

abstract interface class LocalTagsService {
  int get count;

  Map<String, List<String>> get cachedValues;

  List<String> get(String filename);

  void add(String filename, List<String> tags);
  void addAll(List<LocalTagsData> tags);
  void addMultiple(List<String> filenames, String tag);

  void delete(String filename);
  void removeSingle(List<String> filenames, String tag);

  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData) f,
  );

  // StreamSubscription<List<ImageTag>> watchImagePinned(
  //   List<String> tags,
  //   void Function(List<ImageTag>) f, {
  //   String? withFilename,
  // });
}

enum TagType {
  normal,
  pinned,
  excluded;
}

abstract interface class DirectoryTagService {
  String? get(String bucketId);
  void add(Iterable<String> bucketIds, String tag);
  void delete(Iterable<String> buckedIds);
}

abstract class TagData {
  const TagData({
    required this.tag,
    required this.type,
  });

  @Index(unique: true, replace: true, composite: [CompositeIndex("type")])
  final String tag;

  @enumerated
  final TagType type;

  TagData copy({String? tag, TagType? type});
}

/// Tag search history.
/// Used for both for the recent tags and the excluded.
abstract class BooruTagging {
  const BooruTagging();

  bool exists(String tag);

  /// Get the current tags.
  /// Last added first.
  List<TagData> get(int limit);

  /// Add the [tag] to the DB.
  /// Updates the added time if already exist.
  void add(String tag);

  /// Delete the [tag] from the DB.
  void delete(String tag);

  /// Delete all the tags from the DB.
  void clear();

  StreamSubscription<void> watch(void Function(void) f, [bool fire = false]);

  StreamSubscription<List<ImageTag>> watchImage(
    List<String> tags,
    void Function(List<ImageTag>) f, {
    bool fire = false,
  });

  StreamSubscription<List<ImageTag>> watchImageLocal(
    String filename,
    void Function(List<ImageTag>) f, {
    required LocalTagsService localTag,
    bool fire = false,
  });
}

mixin TagManagerDbScope<W extends DbConnHandle<TagManager>>
    implements DbScope<TagManager, W>, TagManager {
  @override
  BooruTagging get excluded => widget.db.excluded;
  @override
  BooruTagging get latest => widget.db.latest;
  @override
  BooruTagging get pinned => widget.db.pinned;
}

abstract interface class TagManager implements ServiceMarker {
  factory TagManager.booru(Booru booru) => _currentDb.tagManager(booru);

  factory TagManager.of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_TagManagerAnchor>();

    return widget!.tagManager;
  }

  static Widget wrapAnchor(TagManager tagManager, Widget child) =>
      _TagManagerAnchor(tagManager: tagManager, child: child);

  BooruTagging get excluded;
  BooruTagging get latest;
  BooruTagging get pinned;
}

class _TagManagerAnchor extends InheritedWidget {
  const _TagManagerAnchor({
    super.key,
    required this.tagManager,
    required super.child,
  });

  final TagManager tagManager;

  @override
  bool updateShouldNotify(_TagManagerAnchor oldWidget) =>
      tagManager != oldWidget.tagManager;
}

abstract class GridStateBase {
  const GridStateBase({
    required this.tags,
    required this.safeMode,
    required this.scrollOffset,
    required this.name,
    required this.time,
  });

  @Index(unique: true, replace: true)
  final String name;
  @Index()
  final DateTime time;

  final String tags;

  final double scrollOffset;

  @enumerated
  final SafeMode safeMode;

  @override
  String toString() =>
      "GridStateBase: $name, $time, '$tags', $scrollOffset, $safeMode";
}

extension GridStateBooruExt on GridStateBooru {
  void save() => _currentDb.gridStateBooru.add(this);
}

mixin GridStateBooru implements GridStateBase {
  Booru get booru;

  GridStateBooru copy({
    String? name,
    Booru? booru,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  });
}

abstract interface class GridStateBooruService {
  int get count;

  List<GridStateBooru> get all;

  GridStateBooru? get(String name);

  void delete(String name);

  void add(GridStateBooru state);

  StreamSubscription<void> watch(void Function(void) f, [bool fire = false]);
}

extension GridStateExt on GridState {
  void save(MainGridService s) => s.currentState = this;
  void saveSecondary(SecondaryGridService s) => s.currentState = this;
}

mixin GridState implements GridStateBase {
  GridState copy({
    String? name,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  });
}

abstract interface class MainGridService {
  int get page;
  set page(int p);

  GridState get currentState;
  set currentState(GridState state);

  TagManager get tagManager;

  PostsOptimizedStorage get savedPosts;

  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    HiddenBooruPostService hiddenBooruPosts,
  );
}

abstract interface class SecondaryGridService {
  int get page;
  set page(int p);

  GridState get currentState;
  set currentState(GridState state);

  TagManager get tagManager;

  PostsOptimizedStorage get savedPosts;

  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    String tags,
    HiddenBooruPostService hiddenBooruPosts,
  );

  Future<void> destroy();
  Future<void> close();
}
