// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/gallery_thumbnail_provider.dart";
import "package:azari/src/db/services/impl_table/io.dart"
    if (dart.library.html) "package:azari/src/db/services/impl_table/web.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/net/manga/manga_api.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/plugs/gallery.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

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

Future<void> initServices(bool temporary) async {
  _downloadManager ??= await init(_currentDb, temporary);

  return Future.value();
}

int refreshPostCountLimit() {
  return 100;
}

DownloadManager? _downloadManager;

abstract interface class ServicesImplTable implements ServiceMarker {
  SettingsService get settings;
  MiscSettingsService get miscSettings;
  SavedAnimeEntriesService get savedAnimeEntries;
  SavedAnimeCharactersService get savedAnimeCharacters;
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
  DirectoryTagService get directoryTags;
  BlacklistedDirectoryService get blacklistedDirectories;
  GridSettingsService get gridSettings;
  VisitedPostsService get visitedPosts;
  AnimeListsService get animeLists;
  HottestTagsService get hottestTags;

  TagManager get tagManager;

  MainGridService mainGrid(Booru booru);
  SecondaryGridService secondaryGrid(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]);
}

final ServicesImplTable _currentDb = getApi();
typedef DbConn = ServicesImplTable;

@immutable
abstract class VisitedPost
    implements CellBase, Thumbnailable, Pressable<VisitedPost> {
  const factory VisitedPost({
    required Booru booru,
    required int id,
    required String thumbUrl,
    required DateTime date,
    required PostRating rating,
  }) = $VisitedPost;

  Booru get booru;
  int get id;
  String get thumbUrl;
  DateTime get date;
  PostRating get rating;
}

mixin VisitedPostImpl implements VisitedPost {
  @override
  String alias(bool long) => id.toString();

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((booru, id));

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<VisitedPost> functionality,
    VisitedPost cell,
    int idx,
  ) =>
      Post.imageViewSingle(
        context,
        booru,
        id,
        wrapNotifiers: functionality.registerNotifiers,
      );
}

abstract interface class VisitedPostsService {
  List<VisitedPost> get all;

  void addAll(List<VisitedPost> visitedPosts);
  void removeAll(List<VisitedPost> visitedPosts);

  void clear();

  StreamSubscription<void> watch(void Function(void) f);
}

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
  List<BooruTag> mostFrequent(int count);

  void add(List<String> tags);

  Future<List<BooruTag>> complete(String string);
}

abstract class LocalTagsData {
  const factory LocalTagsData({
    required String filename,
    required List<String> tags,
  }) = $LocalTagsData;

  String get filename;
  List<String> get tags;
}

abstract interface class LocalTagsService {
  factory LocalTagsService.db() => _currentDb.localTags;

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
  bool searchByTag(String tag);
  void add(Iterable<String> bucketIds, String tag);
  void delete(Iterable<String> buckedIds);
}

@immutable
abstract class TagData implements CellBase {
  const factory TagData({
    required String tag,
    required TagType type,
    required DateTime time,
  }) = $TagData;

  String get tag;
  TagType get type;
  DateTime get time;

  TagData copy({String? tag, TagType? type});
}

abstract class TagDataImpl implements TagData, CellBase {
  const TagDataImpl();

  @override
  String alias(bool long) => tag;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Key uniqueKey() => ValueKey((tag, type));
}

/// Tag search history.
/// Used for both for the recent tags and the excluded.
abstract class BooruTagging {
  const BooruTagging();

  bool exists(String tag);

  List<TagData> complete(String string);

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
  StreamSubscription<int> watchCount(void Function(int) f, [bool fire = false]);

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
    final widget = context
        .dependOnInheritedWidgetOfExactType<DatabaseConnectionNotifier>();

    return widget!.db.tagManager;
  }

  BooruTagging get excluded;
  BooruTagging get latest;
  BooruTagging get pinned;
}

@immutable
abstract class GridBookmark implements CellBase {
  const factory GridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
  }) = $GridBookmark;

  String get tags;
  Booru get booru;
  String get name;
  DateTime get time;
  List<GridBookmarkThumbnail> get thumbnails;

  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
    List<GridBookmarkThumbnail>? thumbnails,
  });
}

@immutable
abstract class GridBookmarkImpl implements CellBase, GridBookmark {
  const GridBookmarkImpl();

  @override
  String alias(bool long) => tags;

  @override
  Key uniqueKey() => ValueKey(name);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String toString() => "GridBookmarkBase: $name $time";
}

@immutable
abstract class GridBookmarkThumbnail {
  const factory GridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) = $GridBookmarkThumbnail;

  String get url;
  PostRating get rating;
}

extension GridStateBooruExt on GridBookmark {
  void save() => _currentDb.gridBookmarks.add(this);
}

abstract class GridState {
  const factory GridState({
    required String name,
    required double offset,
    required String tags,
    required SafeMode safeMode,
  }) = $GridState;

  String get name;
  double get offset;
  String get tags;
  SafeMode get safeMode;

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
  GridBookmark? getFirstByTags(String tags, Booru preferBooru);

  List<GridBookmark> complete(String str);

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

  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    HiddenBooruPostService hiddenBooruPosts,
  );
}

class UpdatesAvailableStatus {
  const UpdatesAvailableStatus(this.hasUpdates, this.inRefresh);

  final bool hasUpdates;
  final bool inRefresh;
}

abstract interface class UpdatesAvailable {
  bool tryRefreshIfNeeded();

  void setCount(int count);

  StreamSubscription<UpdatesAvailableStatus> watch(
    void Function(UpdatesAvailableStatus) f,
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

@immutable
abstract class HottestTag {
  const factory HottestTag({
    required String tag,
    required int count,
    required Booru booru,
  }) = $HottestTag;

  List<ThumbUrlRating> get thumbUrls;

  Booru get booru;
  String get tag;
  int get count;

  HottestTag copy({
    String? tag,
    int? count,
    Booru? booru,
    List<ThumbUrlRating>? thumbUrls,
  });
}

@immutable
abstract class ThumbUrlRating {
  const factory ThumbUrlRating({
    required int postId,
    required String url,
    required PostRating rating,
  }) = $ThumbUrlRating;

  int get postId;
  String get url;
  PostRating get rating;
}

abstract interface class HottestTagsService {
  DateTime? refreshedAt(Booru booru);

  List<HottestTag> all(Booru booru);

  void replace(List<HottestTag> tags, Booru booru);

  StreamSubscription<void> watch(Booru booru, void Function(void) f);
}

@immutable
abstract class AnimeGenre {
  const factory AnimeGenre({
    required int id,
    required String title,
    required bool unpressable,
    required bool explicit,
  }) = $AnimeGenre;

  String get title;
  int get id;
  bool get unpressable;
  bool get explicit;
}

@immutable
abstract class AnimeRelation {
  const factory AnimeRelation({
    required int id,
    required String thumbUrl,
    required String title,
    required String type,
  }) = $AnimeRelation;

  int get id;
  String get thumbUrl;
  String get title;
  String get type;

  static bool idIsValid(AnimeRelation e) => e.id != 0 && e.type != "manga";

  @override
  String toString() => title;
}

@immutable
abstract class AnimeEntryData
    implements
        AnimeCell,
        ContentWidgets,
        Thumbnailable,
        Downloadable,
        Pressable<AnimeEntryData>,
        Stickerable {
  const factory AnimeEntryData({
    required DateTime? airedFrom,
    required DateTime? airedTo,
    required AnimeMetadata site,
    required String type,
    required String thumbUrl,
    required String imageUrl,
    required String title,
    required String titleJapanese,
    required String titleEnglish,
    required double score,
    required String synopsis,
    required int id,
    required String siteUrl,
    required bool isAiring,
    required List<String> titleSynonyms,
    required String trailerUrl,
    required int episodes,
    required String background,
    required AnimeSafeMode explicit,
  }) = $AnimeEntryData;

  int get id;

  String get thumbUrl;
  String get imageUrl;
  String get siteUrl;
  String get trailerUrl;
  String get title;
  String get titleJapanese;
  String get titleEnglish;
  String get synopsis;
  String get background;
  String get type;

  List<String> get titleSynonyms;
  List<AnimeGenre> get genres;

  List<AnimeRelation> get relations;
  List<AnimeRelation> get staff;

  double get score;

  DateTime? get airedFrom;
  DateTime? get airedTo;

  int get episodes;

  bool get isAiring;
  AnimeSafeMode get explicit;
  AnimeMetadata get site;

  void openInfoPage(BuildContext context);
  dynamic properties();

  AnimeEntryData copy({
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
    double? score,
    String? thumbUrl,
    String? synopsis,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  });
}

mixin DefaultAnimeEntryPressable
    implements Pressable<AnimeEntryData>, AnimeEntryData {
  @override
  void onPress(
    BuildContext context,
    GridFunctionality<AnimeEntryData> functionality,
    AnimeEntryData cell,
    int idx,
  ) {
    openInfoPage(context);
  }
}

@immutable
abstract class Post implements PostBase, PostImpl, Pressable<Post> {
  const factory Post({
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
  }) = $Post;

  static String getUrl(PostBase p) {
    var url = switch (SettingsService.db().current.quality) {
      DisplayQuality.original => p.fileUrl,
      DisplayQuality.sample => p.sampleUrl
    };
    if (url.isEmpty) {
      url = p.sampleUrl.isNotEmpty
          ? p.sampleUrl
          : p.fileUrl.isEmpty
              ? p.previewUrl
              : p.fileUrl;
    }

    return url;
  }

  static PostContentType makeType(PostBase p) {
    final url = getUrl(p);

    return PostContentType.fromUrl(url);
  }

  static void imageViewSingle(
    BuildContext context,
    Booru booru,
    int postId, {
    Widget Function(Widget)? wrapNotifiers,
  }) {
    final db = DatabaseConnectionNotifier.of(context);

    ImageView.launchWrappedAsyncSingle(
      context,
      () async {
        final dio = BooruAPI.defaultClientForBooru(booru);
        final api = BooruAPI.fromEnum(booru, dio, PageSaver.noPersist());

        final Post post;
        try {
          post = await api.singlePost(postId);
        } catch (e) {
          rethrow;
        } finally {
          dio.close(force: true);
        }

        db.visitedPosts.addAll([
          VisitedPost(
            booru: booru,
            id: postId,
            thumbUrl: post.previewUrl,
            rating: post.rating,
            date: DateTime.now(),
          ),
        ]);

        return () => post.content();
      },
      wrapNotifiers: wrapNotifiers,
      tags: (c) => DefaultPostPressable.imageViewTags(c, db.tagManager),
      watchTags: (c, f) => DefaultPostPressable.watchTags(c, f, db.tagManager),
    );
  }
}

abstract interface class AnimeListsService implements ServiceMarker {
  (DateTime, List<AnimeEntryData>) get upcoming;
  (DateTime, List<AnimeEntryData>) get currentSeason;

  void setUpcoming(List<AnimeEntryData> l);
  void clearUpcoming();

  void setCurrentSeason(List<AnimeEntryData> l);
  void clearCurrentSeason();

  StreamSubscription<void> watchAllUpcoming(
    void Function(void) f, [
    bool fire = false,
  ]);

  StreamSubscription<void> watchAllCurrentSeason(
    void Function(void) f, [
    bool fire = false,
  ]);
}
