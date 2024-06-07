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
import "package:gallery/src/db/services/resource_source/resource_source.dart";
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
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/manga/manga_info_page.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
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

ServicesObjFactoryExt get objFactory => _currentDb;

abstract interface class ServicesImplTable
    with ServicesObjFactoryExt
    implements ServiceMarker {
  SettingsService get settings;
  MiscSettingsService get miscSettings;
  SavedAnimeEntriesService get savedAnimeEntries;
  SavedAnimeCharactersService get savedAnimeCharacters;
  WatchedAnimeEntryService get watchedAnime;
  VideoSettingsService get videoSettings;
  HiddenBooruPostService get hiddenBooruPost;
  DownloadFileService get downloads;
  FavoritePostSourceService get favoritePosts;
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
  GridBookmarkService get gridBookmarks;
  FavoriteFileService get favoriteFiles;
  DirectoryTagService get directoryTags;
  BlacklistedDirectoryService get blacklistedDirectories;
  GridSettingsService get gridSettings;

  MainGridService mainGrid(Booru booru);
  SecondaryGridService secondaryGrid(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]);
}

mixin ServicesObjFactoryExt {
  TagManager makeTagManager(Booru booru);

  LocalTagsData makeLocalTagsData(
    String filename,
    List<String> tags,
  );

  CompactMangaData makeCompactMangaData({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  });

  DownloadFileData makeDownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  });

  HiddenBooruPostData makeHiddenBooruPostData(
    String thumbUrl,
    int postId,
    Booru booru,
  );

  PinnedManga makePinnedManga({
    required String mangaId,
    required MangaMeta site,
    required String thumbUrl,
    required String title,
  });

  GridBookmark makeGridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
  });

  BlacklistedDirectoryData makeBlacklistedDirectoryData(
    String bucketId,
    String name,
  );

  AnimeGenre makeAnimeGenre({
    required String title,
    required int id,
    required bool unpressable,
    required bool explicit,
  });

  AnimeRelation makeAnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  });

  AnimeCharacter makeAnimeCharacter({
    required String imageUrl,
    required String name,
    required String role,
  });
}

final ServicesImplTable _currentDb = getApi();
typedef DbConn = ServicesImplTable;

class DatabaseConnectionNotifier extends InheritedWidget {
  const DatabaseConnectionNotifier._({
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

abstract interface class LocalTagDictionaryService {
  void add(List<String> tags);

  Future<List<BooruTag>> complete(String string);
}

abstract class LocalTagsData {
  const LocalTagsData(this.filename, this.tags);

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

  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData) f,
  );
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
    required this.tagManager,
    required super.child,
  });

  final TagManager tagManager;

  @override
  bool updateShouldNotify(_TagManagerAnchor oldWidget) =>
      tagManager != oldWidget.tagManager;
}

abstract class GridBookmark implements CellBase {
  const GridBookmark({
    required this.tags,
    required this.booru,
    required this.name,
    required this.time,
  });

  final String tags;

  @enumerated
  final Booru booru;

  @Index(unique: true, replace: true)
  final String name;
  @Index()
  final DateTime time;

  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
  });

  @override
  String alias(bool long) => tags;

  @override
  Key uniqueKey() => ValueKey(name);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String toString() => "GridBookmarkBase: $name $time";
}

extension GridStateBooruExt on GridBookmark {
  void save() => _currentDb.gridBookmarks.add(this);
}

abstract class GridState {
  const GridState({
    required this.name,
    required this.offset,
    required this.tags,
    required this.safeMode,
  });

  @Index(unique: true, replace: true)
  final String name;

  final double offset;
  final String tags;
  @enumerated
  final SafeMode safeMode;

  GridState copy({
    String? name,
    double? offset,
    String? tags,
    SafeMode? safeMode,
  });
}

abstract interface class GridBookmarkService {
  int get count;

  List<GridBookmark> get all;

  GridBookmark? get(String name);

  List<GridBookmark> firstNumber(int n);

  void delete(String name);

  void add(GridBookmark state);

  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]);
}

extension GridStateExt on GridState {
  void save(MainGridService s) => s.currentState = this;
  void saveSecondary(SecondaryGridService s) => s.currentState = this;
}

abstract interface class MainGridService {
  int get page;
  set page(int p);

  DateTime get time;
  set time(DateTime d);

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
  String get name;

  int get page;
  set page(int p);

  GridState get currentState;
  set currentState(GridState state);

  StreamSubscription<GridState> watch(
    void Function(GridState s) f, [
    bool fire = false,
  ]);

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

class BufferedStorage<T> {
  final List<T> _buffer = [];
  int _offset = 0;
  int _cursor = -1;
  bool _done = false;

  T get current => _buffer[_cursor];

  bool moveNext(Iterable<T> Function(int offset, int limit) nextItems) {
    if (_done) {
      return false;
    }

    if (_buffer.isNotEmpty && _cursor != _buffer.length - 1) {
      _cursor += 1;
      return true;
    }

    final ret = nextItems(_offset, 40);
    if (ret.isEmpty) {
      _cursor = -1;
      _buffer.clear();
      _offset = -1;
      return !(_done = true);
    }

    _cursor = 0;
    _buffer.clear();
    _buffer.addAll(ret);
    _offset += _buffer.length;

    return true;
  }
}
