// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io" as io;

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/impl/io/android/gallery/android_gallery.dart";
import "package:azari/src/services/impl/io/android/notifications/notifications.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:permission_handler/permission_handler.dart";
import "package:stream_transform/stream_transform.dart";

_PlatformGalleryImpl initalizeAndroidGallery() {
  final ret = _PlatformGalleryImpl();
  platform.PlatformGalleryApi.setUp(ret);

  return ret;
}

class AndroidPlatformImpl implements PlatformApi {
  AndroidPlatformImpl({
    required Color accentColor,
    required String version,
    required bool canOpenBy,
    required _PlatformGalleryImpl galleryImpl,
    required Stream<platform.NotificationRouteEvent> notificationEvents,
  }) : app = _AppApi(accentColor, version, notificationEvents, canOpenBy),
       network = _NetworkStatusApi(galleryImpl),
       gallery = _GalleryApi(galleryImpl);

  static const appContext = MethodChannel(
    "com.github.thebiglettuce.azari.app_context",
  );

  static const activityContext = MethodChannel(
    "com.github.thebiglettuce.azari.activity_context",
  );

  @override
  WindowApi get window => const _WindowApi();

  @override
  FilesApi get files => const _FilesApiImpl();

  @override
  final _GalleryApi gallery;

  @override
  final NetworkStatusApi network;

  @override
  final NotificationApi notifications = NotificationsImpl();

  @override
  final AppApi app;

  @override
  ThumbsApi? get thumbs => const _ThumbsApiImpl();

  Future<List<String>> getQuickViewUris() {
    return activityContext
        .invokeListMethod<String>("getQuickViewUris")
        .then((e) => e!);
  }

  Future<bool> moveInternal(String internalAppDir, List<String> uris) {
    return activityContext
        .invokeMethod("moveInternal", {"dir": internalAppDir, "uris": uris})
        .then((value) => (value as bool?) ?? false);
  }

  Future<bool> currentNetworkStatus() {
    return appContext
        .invokeMethod("currentNetworkStatus")
        .then((value) => value as bool);
  }
}

enum _AndroidPermissionToken {
  mediaLocation,
  photosVideos,
  manageMedia,
  notification,
  storage,
}

class _MediaLocationPermission implements PermissionController {
  const _MediaLocationPermission();

  @override
  Object get token => _AndroidPermissionToken.mediaLocation;

  @override
  Future<bool> get granted => Permission.accessMediaLocation.isGranted;

  @override
  Future<bool> get enabled => SynchronousFuture(true);

  @override
  Future<bool> request() =>
      Permission.accessMediaLocation.request().then((e) => e.isGranted);

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return (l10n.permissionsMediaLocation, Icons.folder_copy);
  }
}

class _PhotosVideosPermission implements PermissionController {
  const _PhotosVideosPermission();

  @override
  Object get token => _AndroidPermissionToken.photosVideos;

  @override
  Future<bool> get granted async {
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;

    return photos & videos;
  }

  @override
  Future<bool> get enabled => AndroidPlatformImpl.appContext
      .invokeMethod("requiresStoragePermission")
      .then((value) => !(value as bool));

  @override
  Future<bool> request() async {
    final resultPhotos = await Permission.photos.request();
    final resultVideos = await Permission.videos.request();

    return resultVideos.isGranted && resultPhotos.isGranted;
  }

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return (l10n.permissionsPhotosVideos, Icons.photo);
  }
}

class _ManageMediaPermission implements PermissionController {
  const _ManageMediaPermission();

  @override
  Object get token => _AndroidPermissionToken.manageMedia;

  @override
  Future<bool> get granted => AndroidPlatformImpl.appContext
      .invokeMethod("manageMediaStatus")
      .then((value) => value as bool);

  @override
  Future<bool> get enabled => AndroidPlatformImpl.appContext
      .invokeMethod("manageMediaSupported")
      .then((value) => value as bool);

  @override
  Future<bool> request() => AndroidPlatformImpl.activityContext
      .invokeMethod("requestManageMedia")
      .then((value) => value as bool);

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return (l10n.permissionsManageMedia, Icons.perm_media);
  }
}

class _NotificationPermission implements PermissionController {
  const _NotificationPermission();

  @override
  Object get token => _AndroidPermissionToken.notification;

  @override
  Future<bool> get granted => Permission.notification.isGranted;

  @override
  Future<bool> get enabled => SynchronousFuture(true);

  @override
  Future<bool> request() => Permission.notification.request().isGranted;

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return (l10n.permissionsNotifications, Icons.notifications_rounded);
  }
}

class _StoragePermission implements PermissionController {
  const _StoragePermission();

  @override
  Object get token => _AndroidPermissionToken.storage;

  @override
  Future<bool> get granted => Permission.storage.isGranted;

  @override
  Future<bool> get enabled => AndroidPlatformImpl.appContext
      .invokeMethod("requiresStoragePermission")
      .then((value) => value as bool);

  @override
  Future<bool> request() => Permission.storage.request().isGranted;

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return ("Storage", Icons.folder_rounded);
  }
}

class _WindowApi implements WindowApi {
  const _WindowApi();

  @override
  Future<void> setWakelock(bool lockWake) {
    return AndroidPlatformImpl.activityContext.invokeMethod(
      "setWakelock",
      lockWake,
    );
  }

  @override
  Future<void> setFullscreen(bool f) =>
      AndroidPlatformImpl.activityContext.invokeMethod("setFullscreen", f);

  @override
  void setProtected(bool enabled) {
    AndroidPlatformImpl.activityContext.invokeMethod("hideRecents", enabled);
  }

  @override
  void setTitle(String n) {}
}

class _FilesApiImpl implements FilesApi {
  const _FilesApiImpl();

  @override
  Future<({String path, String formattedPath})?> chooseDirectory(
    AppLocalizations _, {
    bool temporary = false,
  }) => AndroidPlatformImpl.activityContext
      .invokeMethod("chooseDirectory", temporary)
      .then(
        (value) => (
          formattedPath: (value as Map)["pathDisplay"] as String,
          path: value["path"] as String,
        ),
      );

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) {
    return AndroidPlatformImpl.appContext.invokeMethod("move", {
      "source": source,
      "rootUri": rootDir,
      "dir": targetDir,
    });
  }

  @override
  void deleteAll(List<File> selected) {
    AndroidPlatformImpl.activityContext.invokeMethod(
      "deleteFiles",
      selected.map((e) => e.originalUri).toList(),
    );
  }

  @override
  Future<bool> exists(String filePath) => io.File(filePath).exists();

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) {
    return AndroidPlatformImpl.activityContext.invokeMethod("copyMoveFiles", {
      "dest": chosen,
      "images": selected
          .where((element) => !element.isVideo)
          .map((e) => e.id)
          .toList(),
      "videos": selected
          .where((element) => element.isVideo)
          .map((e) => e.id)
          .toList(),
      "move": move,
      "volumeName": chosenVolumeName,
      "newDir": newDir,
    });
  }

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) {
    if (newName.isEmpty) {
      return Future.value();
    }

    AndroidPlatformImpl.activityContext.invokeMethod("rename", {
      "uri": uri,
      "newName": newName,
      "notify": notify,
    });

    return Future.value();
  }

  @override
  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) {
    final List<String> images = [];
    final List<String> videos = [];

    for (final e in internalPaths) {
      final type = PostContentType.fromUrl(e);
      if (type == PostContentType.gif || type == PostContentType.image) {
        images.add(e);
      } else if (type == PostContentType.video) {
        videos.add(e);
      }
    }

    return AndroidPlatformImpl.activityContext
        .invokeMethod("copyMoveInternal", {
          "dirName": dirName,
          "relativePath": relativePath,
          "images": images,
          "videos": videos,
          "volume": volume,
        });
  }
}

class _ThumbsApiImpl implements ThumbsApi {
  const _ThumbsApiImpl();

  @override
  Future<int> size([bool fromPinned = false]) {
    return AndroidPlatformImpl.appContext
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value as int);
  }

  @override
  Future<ThumbId> get(int id) {
    return AndroidPlatformImpl.appContext
        .invokeMethod("getCachedThumb", id)
        .then((value) {
          return ThumbId(
            id: id,
            path: (value as Map)["path"] as String,
            differenceHash: value["hash"] as int,
          );
        });
  }

  @override
  void clear([bool fromPinned = false]) => AndroidPlatformImpl.appContext
      .invokeMethod("clearCachedThumbs", fromPinned);

  @override
  void removeAll(List<int> id, [bool fromPinned = false]) {
    AndroidPlatformImpl.appContext.invokeMethod("deleteCachedThumbs", {
      "ids": id,
      "fromPinned": fromPinned,
    });
  }

  @override
  Future<ThumbId> saveFromNetwork(String url, int id) {
    return AndroidPlatformImpl.appContext
        .invokeMethod("saveThumbNetwork", {"url": url, "id": id})
        .then(
          (value) => ThumbId(
            id: id,
            path: (value as Map)["path"] as String,
            differenceHash: value["hash"] as int,
          ),
        );
  }
}

class _AppApi implements AppApi {
  const _AppApi(
    this.accentColor,
    this.version,
    this.notificationEvents,
    this.canOpenBy,
  );

  @override
  final Stream<platform.NotificationRouteEvent> notificationEvents;

  @override
  bool get canAuthBiometric => true;

  @override
  List<PermissionController> get requiredPermissions => const [
    _PhotosVideosPermission(),
    _ManageMediaPermission(),
    _NotificationPermission(),
    _MediaLocationPermission(),
    _StoragePermission(),
  ];

  @override
  final Color accentColor;

  @override
  final String version;

  @override
  final bool canOpenBy;

  @override
  Future<void> setWallpaper(int id) {
    return AndroidPlatformImpl.activityContext.invokeMethod("setWallpaper", id);
  }

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) {
    AndroidPlatformImpl.activityContext.invokeMethod("shareMedia", {
      "uri": originalUri,
      "isUrl": url,
    });

    return Future.value();
  }

  @override
  void close([Object? returnValue]) {
    if (returnValue == null) {
      closeActivity();
    } else {
      returnUri(returnValue as String);
    }
  }

  Future<void> closeActivity() =>
      AndroidPlatformImpl.activityContext.invokeMethod("closeActivity");

  void returnUri(String originalUri) {
    AndroidPlatformImpl.activityContext.invokeMethod("returnUri", originalUri);
  }

  @override
  Future<void> openSettingsOpenBy() =>
      AndroidPlatformImpl.activityContext.invokeMethod("openSettingsOpenBy");
}

class _Events implements Events {
  const _Events(this.galleryImpl);

  final _PlatformGalleryImpl galleryImpl;

  @override
  Stream<platform.GalleryPageChangeEvent>? get pageChange =>
      galleryImpl._pageChange.stream;

  @override
  Stream<void>? get tapDown => galleryImpl._tapDown.stream;

  @override
  Stream<String?>? get notify => galleryImpl._events.stream;

  @override
  Stream<String>? get webLinks => galleryImpl._webLinkEventsMain.stream;
}

class _GalleryApi implements GalleryApi {
  _GalleryApi(this.galleryImpl) : events = _Events(galleryImpl);

  final _PlatformGalleryImpl galleryImpl;

  @override
  Future<int> get version => platform.GalleryHostApi().mediaVersion();

  @override
  Search get search => const _Search();

  @override
  final _Events events;

  @override
  void notify(String? target) => galleryImpl.notify(target);
}

class _Search implements Search {
  const _Search();

  @override
  Future<List<File>> filesById(List<int> ids) async {
    final cursorApi = platform.FilesCursor();

    final cursor = await cursorApi.acquireIds(ids);

    return (await cursor.drainFiles(cursorApi))
        .map(
          (e) => e.toAndroidFile(
            (LocalTagsService.safe()?.get(e.name) ?? []).fold({}, (map, e) {
              map[e] = null;
              return map;
            }),
          ),
        )
        .toList();
  }

  @override
  Future<List<File>> filesByName(String name, int limit) async {
    final cursorApi = platform.FilesCursor();

    final cursor = await cursorApi.acquireFilter(
      name: name,
      sortingMode: platform.FilesSortingMode.none,
      limit: limit,
    );

    return (await cursor.drainFiles(cursorApi))
        .map(
          (e) => e.toAndroidFile(
            (LocalTagsService.safe()?.get(e.name) ?? []).fold({}, (map, e) {
              map[e] = null;
              return map;
            }),
          ),
        )
        .toList();
  }
}

class _NetworkStatusApi implements NetworkStatusApi {
  _NetworkStatusApi(_PlatformGalleryImpl galleryImpl) {
    _events = galleryImpl._networkStatus.stream.listen((e) {
      hasInternet = e;
      _controller.add(hasInternet);
    });
  }

  late final StreamSubscription<bool> _events;
  final StreamController<bool> _controller = StreamController.broadcast();

  @override
  Stream<bool> get events => _controller.stream;

  @override
  bool hasInternet = true;

  void dispose() {
    _events.cancel();
  }
}

class _PlatformGalleryImpl implements platform.PlatformGalleryApi {
  _PlatformGalleryImpl() {
    _webLinkEventsMain = StreamController<String>.broadcast();
    _webLinkEventsBuffer = StreamController<String>.broadcast();
    _webLinkEventsBuffered = _webLinkEventsBuffer.stream.buffer(
      eventsTarget.stream,
    );
    _webLinkEventsBuffered.listen((e) {
      for (final link in e) {
        _webLinkEventsMain.add(link);
      }
    });
  }

  final _events = StreamController<String?>.broadcast();
  late final StreamController<String> _webLinkEventsMain;
  late final StreamController<String> _webLinkEventsBuffer;

  late final Stream<List<String>> _webLinkEventsBuffered;

  final _networkStatus = StreamController<bool>.broadcast();

  final StreamController<void> _tapDown = StreamController.broadcast();

  final StreamController<platform.GalleryPageChangeEvent> _pageChange =
      StreamController.broadcast();

  @override
  void notify(String? target) => _events.add(target);

  @override
  void notifyNetworkStatus(bool hasInternet) => _networkStatus.add(hasInternet);

  @override
  void galleryTapDownEvent() => _tapDown.add(null);
  @override
  void galleryPageChangeEvent(platform.GalleryPageChangeEvent e) =>
      _pageChange.add(e);

  @override
  void webLinkEvent(String link) {
    _webLinkEventsMain.add(link);
    _webLinkEventsBuffer.add(link);
  }
}
