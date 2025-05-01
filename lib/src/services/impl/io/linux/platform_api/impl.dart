// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/services.dart";

class LinuxPlatformImpl implements PlatformApi {
  LinuxPlatformImpl({
    required Color accentColor,
    required String version,
  }) : app = _AppApi(accentColor, version);

  static const _channel = MethodChannel("com.github.thebiglettuce.azari");

  @override
  final AppApi app;

  @override
  WindowApi get window => const _WindowApi();

  @override
  FilesApi get files => const IoFilesManagement();

  @override
  GalleryApi? get gallery => null;

  @override
  NetworkStatusApi? get network => null;

  @override
  NotificationApi? get notifications => null;

  @override
  ThumbsApi? get thumbs => null;

  @override
  StorageApi get storage => throw UnimplementedError();
}

class _WindowApi implements WindowApi {
  const _WindowApi();

  @override
  Future<void> setFullscreen(bool f) {
    if (f) {
      return LinuxPlatformImpl._channel.invokeMethod("fullscreen");
    } else {
      LinuxPlatformImpl._channel.invokeMethod("default_title");
      return LinuxPlatformImpl._channel.invokeMethod("fullscreen_untoggle");
    }
  }

  @override
  void setProtected(bool enabled) {
    // TODO: implement setProtected
  }

  @override
  void setTitle(String n) {
    // TODO: implement setTitle
  }

  @override
  Future<void> setWakelock(bool lockWake) => Future.value();
}

class _AppApi implements AppApi {
  const _AppApi(this.accentColor, this.version);

  @override
  final Color accentColor;

  @override
  final String version;

  @override
  bool get canAuthBiometric => false;

  @override
  List<PermissionController> get requiredPermissions => const [];

  @override
  Future<void> setWallpaper(int id) => Future.value();

  @override
  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      Future.value();

  @override
  void close([Object? returnValue]) {}

  @override
  Stream<NotificationRouteEvent> get notificationEvents => const Stream.empty();
}
