// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:convert";
import "dart:io";

import "package:azari/src/platform/platform_api.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:path/path.dart" as path;
import "package:permission_handler/permission_handler.dart";

PlatformApi getApi() => Platform.isAndroid
    ? const _AndroidImpl()
    : Platform.isLinux
        ? const _LinuxImpl()
        : const PlatformApi.dummy();

class _LinuxImpl implements PlatformApi {
  const _LinuxImpl();

  static const _channel = MethodChannel("com.github.thebiglettuce.azari");

  @override
  WindowApi get window => const WindowApi.dummy();

  @override
  bool get authSupported => false;

  // @override
  // Future<void> setTitle(String windowTitle) {
  //   return _channel.invokeMethod("set_title", windowTitle);
  // }

  @override
  Future<Color> get accentColor async {
    try {
      return (await DynamicColorPlugin.getAccentColor())!;
    } catch (_) {
      return Colors.limeAccent;
    }
  }

  @override
  Future<void> setFullscreen(bool f) {
    if (f) {
      return _channel.invokeMethod("fullscreen");
    } else {
      _channel.invokeMethod("default_title");
      return _channel.invokeMethod("fullscreen_untoggle");
    }
  }

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  Future<void> setWallpaper(int id) => Future.value();

  @override
  Future<String> get version async {
    try {
      final exePath = await File("/proc/self/exe").resolveSymbolicLinks();
      final appPath = path.dirname(exePath);
      final assetPath = path.join(appPath, "data", "flutter_assets");
      final versionPath = path.join(assetPath, "version.json");
      // ignore: avoid_dynamic_calls
      return jsonDecode(await File(versionPath).readAsString())["version"]
              as String? ??
          "";
    } catch (_) {
      return "";
    }
  }

  @override
  List<PermissionController> get requiredPermissions => const [];

  @override
  Future<void> setWakelock(bool lockWake) {
    return Future.value();
  }

  @override
  void closeApp([Object? returnValue]) {}
}

class _AndroidImpl implements PlatformApi {
  const _AndroidImpl();

  static const appContext =
      MethodChannel("com.github.thebiglettuce.azari.app_context");

  static const activityContext =
      MethodChannel("com.github.thebiglettuce.azari.activity_context");

  @override
  bool get authSupported => true;

  @override
  WindowApi get window => const _AndroidWindowApi();

  @override
  Future<Color> get accentColor async {
    final int c = (await appContext.invokeMethod("accentColor")) as int;
    return Color(c);
  }

  @override
  List<PermissionController> get requiredPermissions => const [
        _PhotosVideosPermission(),
        _ManageMediaPermission(),
        _NotificationPermission(),
        _MediaLocationPermission(),
        _StoragePermission(),
      ];

  @override
  Future<String> get version =>
      activityContext.invokeMethod("version").then((v) => v as String);

  @override
  Future<void> setFullscreen(bool f) =>
      activityContext.invokeMethod("setFullscreen", f);

  Future<void> closeActivity() => activityContext.invokeMethod("closeActivity");

  Future<List<String>> getQuickViewUris() {
    return activityContext
        .invokeListMethod<String>("getQuickViewUris")
        .then((e) => e!);
  }

  void returnUri(String originalUri) {
    activityContext.invokeMethod("returnUri", originalUri);
  }

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) {
    activityContext
        .invokeMethod("shareMedia", {"uri": originalUri, "isUrl": url});

    return Future.value();
  }

  Future<bool> moveInternal(String internalAppDir, List<String> uris) {
    return activityContext.invokeMethod(
      "moveInternal",
      {"dir": internalAppDir, "uris": uris},
    ).then((value) => (value as bool?) ?? false);
  }

  Future<bool> currentNetworkStatus() {
    return appContext
        .invokeMethod("currentNetworkStatus")
        .then((value) => value as bool);
  }

  @override
  Future<void> setWallpaper(int id) {
    return activityContext.invokeMethod("setWallpaper", id);
  }

  @override
  Future<void> setWakelock(bool lockWake) {
    return activityContext.invokeMethod("setWakelock", lockWake);
  }

  @override
  void closeApp([Object? returnValue]) {
    if (returnValue == null) {
      closeActivity();
    } else {
      returnUri(returnValue as String);
    }
  }
}

class _AndroidWindowApi implements WindowApi {
  const _AndroidWindowApi();

  @override
  void setProtected(bool enabled) {
    _AndroidImpl.activityContext.invokeMethod("hideRecents", enabled);
  }

  @override
  void setTitle(String n) {}
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
  Future<bool> get enabled => _AndroidImpl.appContext
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
  Future<bool> get granted => _AndroidImpl.appContext
      .invokeMethod("manageMediaStatus")
      .then((value) => value as bool);

  @override
  Future<bool> get enabled => _AndroidImpl.appContext
      .invokeMethod("manageMediaSupported")
      .then((value) => value as bool);

  @override
  Future<bool> request() => _AndroidImpl.activityContext
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
  Future<bool> get enabled => _AndroidImpl.appContext
      .invokeMethod("requiresStoragePermission")
      .then((value) => value as bool);

  @override
  Future<bool> request() => Permission.storage.request().isGranted;

  @override
  (String, IconData) translatedNameIcon(AppLocalizations l10n) {
    return ("Storage", Icons.folder_rounded);
  }
}
