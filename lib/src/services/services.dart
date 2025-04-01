// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// ignore_for_file: unnecessary_late

import "dart:async";
import "dart:math";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform
    show
        DirectoryFile,
        FilesCursor,
        GalleryPageChangeEvent,
        NotificationChannel,
        NotificationGroup,
        NotificationRouteEvent;
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/posts_source.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/io.dart"
    if (dart.library.html) "package:azari/src/services/impl/web.dart";
import "package:azari/src/services/impl/obj/blacklisted_directory_data_impl.dart";
import "package:azari/src/services/impl/obj/directory_impl.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell/contentable.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:mime/mime.dart" as mime;
import "package:path/path.dart" as path;

export "package:azari/src/generated/platform/platform_api.g.dart"
    show NotificationChannel, NotificationGroup, NotificationRouteEvent;

part "blacklisted_directory.dart";
part "directory_metadata.dart";
part "download_file.dart";
part "download_manager.dart";
part "favorite_post.dart";
part "gallery_service.dart";
part "grid_settings.dart";
part "hidden_booru_post.dart";
part "platform_api.dart";
part "settings.dart";
part "statistics_booru.dart";
part "statistics_daily.dart";
part "statistics_gallery.dart";
part "statistics_general.dart";
part "tasks.dart";
part "thumbnail.dart";
part "video_settings.dart";

Future<void> initServices(AppInstanceType appType) {
  if (_isInit) {
    return Future.value();
  }
  _isInit = true;

  return Future(() async {
    _dbInstance = await init(appType);

    return;
  });
}

Widget injectWidgetEvents(Widget child) =>
    _dbInstance.injectWidgetEvents(child);

enum AppInstanceType {
  full,
  quickView,
  pickFile;
}

abstract interface class Services implements ServiceMarker {
  T? get<T extends ServiceMarker>();
  T require<T extends RequiredService>();

  Widget injectWidgetEvents(Widget child);
}

mixin class GridDbService implements ServiceMarker {
  const GridDbService();

  static bool get available => _instance != null;
  static GridDbService? safe() => _instance;

  static late final _instance = _dbInstance.get<GridDbService>();

  MainGridHandle openMain(Booru booru) => _instance!.openMain(booru);
  SecondaryGridHandle openSecondary(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]) =>
      _instance!.openSecondary(booru, name, safeMode, create);
}

bool _isInit = false;
late final Services _dbInstance;

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

mixin class VisitedPostsService implements ServiceMarker {
  const VisitedPostsService();

  static bool get available => _instance != null;
  static VisitedPostsService? safe() => _instance;

  static late final VisitedPostsService? _instance =
      _dbInstance.get<VisitedPostsService>();

  List<VisitedPost> get all => _instance!.all;

  void addAll(List<VisitedPost> visitedPosts) =>
      _instance!.addAll(visitedPosts);

  void removeAll(List<VisitedPost> visitedPosts) =>
      _instance!.removeAll(visitedPosts);

  void clear() => _instance!.clear();

  StreamSubscription<void> watch(void Function(void) f) => _instance!.watch(f);
}

sealed class ServiceMarker extends Object {}

sealed class RequiredService extends Object {}

abstract class LocalTagsData {
  const factory LocalTagsData({
    required String filename,
    required List<String> tags,
  }) = $LocalTagsData;

  String get filename;
  List<String> get tags;
}

mixin class LocalTagsService implements ServiceMarker {
  const LocalTagsService();

  static bool get available => _instance != null;
  static LocalTagsService? safe() => _instance;

  static late final LocalTagsService? _instance =
      _dbInstance.get<LocalTagsService>();

  int get count => _instance!.count;

  List<String> get(String filename) => _instance!.get(filename);
  List<BooruTag> mostFrequent(int count) => _instance!.mostFrequent(count);

  void add(String filename, List<String> tags) =>
      _instance!.add(filename, tags);
  void addAll(List<LocalTagsData> tags) => _instance!.addAll(tags);
  void addMultiple(List<String> filenames, String tag) =>
      _instance!.addMultiple(filenames, tag);

  void delete(String filename) => _instance!.delete(filename);
  void removeSingle(List<String> filenames, String tag) =>
      _instance!.removeSingle(filenames, tag);

  void addFrequency(List<String> tags) => _instance!.addFrequency(tags);

  Future<List<BooruTag>> complete(String string) => _instance!.complete(string);

  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData) f,
  ) =>
      _instance!.watch(filename, f);
}

enum TagType {
  normal,
  pinned,
  excluded;
}

mixin class DirectoryTagService implements ServiceMarker {
  const DirectoryTagService();

  static DirectoryTagService? safe() => _instance;
  static bool get available => _instance != null;

  static late final _instance = _dbInstance.get<DirectoryTagService>();

  String? get(String bucketId) => _instance!.get(bucketId);
  bool searchByTag(String tag) => _instance!.searchByTag(tag);
  void add(Iterable<String> bucketIds, String tag) =>
      _instance!.add(bucketIds, tag);
  void delete(Iterable<String> buckedIds) => _instance!.delete(buckedIds);
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
    bool fire = false,
  });
}

mixin class TagManagerService implements ServiceMarker {
  const TagManagerService();

  static bool get available => _instance != null;
  static TagManagerService? safe() => _instance;

  static late final _instance = _dbInstance.get<TagManagerService>();

  BooruTagging<Excluded> get excluded => _instance!.excluded;
  BooruTagging<Latest> get latest => _instance!.latest;
  BooruTagging<Pinned> get pinned => _instance!.pinned;
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
abstract class GridBookmarkThumbnail {
  const factory GridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) = $GridBookmarkThumbnail;

  String get url;
  PostRating get rating;
}

extension GridStateBooruExt on GridBookmark {
  void maybeSave() => _dbInstance.get<GridBookmarkService>()?.add(this);
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

mixin class GridBookmarkService implements ServiceMarker {
  const GridBookmarkService();

  static bool get available => _instance != null;
  static GridBookmarkService? safe() => _instance;

  static late final _instance = _dbInstance.get<GridBookmarkService>();

  int get count => _instance!.count;

  List<GridBookmark> get all => _instance!.all;

  GridBookmark? get(String name) => _instance!.get(name);
  GridBookmark? getFirstByTags(String tags, Booru preferBooru) =>
      _instance!.getFirstByTags(tags, preferBooru);

  List<GridBookmark> complete(String str) => _instance!.complete(str);

  List<GridBookmark> firstNumber(int n) => _instance!.firstNumber(n);

  void delete(String name) => _instance!.delete(name);

  void add(GridBookmark state) => _instance!.add(state);

  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]) =>
      _instance!.watch(f, fire);
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
    void Function(GridPostSource)? onNextCompleted,
    void Function(GridPostSource)? onClearRefreshCompleted,
  });
}

class UpdatesAvailableStatus {
  const UpdatesAvailableStatus(
    this.hasUpdates,
    this.inRefresh,
  );

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
    void Function(GridPostSource)? onClearRefreshCompleted,
    void Function(GridPostSource)? onNextCompleted,
  });

  Future<void> destroy();
  Future<void> close();
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

mixin class HottestTagsService implements ServiceMarker {
  const HottestTagsService();

  static bool get available => _instance != null;
  static HottestTagsService? safe() => _instance;

  static late final _instance = _dbInstance.get<HottestTagsService>();

  DateTime? refreshedAt(Booru booru) => _instance!.refreshedAt(booru);

  List<HottestTag> all(Booru booru) => _instance!.all(booru);

  void replace(List<HottestTag> tags, Booru booru) =>
      _instance!.replace(tags, booru);

  StreamSubscription<void> watch(Booru booru, void Function(void) f) =>
      _instance!.watch(booru, f);
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
    var url = switch (const SettingsService().current.quality) {
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
    if (!TagManagerService.available || !VisitedPostsService.available) {
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

        const VisitedPostsService().addAll([
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
      tags: (c) =>
          DefaultPostPressable.imageViewTags(c, const TagManagerService()),
      watchTags: (c, f) => DefaultPostPressable.watchTags(
        c,
        f,
        const TagManagerService().pinned,
      ),
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
    if (this is! FavoritePost &&
        const SettingsService().current.sampleThumbnails) {
      PostCell.openMaximizedImage(
        context,
        this,
        content(context),
      );

      return;
    }

    final fnc = OnBooruTagPressed.of(context);

    final source = this is FavoritePost
        ? getSource<FavoritePost>(context)
        : getSource<Post>(context);

    void tryScrollTo(int i) =>
        ShellScrollNotifier.maybeScrollToOf(context, i, true);

    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        barrierDismissible: true,
        fullscreenDialog: true,
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        pageBuilder: (context, animation, secondaryAnimation) {
          return OnBooruTagPressed(
            onPressed: fnc,
            child: CardDialog(
              animation: animation,
              source: source,
              tryScrollTo: tryScrollTo,
              idx: idx,
            ),
          );
        },
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
