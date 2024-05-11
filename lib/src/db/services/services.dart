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
import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/filtering/filtering_interface.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/manga/manga_info_page.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/pages/manga/next_chapter_button.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_masonry_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:isar/isar.dart";

part "settings.dart";
part "saved_anime_characters.dart";
part "saved_anime_entry.dart";
part "video_settings.dart";
part "misc_settings.dart";
part "hidden_booru_post.dart";
part "favorite_post.dart";
part "grid_settings.dart";
part "saved_manga_chapters.dart";
part "read_manga_chapters.dart";
part "pinned_manga.dart";
part "compact_manga_data.dart";
part "chapters_settings.dart";
part "thumbnail.dart";
part "pinned_thumbnail.dart";
part "favorite_file.dart";
part "directory_metadata.dart";
part "blacklisted_directory.dart";
part "statistics_daily.dart";
part "statistics_booru.dart";
part "statistics_gallery.dart";
part "statistics_general.dart";
part "download_file.dart";
part "watched_anime_entry.dart";

ServicesImplTable get _currentDb => ServicesImplTable.isar;
typedef DbConn = ServicesImplTable;

class DatabaseConnectionNotifier extends InheritedWidget {
  const DatabaseConnectionNotifier._({
    super.key,
    required this.db,
    required super.child,
  });

  factory DatabaseConnectionNotifier.current(Widget child) =>
      DatabaseConnectionNotifier._(
        db: _currentDb,
        child: child,
      );

  final DbConn db;

  static DbConn of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<DatabaseConnectionNotifier>();

    return widget!.db;
  }

  @override
  bool updateShouldNotify(DatabaseConnectionNotifier oldWidget) =>
      db != oldWidget.db;
}

enum ServicesImplTable {
  isar;

  SettingsService get settings => switch (this) {
        ServicesImplTable.isar => const IsarSettingsService(),
      };

  MiscSettingsService get miscSettings => switch (this) {
        ServicesImplTable.isar => const IsarMiscSettingsService(),
      };

  SavedAnimeEntriesService get savedAnimeEntries => switch (this) {
        ServicesImplTable.isar => const IsarSavedAnimeEntriesService(),
      };

  SavedAnimeCharactersService get savedAnimeCharacters => switch (this) {
        ServicesImplTable.isar => const IsarSavedAnimeCharatersService(),
      };

  WatchedAnimeEntryService get watchedAnime => switch (this) {
        ServicesImplTable.isar => const IsarWatchedAnimeEntryService(),
      };

  VideoSettingsService get videoSettings => switch (this) {
        ServicesImplTable.isar => const IsarVideoService(),
      };

  HiddenBooruPostService get hiddenBooruPost => switch (this) {
        ServicesImplTable.isar => const IsarHiddenBooruPostService(),
      };

  DownloadFileService get downloads => switch (this) {
        ServicesImplTable.isar => const IsarDownloadFileService(),
      };

  FavoritePostService get favoritePosts => switch (this) {
        ServicesImplTable.isar => const IsarFavoritePostService(),
      };

  StatisticsGeneralService get statisticsGeneral => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsGeneralService(),
      };

  StatisticsGalleryService get statisticsGallery => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsGalleryService(),
      };

  StatisticsBooruService get statisticsBooru => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsBooruService(),
      };

  StatisticsDailyService get statisticsDaily => switch (this) {
        ServicesImplTable.isar => const IsarDailyStatisticsService(),
      };

  DirectoryMetadataService get directoryMetadata => switch (this) {
        ServicesImplTable.isar => const IsarDirectoryMetadataService(),
      };

  ChaptersSettingsService get chaptersSettings => switch (this) {
        ServicesImplTable.isar => const IsarChapterSettingsService(),
      };

  SavedMangaChaptersService get savedMangaChapters => switch (this) {
        ServicesImplTable.isar => const IsarSavedMangaChaptersService(),
      };

  ReadMangaChaptersService get readMangaChapters => switch (this) {
        ServicesImplTable.isar => const IsarReadMangaChapterService(),
      };

  PinnedMangaService get pinnedManga => switch (this) {
        ServicesImplTable.isar => const IsarPinnedMangaService(),
      };

  ThumbnailService get thumbnails => switch (this) {
        ServicesImplTable.isar => const IsarThumbnailService(),
      };

  PinnedThumbnailService get pinnedThumbnails => switch (this) {
        ServicesImplTable.isar => const IsarPinnedThumbnailService(),
      };

  LocalTagsService get localTags => switch (this) {
        ServicesImplTable.isar => const IsarLocalTagsService(),
      };

  LocalTagDictionaryService get localTagDictionary => switch (this) {
        ServicesImplTable.isar => const IsarLocalTagDictionaryService(),
      };

  CompactMangaDataService get compactManga => switch (this) {
        ServicesImplTable.isar => const IsarCompactMangaDataService(),
      };

  GridStateBooruService get gridStateBooru => switch (this) {
        ServicesImplTable.isar => const IsarGridStateBooruService(),
      };

  FavoriteFileService get favoriteFiles => switch (this) {
        ServicesImplTable.isar => const IsarFavoriteFileService(),
      };

  DirectoryTagService get directoryTags => switch (this) {
        ServicesImplTable.isar => const IsarDirectoryTagService(),
      };

  BlacklistedDirectoryService get blacklistedDirectories => switch (this) {
        ServicesImplTable.isar => const IsarBlacklistedDirectoryService(),
      };

  GridSettingsService get gridSettings => switch (this) {
        ServicesImplTable.isar => const IsarGridSettinsService(),
      };

  MainGridService mainGrid(Booru booru) => switch (this) {
        ServicesImplTable.isar => IsarMainGridService.booru(booru),
      };

  SecondaryGridService secondaryGrid(Booru booru, String name) =>
      switch (this) {
        ServicesImplTable.isar => IsarSecondaryGridService.booru(booru, name),
      };
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

abstract class SourceStorage<T> with Iterable<T> {
  int get count;

  void add(T e);

  T? get(int idx);

  void addAll(List<T> l);

  void removeAll(List<int> idx);

  void clear();

  void destroy();

  T operator [](int index);
  void operator []=(int index, T value);
}

class ListStorage<T> extends SourceStorage<T> {
  ListStorage();

  final List<T> list = [];

  @override
  void add(T e) => list.add(e);

  @override
  int get count => list.length;

  @override
  Iterator<T> get iterator => list.iterator;

  @override
  T? get(int idx) => idx >= list.length ? null : list[idx];

  @override
  void addAll(List<T> l) => list.addAll(l);

  @override
  void clear() => list.clear();

  @override
  void removeAll(List<int> idx) => idx.forEach(list.removeAt);

  @override
  T operator [](int index) => get(index)!;

  @override
  void operator []=(int index, T value) => list[index] = value;

  @override
  void destroy() => clear();
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
  })  : assert(allowedFilteringModes.isEmpty
            ? true
            : allowedFilteringModes.contains(initialFilteringMode)),
        assert(allowedSortingModes.isEmpty
            ? true
            : allowedSortingModes.contains(initialSortingMode)),
        _mode = initialFilteringMode,
        _sorting = initialSortingMode {
    _originalSubscr = _original.watch((c) {
      clearRefresh();
    });
  }

  final ResourceSource<T> _original;
  final SourceStorage<T> _filterStorage;

  @override
  SourceStorage<T> get backingStorage => _filterStorage;

  late final StreamSubscription<int> _originalSubscr;
  final StreamController<int> _events = StreamController.broadcast();

  final Set<FilteringMode> allowedFilteringModes;
  final Set<SortingMode> allowedSortingModes;

  FilteringMode _mode;
  SortingMode _sorting;

  FilteringMode get filteringMode => _mode;
  SortingMode get sortingMode => _sorting;

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

  bool _filteringInProgress = false;

  @override
  int get count => backingStorage.count;

  @override
  Future<int> clearRefresh() async {
    if (_filteringInProgress) {
      throw "filtering is in progress";
    }
    _filteringInProgress = true;

    backingStorage.clear();
    _events.add(count);

    if (_original.backingStorage.count == 0) {
      _filteringInProgress = false;
      return 0;
    }

    for (final e in _original.backingStorage) {
      final keep = fn(e, _mode, _sorting);
      if (keep) {
        backingStorage.add(e);
      }
    }

    _events.add(count);

    _filteringInProgress = false;

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
    _events.close();
    _originalSubscr.cancel();

    _currentProgress?.ignore();
  }

  @override
  StreamSubscription<int> watch(void Function(int c) f) =>
      _events.stream.listen(f);
}

abstract interface class ResourceSource<T> {
  const ResourceSource();

  SourceStorage<T> get backingStorage;

  int get count;

  T? forIdx(int idx);
  T forIdxUnsafe(int idx);

  Future<int> clearRefresh();

  Future<int> next();

  void destroy();

  StreamSubscription<int> watch(void Function(int) f);
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
      switch (_currentDb) {
        ServicesImplTable.isar => IsarLocalTags(filename, tags),
      };

  @Index(unique: true, replace: true)
  final String filename;

  @Index(caseSensitive: false, type: IndexType.hashElements)
  final List<String> tags;
}

abstract interface class LocalTagsService {
  int get count;

  List<String> get(String filename);

  void add(String filename, List<String> tags);
  void addAll(List<LocalTagsData> tags);
  void addMultiple(List<String> filenames, String tag);

  void delete(String filename);
  void removeSingle(List<String> filenames, String tag);

  StreamSubscription<List<LocalTagsData>> watch(
    String filename,
    void Function(List<LocalTagsData>) f,
  );

  StreamSubscription<List<ImageTag>> watchImagePinned(
    List<String> tags,
    void Function(List<ImageTag>) f, {
    String? withFilename,
  });
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
  factory TagManager.of(BuildContext context) {}

  BooruTagging get excluded;
  BooruTagging get latest;
  BooruTagging get pinned;
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

  PostsSourceService<Post> makeSource(
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

  PostsSourceService<Post> makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    String tags,
    HiddenBooruPostService hiddenBooruPosts,
  );

  void destroy();
}
