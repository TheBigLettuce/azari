// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class PlatformApi implements ServiceMarker {
  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<PlatformApi>();

  AppApi get app;

  WindowApi? get window;
  NotificationApi? get notifications;
  NetworkStatusApi? get network;
  GalleryApi? get gallery;
  ThumbsApi? get thumbs;
  FilesApi? get files;
  // StorageApi get storage;
}

abstract class StorageApi {
  CategoryApi get category;
  GalleryApi? get gallery;

  Future<StorageData> loadData();
}

abstract class CategoryApi {
  Future<void> nuke(StorageCategories c);
  Future<void> optimize(StorageCategories c);

  Future<void> move(InternalStoragePath path, StorageCategories to);
  Future<void> copy(InternalStoragePath path, StorageCategories to);
  // Future<void> rename(InternalStoragePath from, InternalStoragePath to);
  Future<void> remove(InternalStoragePath path);
}

abstract class InternalStoragePath {}

abstract class ExternalStoragePath {}

abstract class StorageData {
  StorageCategories get categories;
  Map<StorageCategories, int> get sizes;

  List<StorageUnit> describeCategory(StorageCategories c);
}

abstract class StorageUnit {
  String get displayName;
  InternalStoragePath get path;
}

enum StorageCategories {
  unknown,
  cache,
  thumbnails,
  db;
}

mixin class AppApi {
  const AppApi();

  List<PermissionController> get requiredPermissions =>
      PlatformApi._instance?.app.requiredPermissions ?? const [];

  Color get accentColor =>
      PlatformApi._instance?.app.accentColor ?? Colors.blue;

  bool get canAuthBiometric =>
      PlatformApi._instance?.app.canAuthBiometric ?? false;
  String get version => PlatformApi._instance?.app.version ?? "";

  Stream<platform.NotificationRouteEvent> get notificationEvents =>
      PlatformApi._instance?.app.notificationEvents ?? const Stream.empty();

  Future<void> shareMedia(String originalUri, {bool url = false}) =>
      PlatformApi._instance?.app.shareMedia(originalUri, url: url) ??
      Future.value();
  Future<void> setWallpaper(int id) =>
      PlatformApi._instance?.app.setWallpaper(id) ?? Future.value();

  void close([Object? returnValue]) {
    PlatformApi._instance?.app.close(returnValue);
  }
}

abstract interface class PermissionController {
  Object get token;
  Future<bool> get granted;
  Future<bool> get enabled;

  (String, IconData) translatedNameIcon(AppLocalizations l10n);

  Future<bool> request();
}

mixin class WindowApi {
  const WindowApi();

  static bool get available => PlatformApi._instance?.window != null;

  Future<void> setFullscreen(bool f) =>
      PlatformApi._instance?.window?.setFullscreen(f) ?? Future.value();

  Future<void> setWakelock(bool lockWake) =>
      PlatformApi._instance?.window?.setWakelock(lockWake) ?? Future.value();

  void setTitle(String n) {
    PlatformApi._instance?.window?.setTitle(n);
  }

  void setProtected(bool enabled) {
    PlatformApi._instance?.window?.setProtected(enabled);
  }
}

mixin class NotificationApi {
  const NotificationApi();

  Future<NotificationHandle?> show({
    required NotificationChannelId id,
    required String title,
    required platform.NotificationChannel channel,
    required platform.NotificationGroup group,
    String? body,
    String? payload,
  }) =>
      PlatformApi._instance?.notifications?.show(
        id: id,
        title: title,
        channel: channel,
        group: group,
      ) ??
      Future.value();
}

abstract class NotificationChannels {
  const factory NotificationChannels() = $NotificationChannels;

  NotificationChannelId get savingTags;
  NotificationChannelId get savingThumb;
  NotificationChannelId get redownloadFiles;

  NotificationChannelId downloadId();
}

abstract class NotificationChannelId {
  const NotificationChannelId();
}

abstract class NotificationHandle {
  void setTotal(int t);
  void update(int progress, [String? str]);
  void done();
  void error(String s);
}

mixin class NetworkStatusApi {
  const NetworkStatusApi();

  bool get hasInternet => PlatformApi._instance?.network?.hasInternet ?? true;
  Stream<bool> get events =>
      PlatformApi._instance?.network?.events ?? const Stream<bool>.empty();
}

mixin NetworkStatusWatcher<W extends StatefulWidget> on State<W> {
  late final StreamSubscription<bool> _networkEvents;

  @override
  void initState() {
    super.initState();

    _networkEvents = const NetworkStatusApi().events.listen((e) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _networkEvents.cancel();
    super.dispose();
  }
}

mixin class GalleryApi {
  const GalleryApi();

  static bool get available => PlatformApi._instance?.gallery != null;
  static GalleryApi? safe() => PlatformApi._instance?.gallery;

  Future<int> get version => (PlatformApi._instance?.gallery?.version)!;

  Search get search => (PlatformApi._instance?.gallery?.search)!;
  Events get events => (PlatformApi._instance?.gallery?.events)!;

  void notify(String? target) {
    PlatformApi._instance?.gallery!.notify(target);
  }
}

abstract class Search {
  Future<List<File>> filesByName(String name, int limit);
  Future<List<File>> filesById(List<int> ids);
}

abstract class Events {
  Stream<void>? get tapDown;
  Stream<platform.GalleryPageChangeEvent>? get pageChange;
  Stream<String?>? get notify;
}

mixin class ThumbsApi {
  const ThumbsApi();

  static bool get available => PlatformApi._instance?.thumbs != null;
  static ThumbsApi? safe() => PlatformApi._instance?.thumbs;

  Future<int> size([bool fromPinned = false]) =>
      PlatformApi._instance?.thumbs?.size(fromPinned) ?? Future.value(0);

  Future<ThumbId?> get(int id) =>
      PlatformApi._instance?.thumbs?.get(id) ?? Future.value();

  void clear([bool fromPinned = false]) =>
      PlatformApi._instance?.thumbs?.clear(fromPinned);

  void removeAll(List<int> id, [bool fromPinned = false]) =>
      PlatformApi._instance?.thumbs?.removeAll(id, fromPinned);

  Future<ThumbId?> saveFromNetwork(String url, int id) =>
      PlatformApi._instance?.thumbs?.saveFromNetwork(url, id) ?? Future.value();
}

mixin class FilesApi {
  const FilesApi();

  static bool get available => PlatformApi._instance?.files != null;
  static FilesApi? safe() => PlatformApi._instance?.files;

  Future<void> rename(String uri, String newName, [bool notify = true]) =>
      PlatformApi._instance?.files?.rename(uri, newName, notify) ??
      Future.value();

  Future<bool> exists(String filePath) =>
      PlatformApi._instance?.files?.exists(filePath) ?? Future.value(false);

  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) =>
      PlatformApi._instance?.files?.moveSingle(
        source: source,
        rootDir: rootDir,
        targetDir: targetDir,
      ) ??
      Future.value();

  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) =>
      PlatformApi._instance?.files?.copyMoveInternal(
        relativePath: relativePath,
        volume: volume,
        dirName: dirName,
        internalPaths: internalPaths,
      ) ??
      Future.value();

  /// if newDir is is set, [choosen] should be uri str on android
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) =>
      PlatformApi._instance?.files?.copyMove(
        chosen,
        chosenVolumeName,
        selected,
        move: move,
        newDir: newDir,
      ) ??
      Future.value();

  void deleteAll(List<File> selected) =>
      PlatformApi._instance?.files?.deleteAll(selected);

  Future<({String formattedPath, String uri})?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  }) =>
      PlatformApi._instance?.files
          ?.chooseDirectory(l10n, temporary: temporary) ??
      Future.value();
}

extension DrainCursorsExt on String {
  Future<List<platform.DirectoryFile>> drainFiles(
    platform.FilesCursor cursorApi,
  ) async {
    final ret = <platform.DirectoryFile>[];

    try {
      while (true) {
        final e = await cursorApi.advance(this);
        if (e.isEmpty) {
          break;
        }

        ret.addAll(e);
      }
    } catch (e, trace) {
      Logger.root.severe(".drainFiles", e, trace);
    } finally {
      await cursorApi.destroy(this);
    }

    return ret;
  }
}

extension FileToDirectoryFileExt on File {
  platform.DirectoryFile toDirectoryFile() => platform.DirectoryFile(
        id: id,
        bucketId: bucketId,
        bucketName: name,
        name: name,
        originalUri: originalUri,
        lastModified: lastModified,
        height: height,
        width: width,
        size: size,
        isVideo: isVideo,
        isGif: isGif,
      );
}
