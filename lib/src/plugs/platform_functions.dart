// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gallery/src/plugs/api_functions/dummy.dart"
    if (dart.library.io) "package:gallery/src/plugs/api_functions/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/api_functions/web.dart";

@immutable
class ThumbId {
  const ThumbId({
    required this.id,
    required this.path,
    required this.differenceHash,
  });

  final int id;
  final String path;
  final int differenceHash;
}

abstract interface class PlatformApi {
  factory PlatformApi.current() => getApi();

  bool get requiresPermissions;

  Future<Color> accentColor();
  Future<void> setFullscreen(bool f);
  Future<void> setTitle(String windowTitle);

  Future<void> shareMedia(String originalUri, {bool url = false});
  Future<void> setWallpaper(int id);

  Future<void> hideRecents(bool hide);
}

class DummyApiFunctions implements PlatformApi {
  const DummyApiFunctions();

  @override
  bool get requiresPermissions => false;

  @override
  Future<Color> accentColor() => Future.value(Colors.indigo);

  @override
  Future<void> setFullscreen(bool f) => Future.value();

  @override
  Future<void> setTitle(String windowTitle) => Future.value();

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  Future<void> setWallpaper(int id) => Future.value();

  @override
  Future<void> hideRecents(bool hide) => Future.value();
}

class LinuxApiFunctions implements PlatformApi {
  const LinuxApiFunctions();

  static const _channel = MethodChannel("lol.bruh19.azari.gallery");

  @override
  bool get requiresPermissions => false;

  @override
  Future<Color> accentColor() async {
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
  Future<void> setTitle(String windowTitle) {
    return _channel.invokeMethod("set_title", windowTitle);
  }

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setWallpaper(int id) {
    throw UnimplementedError();
  }

  @override
  Future<void> hideRecents(bool hide) => Future.value();
}

class AndroidApiFunctions implements PlatformApi {
  const AndroidApiFunctions();

  static const appContext =
      MethodChannel("lol.bruh19.azari.gallery.app_context");

  static const activityContext =
      MethodChannel("lol.bruh19.azari.gallery.activity_context");

  @override
  bool get requiresPermissions => true;

  @override
  Future<void> setFullscreen(bool f) {
    if (f) {
      return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      return SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Future<void> setTitle(String windowTitle) => Future.value();

  Future<void> closeActivity() => activityContext.invokeMethod("closeActivity");

  @override
  Future<void> hideRecents(bool hide) {
    activityContext.invokeMethod("hideRecents", hide);

    return Future.value();
  }

  Future<List<String>> getQuickViewUris() {
    return activityContext
        .invokeListMethod<String>("getQuickViewUris")
        .then((e) => e!);
  }

  Future<bool> requestManageMedia() {
    return activityContext
        .invokeMethod("requestManageMedia")
        .then((value) => value as bool);
  }

  @override
  Future<Color> accentColor() async {
    final int c = (await appContext.invokeMethod("accentColor")) as int;
    return Color(c);
  }

  void returnUri(String originalUri) {
    activityContext.invokeMethod("returnUri", originalUri);
  }

  Future<bool> manageMediaSupported() {
    return appContext
        .invokeMethod("manageMediaSupported")
        .then((value) => value as bool);
  }

  Future<bool> manageMediaStatus() {
    return appContext
        .invokeMethod("manageMediaStatus")
        .then((value) => value as bool);
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

  // Future<bool> moveFromInternal(
  //   String fromInternalFile,
  //   String toDir,
  //   String volume,
  // ) {
  //   return _channel.invokeMethod(
  //     "moveFromInternal",
  //     {"from": fromInternalFile, "to": toDir, "volume": volume},
  //   ).then((value) => (value as bool?) ?? false);
  // }

  Future<int> currentMediastoreVersion() {
    return appContext
        .invokeMethod("currentMediastoreVersion")
        .then((value) => value as int);
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
}
