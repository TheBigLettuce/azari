// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:convert";
import "dart:io" as io;

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/services/impl/io/android/gallery/android_gallery.dart";
import "package:azari/src/services/impl/io/android/platform/impl.dart";
import "package:azari/src/services/impl/io/isar/impl.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/post.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/visited_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/downloader/download_file.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/directory_metadata.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/hottest_tag.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/local_tags.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/tags.dart";
import "package:azari/src/services/impl/io/linux/gallery/impl.dart";
import "package:azari/src/services/impl/io/linux/platform_api/impl.dart";
import "package:azari/src/services/impl/obj/directory_impl.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/services.dart";
import "package:dio/dio.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";

class _OnNotificationPressed implements platform.OnNotificationPressed {
  const _OnNotificationPressed(this.sink);

  final Sink<NotificationRouteEvent> sink;

  @override
  void onPressed(platform.NotificationRouteEvent r) => sink.add(r);
}

Future<Services> init(AppInstanceType appType) async {
  final notificationsEvents =
      StreamController<platform.NotificationRouteEvent>.broadcast();

  if (io.Platform.isAndroid) {
    platform.OnNotificationPressed.setUp(
      _OnNotificationPressed(notificationsEvents.sink),
    );
  }

  final db = IoServices._new(
    switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidPlatformImpl(
          accentColor: Color(
            (await AndroidPlatformImpl.appContext.invokeMethod("accentColor"))
                as int,
          ),
          version: await AndroidPlatformImpl.activityContext
              .invokeMethod("version")
              .then((v) => v as String),
          galleryImpl: initalizeAndroidGallery(),
          notificationEvents: notificationsEvents.stream,
        ),
      TargetPlatform.linux => LinuxPlatformImpl(
          accentColor: await () async {
            try {
              return (await DynamicColorPlugin.getAccentColor())!;
            } catch (_) {
              return Colors.limeAccent;
            }
          }(),
          version: await () async {
            try {
              final exePath =
                  await io.File("/proc/self/exe").resolveSymbolicLinks();
              final appPath = path.dirname(exePath);
              final assetPath = path.join(appPath, "data", "flutter_assets");
              final versionPath = path.join(assetPath, "version.json");
              // ignore: avoid_dynamic_calls
              return jsonDecode(await io.File(versionPath).readAsString())[
                      "version"] as String? ??
                  "";
            } catch (_) {
              return "";
            }
          }(),
        ),
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows =>
        throw UnimplementedError(),
    },
  );

  await initalizeIsarDb(
    appType,
    db,
    (await getApplicationSupportDirectory()).path,
    (await getTemporaryDirectory()).path,
  );

  return db;
}

class AndroidNotificationChannelId implements NotificationChannelId {
  const AndroidNotificationChannelId(this.id);

  final int id;

  @override
  bool operator ==(Object other) {
    return other is AndroidNotificationChannelId && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _AndroidNotificationChannels implements NotificationChannels {
  _AndroidNotificationChannels();

  int notificationId = 0;

  @override
  NotificationChannelId get redownloadFiles =>
      const AndroidNotificationChannelId(-12);

  @override
  NotificationChannelId get savingTags =>
      const AndroidNotificationChannelId(-10);

  @override
  NotificationChannelId get savingThumb =>
      const AndroidNotificationChannelId(-11);

  @override
  NotificationChannelId downloadId() =>
      AndroidNotificationChannelId(notificationId += 1);
}

class $NotificationChannels implements NotificationChannels {
  const $NotificationChannels();

  static final _instance = _AndroidNotificationChannels();

  @override
  NotificationChannelId get savingTags => _instance.savingTags;
  @override
  NotificationChannelId get savingThumb => _instance.savingThumb;
  @override
  NotificationChannelId get redownloadFiles => _instance.redownloadFiles;

  @override
  NotificationChannelId downloadId() => _instance.downloadId();
}

class IoFilesManagement implements FilesApi {
  const IoFilesManagement();

  static final _log = Logger("IoFilesManagement");

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) async {
    try {
      await io.Directory(path.joinAll([rootDir, targetDir])).create();
      await io.File(source).copy(
        path.joinAll([rootDir, targetDir, path.basename(source)]),
      );
      await io.File(source).delete();
    } catch (e, trace) {
      _log.severe("moveSingle", e, trace);
    }

    return;
  }

  @override
  Future<bool> exists(String filePath) => io.File(filePath).exists();

  @override
  void deleteAll(List<File> selected) {}

  @override
  Future<void> rename(String path, String newName, [bool notify = true]) {
    throw UnimplementedError();
  }

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) {
    return Future.value();
  }

  @override
  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({String path, String formattedPath})?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  }) {
    return FilePicker.platform
        .getDirectoryPath(dialogTitle: l10n.pickDirectory)
        .then((e) => e == null ? null : (path: e, formattedPath: e));
  }
}

class IoTasksService implements TasksService {
  final map = <Type, Future<dynamic>>{};

  final _events = StreamController<void>.broadcast();

  @override
  void add<Tag>(VoidCallback fn) {
    if (map.containsKey(Tag)) {
      return;
    }

    if (fn is Future<dynamic> Function()) {
      map[Tag] = fn().whenComplete(() {
        map.remove(Tag);
        _events.add(null);
      });
    } else {
      map[Tag] = Future(() {
        fn();
      }).whenComplete(() {
        map.remove(Tag);
        _events.add(null);
      });
    }

    _events.add(null);
  }

  @override
  TaskStatus status<Tag>(BuildContext context) => statusUnsafe(context, Tag);

  @override
  TaskStatus statusUnsafe(BuildContext context, Type tag) {
    _TasksEvents.depend(context);

    return map[tag] != null ? TaskStatus.waiting : TaskStatus.done;
  }
}

class IoServices implements Services {
  IoServices._new(this.platformApi);

  @visibleForTesting
  IoServices.newTests(this.platformApi);

  DownloadManager? downloadManager;

  @override
  T? get<T extends ServiceMarker>() {
    // dart doesn't support switch on types
    if (T == StatisticsBooruService) {
      return statisticsBooru as T;
    } else if (T == StatisticsGeneralService) {
      return statisticsGeneral as T;
    } else if (T == StatisticsGalleryService) {
      return statisticsGallery as T;
    } else if (T == StatisticsDailyService) {
      return statisticsDaily as T;
    } else if (T == DirectoryMetadataService) {
      return directoryMetadata as T;
    } else if (T == ThumbnailService) {
      return thumbnails as T;
    } else if (T == VisitedPostsService) {
      return visitedPosts as T;
    } else if (T == GalleryService) {
      return galleryService as T;
    } else if (T == LocalTagsService) {
      return localTags as T;
    } else if (T == HottestTagsService) {
      return hottestTags as T;
    } else if (T == GridBookmarkService) {
      return gridBookmarks as T;
    } else if (T == DirectoryTagService) {
      return directoryTags as T;
    } else if (T == BlacklistedDirectoryService) {
      return blacklistedDirectories as T;
    } else if (T == GridSettingsService) {
      return gridSettings as T;
    } else if (T == TagManagerService) {
      return tagManager as T;
    } else if (T == GridDbService) {
      return gridDbs as T;
    } else if (T == FavoritePostSourceService) {
      return favoritePosts as T;
    } else if (T == DownloadFileService) {
      return downloads as T;
    } else if (T == HiddenBooruPostsService) {
      return hiddenBooruPosts as T;
    } else if (T == VideoSettingsService) {
      return videoSettings as T;
    } else if (T == DownloadManager) {
      return downloadManager! as T;
    } else if (T == GridSettingsData<BooruData>) {
      return gridSettings.booru as T;
    } else if (T == GridSettingsData<DirectoriesData>) {
      return gridSettings.directories as T;
    } else if (T == GridSettingsData<FavoritePostsData>) {
      return gridSettings.favoritePosts as T;
    } else if (T == GridSettingsData<FilesData>) {
      return gridSettings.files as T;
    } else if (T == PlatformApi) {
      return platformApi as T;
    }

    throw "Unimplemented: $T";
  }

  @override
  T require<T extends RequiredService>() {
    if (T == SettingsService) {
      return settings as T;
    } else if (T == TasksService) {
      return tasks as T;
    }

    throw "Unimplemented: $T";
  }

  final IoTasksService tasks = IoTasksService();
  final IsarSettingsService settings = IsarSettingsService();
  VideoSettingsService get videoSettings => const IsarVideoService();
  HiddenBooruPostsService get hiddenBooruPosts =>
      const IsarHiddenBooruPostService();
  DownloadFileService get downloads => const IsarDownloadFileService();
  final FavoritePostSourceService favoritePosts = IsarFavoritePostService();
  StatisticsGeneralService get statisticsGeneral =>
      const IsarStatisticsGeneralService();
  StatisticsGalleryService get statisticsGallery =>
      const IsarStatisticsGalleryService();
  StatisticsBooruService get statisticsBooru =>
      const IsarStatisticsBooruService();
  StatisticsDailyService get statisticsDaily =>
      const IsarDailyStatisticsService();
  final IsarDirectoryMetadataService directoryMetadata =
      IsarDirectoryMetadataService();
  ThumbnailService get thumbnails => const IsarThumbnailService();
  LocalTagsService get localTags => const IsarLocalTagsService();
  GridBookmarkService get gridBookmarks => const IsarGridStateBooruService();
  DirectoryTagService get directoryTags => const IsarDirectoryTagService();
  final BlacklistedDirectoryService blacklistedDirectories =
      IsarBlacklistedDirectoryService();
  GridSettingsService get gridSettings => const IsarGridSettinsService();
  final TagManagerService tagManager = const IsarTagManager();

  VisitedPostsService get visitedPosts => const IsarVisitedPostsService();

  HottestTagsService get hottestTags => const IsarHottestTagsService();

  IsarGridDbsService get gridDbs => const IsarGridDbsService();

  final PlatformApi platformApi;

  late final GalleryService galleryService = io.Platform.isAndroid
      ? const AndroidGalleryApi()
      : const LinuxGalleryApi();

  @override
  Widget injectWidgetEvents(Widget child) {
    return _TasksEventsHolder(
      services: this,
      child: child,
    );
  }
}

class _TasksEventsHolder extends StatefulWidget {
  const _TasksEventsHolder({
    super.key,
    required this.services,
    required this.child,
  });

  final IoServices services;
  final Widget child;

  @override
  State<_TasksEventsHolder> createState() => __TasksEventsHolderState();
}

class __TasksEventsHolderState extends State<_TasksEventsHolder> {
  late final StreamSubscription<void> _events;

  int i = 0;

  @override
  void initState() {
    super.initState();

    _events = widget.services.tasks._events.stream.listen((e) {
      setState(() {
        i += 1;
      });
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TasksEvents(
      dummy: i,
      child: widget.child,
    );
  }
}

class _TasksEvents extends InheritedWidget {
  const _TasksEvents({
    // super.key,
    required this.dummy,
    required super.child,
  });

  final int dummy;

  static void depend(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_TasksEvents>();
  }

  @override
  bool updateShouldNotify(_TasksEvents oldWidget) => dummy != oldWidget.dummy;
}

class IsarGridDbsService implements GridDbService {
  const IsarGridDbsService();

  @override
  MainGridHandle openMain(Booru booru) => IsarMainGridService.booru(booru);

  @override
  SecondaryGridHandle openSecondary(
    Booru booru,
    String name,
    SafeMode? safeMode, [
    bool create = false,
  ]) {
    final api = IsarSecondaryGridService.booru(booru, name, create);
    if (safeMode != null) {
      api.currentState.copy(safeMode: safeMode).saveSecondary(api);
    }

    return api;
  }
}

abstract class $HottestTag extends HottestTag {
  const factory $HottestTag({
    required String tag,
    required int count,
    required Booru booru,
  }) = IsarHottestTag.noIdList;
}

abstract class $ThumbUrlRating extends ThumbUrlRating {
  const factory $ThumbUrlRating({
    required int postId,
    required String url,
    required PostRating rating,
  }) = IsarThumbUrlRating.required;
}

abstract class $GridState extends GridState {
  const factory $GridState({
    required String name,
    required double offset,
    required String tags,
    required SafeMode safeMode,
  }) = IsarGridState.noId;
}

abstract class $GridBookmarkThumbnail extends GridBookmarkThumbnail {
  const factory $GridBookmarkThumbnail({
    required String url,
    required PostRating rating,
  }) = IsarGridBookmarkThumbnail.required;
}

abstract class $GridBookmark extends GridBookmark {
  const factory $GridBookmark({
    required String tags,
    required Booru booru,
    required String name,
    required DateTime time,
  }) = IsarBookmark.noIdList;
}

abstract class $LocalTagsData extends LocalTagsData {
  const factory $LocalTagsData({
    required String filename,
    required List<String> tags,
  }) = IsarLocalTags.noId;
}

abstract class $TagData extends TagData {
  const factory $TagData({
    required String tag,
    required TagType type,
    required DateTime time,
  }) = IsarTag.noId;
}

abstract class $HiddenBooruPostData extends HiddenBooruPostData {
  const factory $HiddenBooruPostData({
    required Booru booru,
    required int postId,
    required String thumbUrl,
  }) = IsarHiddenBooruPost.noId;
}

abstract class $DownloadFileData extends DownloadFileData {
  const factory $DownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) = IsarDownloadFile.noId;
}

abstract class $BlacklistedDirectoryData extends BlacklistedDirectoryData {
  const factory $BlacklistedDirectoryData({
    required String bucketId,
    required String name,
  }) = IsarBlacklistedDirectory.noId;
}

abstract class $Post extends Post {
  const factory $Post({
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
  }) = PostIsar.noId;
}

abstract class $FavoritePost extends FavoritePost {
  const factory $FavoritePost({
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
    required FavoriteStars stars,
  }) = IsarFavoritePost.noId;
}

abstract class $VisitedPost extends VisitedPost {
  const factory $VisitedPost({
    required Booru booru,
    required int id,
    required String thumbUrl,
    required DateTime date,
    required PostRating rating,
  }) = IsarVisitedPost.noId;
}

abstract class $DirectoryMetadata extends DirectoryMetadata {
  const factory $DirectoryMetadata({
    required String categoryName,
    required DateTime time,
  }) = IsarDirectoryMetadata.noIdFlags;
}

class $Directory extends DirectoryImpl
    with PigeonDirectoryPressable
    implements Directory {
  const $Directory({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  @override
  final String bucketId;

  @override
  final int lastModified;

  @override
  final String name;

  @override
  final String relativeLoc;

  @override
  final String tag;

  @override
  final int thumbFileId;

  @override
  final String volumeName;
}

class $File extends FileImpl with PigeonFilePressable implements File {
  const $File({
    required this.bucketId,
    required this.height,
    required this.id,
    required this.isDuplicate,
    required this.isGif,
    required this.isVideo,
    required this.lastModified,
    required this.name,
    required this.originalUri,
    required this.res,
    required this.size,
    required this.tags,
    required this.width,
  });

  @override
  final String bucketId;

  @override
  final int height;

  @override
  final int id;

  @override
  final bool isDuplicate;

  @override
  final bool isGif;

  @override
  final bool isVideo;

  @override
  final int lastModified;

  @override
  final String name;

  @override
  final String originalUri;

  @override
  final (int, Booru)? res;

  @override
  final int size;

  @override
  final Map<String, void> tags;

  @override
  final int width;
}

class MemoryOnlyDownloadManager extends MapStorage<String, DownloadHandle>
    with DefaultDownloadManagerImpl
    implements DownloadManager, ResourceSource<String, DownloadHandle> {
  MemoryOnlyDownloadManager(this.downloadDir) : super((e) => e.data.url);

  @override
  FilesApi? get files => FilesApi.available ? const FilesApi() : null;

  @override
  final client = Dio();

  @override
  final String downloadDir;

  @override
  final ClosableRefreshProgress progress =
      ClosableRefreshProgress(canLoadMore: false);

  @override
  SourceStorage<String, DownloadHandle> get backingStorage => this;

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  bool get hasNext => false;

  @override
  Future<int> next() => Future.value(count);

  @override
  void restoreFile(DownloadFileData f) {}

  @override
  void destroy() {
    super.destroy();
    progress.close();

    client.close();
  }

  @override
  Future<String> ensureDownloadDirExists({
    required String dir,
    required String site,
  }) =>
      Future.value("");
}

abstract class DownloadManagerHasPersistence {
  DownloadFileService get db;
}

class PersistentDownloadManager extends MapStorage<String, DownloadHandle>
    with DefaultDownloadManagerImpl
    implements
        DownloadManager,
        DownloadManagerHasPersistence,
        ResourceSource<String, DownloadHandle> {
  PersistentDownloadManager(
    this.db,
    this.downloadDir,
    this.files,
  ) : super((e) => e.data.url) {
    _refresher = Stream<void>.periodic(1.seconds).listen((event) {
      if (inWork != 0) {
        StatisticsGeneralService.addTimeDownload(1.seconds.inMilliseconds);
      }
    });
  }

  @override
  final FilesApi? files;

  @override
  final client = Dio();

  @override
  final String downloadDir;

  @override
  final DownloadFileService db;

  late final StreamSubscription<void> _refresher;

  @override
  SourceStorage<String, DownloadHandle> get backingStorage => this;

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  bool get hasNext => false;

  @override
  Future<int> next() => Future.value(count);

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  void restoreFile(DownloadFileData f) {
    map_[f.url] = DownloadHandle(
      data: DownloadEntry.d(
        name: f.name,
        url: f.url,
        thumbUrl: f.thumbUrl,
        site: f.site,
        status: f.status,
        thenMoveTo: null,
      ),
      token: CancelToken(),
    );
  }

  @override
  void add(DownloadHandle e, [bool silent = false]) =>
      throw "should not be called";

  @override
  void addAll(Iterable<DownloadHandle> l, [bool silent = false]) =>
      l.isEmpty ? super.addAll([], silent) : throw "should not be called";

  @override
  void destroy() {
    super.destroy();
    progress.close();
    _refresher.cancel();

    client.close();
  }

  @override
  Future<String> ensureDownloadDirExists({
    required String dir,
    required String site,
  }) async {
    final downloadtd = io.Directory(path.joinAll([dir, "downloads"]));

    final dirpath = path.joinAll([downloadtd.path, site]);
    await downloadtd.create();

    await io.Directory(dirpath).create();

    return dirpath;
  }
}
