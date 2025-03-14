// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/impl_table/io.dart"
    if (dart.library.html) "package:azari/src/db/services/impl_table/web.dart";
import "package:azari/src/db/services/obj_impls/blacklisted_directory_data_impl.dart";
import "package:azari/src/db/services/obj_impls/directory_impl.dart";
import "package:azari/src/db/services/obj_impls/file_impl.dart";
import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/grid_cell/contentable.dart";
import "package:azari/src/widgets/grid_cell_widget.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/post_cell.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/layouts/segment_layout.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:mime/mime.dart" as mime;

part "blacklisted_directory.dart";
part "directory_metadata.dart";
part "download_file.dart";
part "favorite_post.dart";
part "gallery_service.dart";
part "grid_settings.dart";
part "hidden_booru_post.dart";
part "misc_settings.dart";
part "settings.dart";
part "statistics_booru.dart";
part "statistics_daily.dart";
part "statistics_gallery.dart";
part "statistics_general.dart";
part "thumbnail.dart";
part "video_settings.dart";

Future<void> initServices(AppInstanceType appType) async {
  _downloadManager ??= await init(_currentDb, appType);

  return Future.value();
}

int refreshPostCountLimit() {
  return 100;
}

enum AppInstanceType {
  full,
  quickView,
  pickFile;
}

DownloadManager? _downloadManager;

abstract interface class Services implements ServiceMarker {
  T? get<T extends ServiceMarker>();
  T require<T extends RequiredService>();

  static T? getOf<T extends ServiceMarker>(BuildContext context) =>
      of(context).get<T>();
  static T requireOf<T extends RequiredService>(BuildContext context) =>
      of(context).require<T>();

  static T? unsafeGet<T extends ServiceMarker>() => _currentDb.get<T>();
  static T unsafeRequire<T extends RequiredService>() =>
      _currentDb.require<T>();

  static Widget inject(Widget child) => _ServicesNotifier._(
        downloadManager: _downloadManager,
        db: _currentDb,
        child: child,
      );

  static Services of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_ServicesNotifier>();

    return widget!.db;
  }

  static DownloadManager? downloadManagerOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_ServicesNotifier>();

    return widget!.downloadManager;
  }

  static bool get hasDownloadManager => _downloadManager != null;
}

abstract interface class GridDbService implements ServiceMarker {
  MainGridHandle openMain(Booru booru);
  SecondaryGridHandle openSecondary(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]);
}

final Services _currentDb = getApi();

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
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((booru, id));

  @override
  void onPressed(
    BuildContext context,
    int idx,
  ) =>
      Post.imageViewSingle(
        context,
        booru,
        id,
        // wrapNotifiers: functionality.registerNotifiers, // TODO: fix
      );
}

abstract interface class VisitedPostsService implements ServiceMarker {
  List<VisitedPost> get all;

  void addAll(List<VisitedPost> visitedPosts);
  void removeAll(List<VisitedPost> visitedPosts);

  void clear();

  StreamSubscription<void> watch(void Function(void) f);
}

class _ServicesNotifier extends InheritedWidget {
  const _ServicesNotifier._({
    required this.downloadManager,
    required this.db,
    required super.child,
  });

  final Services db;
  final DownloadManager? downloadManager;

  @override
  bool updateShouldNotify(_ServicesNotifier oldWidget) => db != oldWidget.db;
}

sealed class ServiceMarker {}

sealed class RequiredService {}

abstract class LocalTagsData {
  const factory LocalTagsData({
    required String filename,
    required List<String> tags,
  }) = $LocalTagsData;

  String get filename;
  List<String> get tags;
}

abstract interface class LocalTagsService implements ServiceMarker {
  int get count;

  List<String> get(String filename);
  List<BooruTag> mostFrequent(int count);

  void add(String filename, List<String> tags);
  void addAll(List<LocalTagsData> tags);
  void addMultiple(List<String> filenames, String tag);

  void delete(String filename);
  void removeSingle(List<String> filenames, String tag);

  void addFrequency(List<String> tags);

  Future<List<BooruTag>> complete(String string);

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

abstract interface class DirectoryTagService implements ServiceMarker {
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

abstract class TagDataImpl
    with DefaultBuildCellImpl
    implements TagData, CellBase {
  const TagDataImpl();

  @override
  String alias(bool long) => tag;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Key uniqueKey() => ValueKey((tag, type));
}

sealed class BooruTaggingType {
  const BooruTaggingType();
}

abstract class Excluded implements BooruTaggingType {}

abstract class Latest implements BooruTaggingType {}

abstract class Pinned implements BooruTaggingType {}

/// Tag search history.
/// Used for both for the recent tags and the excluded.
abstract class BooruTagging<T extends BooruTaggingType> {
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

abstract interface class TagManagerService implements ServiceMarker {
  BooruTagging<Excluded> get excluded;
  BooruTagging<Latest> get latest;
  BooruTagging<Pinned> get pinned;
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
abstract class GridBookmarkImpl
    with DefaultBuildCellImpl
    implements CellBase, GridBookmark {
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
  void maybeSave() => _currentDb.get<GridBookmarkService>()?.add(this);
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

abstract interface class GridBookmarkService implements ServiceMarker {
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
  void save(MainGridHandle s) => s.currentState = this;
  void saveSecondary(SecondaryGridHandle s) => s.currentState = this;
}

abstract interface class MainGridHandle {
  int get page;
  set page(int p);

  DateTime get time;
  set time(DateTime d);

  GridState get currentState;
  set currentState(GridState state);

  GridPostSource makeSource(
    BooruAPI api,
    PagingEntry entry, {
    required BooruTagging<Excluded>? excluded,
    required HiddenBooruPostsService? hiddenBooruPosts,
    void Function(GridPostSource)? onNextCompleted,
    void Function(GridPostSource)? onClearRefreshCompleted,
  });
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

abstract interface class SecondaryGridHandle {
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
    PagingEntry entry,
    String tags, {
    required BooruTagging<Excluded>? excluded,
    required HiddenBooruPostsService? hiddenBooruPosts,
    void Function(GridPostSource)? onClearRefreshCompleted,
    void Function(GridPostSource)? onNextCompleted,
  });

  Future<void> destroy();
  Future<void> close();
}

class BufferedStorage<T> {
  BufferedStorage(this.bufferLen);

  final List<T> _buffer = [];
  final int bufferLen;
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

    final ret = nextItems(_offset, bufferLen);
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

abstract interface class HottestTagsService implements ServiceMarker {
  DateTime? refreshedAt(Booru booru);

  List<HottestTag> all(Booru booru);

  void replace(List<HottestTag> tags, Booru booru);

  StreamSubscription<void> watch(Booru booru, void Function(void) f);
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
    required int size,
  }) = $Post;

  static String getUrl(PostBase p) {
    var url = switch (
        Services.unsafeRequire<SettingsService>().current.quality) {
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
    final db = Services.of(context);
    final (tagManager, visitedPosts) =
        (db.get<TagManagerService>(), db.get<VisitedPostsService>());

    if (tagManager == null || visitedPosts == null) {
      showSnackbar(context, "Couldn't launch image view"); // TODO: change

      return;
    }

    ImageView.launchWrappedAsyncSingle(
      context,
      () async {
        final dio = BooruAPI.defaultClientForBooru(booru);
        final api = BooruAPI.fromEnum(booru, dio);

        final Post post;
        try {
          post = await api.singlePost(postId);
        } catch (e) {
          rethrow;
        } finally {
          dio.close(force: true);
        }

        visitedPosts.addAll([
          VisitedPost(
            booru: booru,
            id: postId,
            thumbUrl: post.previewUrl,
            rating: post.rating,
            date: DateTime.now(),
          ),
        ]);

        return () => post.content(context);
      },
      wrapNotifiers: wrapNotifiers,
      tags: (c) => DefaultPostPressable.imageViewTags(c, tagManager),
      watchTags: (c, f) =>
          DefaultPostPressable.watchTags(c, f, tagManager.pinned),
    );
  }
}

enum PostRating {
  general,
  sensitive,
  questionable,
  explicit;

  String translatedName(AppLocalizations l10n) => switch (this) {
        PostRating.general => l10n.enumPostRatingGeneral,
        PostRating.sensitive => l10n.enumPostRatingSensitive,
        PostRating.questionable => l10n.enumPostRatingQuestionable,
        PostRating.explicit => l10n.enumPostRatingExplicit,
      };

  SafeMode get asSafeMode => switch (this) {
        PostRating.general => SafeMode.normal,
        PostRating.sensitive => SafeMode.relaxed,
        PostRating.questionable || PostRating.explicit => SafeMode.none,
      };
}

enum PostContentType {
  none,
  video,
  gif,
  image;

  Icon toIcon() => switch (this) {
        PostContentType.none => const Icon(Icons.hide_image_outlined),
        PostContentType.video => const Icon(Icons.slideshow_outlined),
        PostContentType.image ||
        PostContentType.gif =>
          const Icon(Icons.photo_outlined),
      };

  static PostContentType fromUrl(String url) {
    final t = mime.lookupMimeType(url);
    if (t == null) {
      return PostContentType.none;
    }

    final typeHalf = t.split("/");

    if (typeHalf[0] == "image") {
      return typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
    } else if (typeHalf[0] == "video") {
      return PostContentType.video;
    } else {
      throw "";
    }
  }
}

abstract class PostBase {
  const PostBase();

  int get id;

  String get md5;

  List<String> get tags;

  int get width;
  int get height;

  String get fileUrl;
  String get previewUrl;
  String get sampleUrl;
  String get sourceUrl;
  PostRating get rating;
  int get score;
  int get size;
  DateTime get createdAt;
  Booru get booru;
  PostContentType get type;
}

mixin DefaultPostPressable<T extends PostImpl>
    implements PostImpl, Pressable<T> {
  @override
  void onPressed(
    BuildContext context,
    int idx,
  ) {
    final db = Services.of(context);
    final (tagManager, visitedPosts, settingsService) = (
      db.get<TagManagerService>(),
      db.get<VisitedPostsService>(),
      db.require<SettingsService>(),
    );

    if (this is! FavoritePost && settingsService.current.sampleThumbnails) {
      PostCell.openMaximizedImage(
        context,
        this,
        content(context),
      );

      return;
    }

    final fnc = OnBooruTagPressed.of(context);

    ImageView.defaultForGrid<T>(
      context,
      ImageViewDescription(
        ignoreOnNearEnd: false,
        statistics: StatisticsBooruService.asImageViewStatistics(),
      ),
      idx,
      tagManager == null ? null : (c) => imageViewTags(c, tagManager),
      tagManager == null ? null : (c, f) => watchTags(c, f, tagManager.pinned),
      visitedPosts == null
          ? null
          : (post) {
              visitedPosts.addAll([
                VisitedPost(
                  booru: post.booru,
                  id: post.id,
                  rating: post.rating,
                  thumbUrl: post.previewUrl,
                  date: DateTime.now(),
                ),
              ]);
            },
      source: getSource(context),
      wrapNotifiers: (child) => OnBooruTagPressed(
        onPressed: fnc,
        child: child,
      ),
    );
  }

  static List<ImageTag> imageViewTags(
    ContentWidgets c,
    TagManagerService tagManager,
  ) =>
      (c as PostBase)
          .tags
          .map(
            (e) => ImageTag(
              e,
              favorite: tagManager.pinned.exists(e),
              excluded: tagManager.excluded.exists(e),
            ),
          )
          .toList();

  static StreamSubscription<List<ImageTag>> watchTags(
    ContentWidgets c,
    void Function(List<ImageTag> l) f,
    BooruTagging<Pinned> pinnedTags,
  ) =>
      pinnedTags.watchImage((c as PostBase).tags, f);
}

void showSnackbar(BuildContext context, String body) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(body),
    ),
  );
}
