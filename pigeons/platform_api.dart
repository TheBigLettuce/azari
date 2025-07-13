// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:pigeon/pigeon.dart";

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/generated/platform/platform_api.g.dart",
    dartTestOut: "test/platform_api.g.dart",
    kotlinOut:
        "android/app/src/main/kotlin/com/github/thebiglettuce/azari/generated/Generated.kt",
    kotlinOptions: KotlinOptions(
      package: "com.github.thebiglettuce.azari.generated",
    ),
    copyrightHeader: "pigeons/copyright.txt",
  ),
)
class Directory {
  const Directory({
    required this.bucketId,
    required this.thumbFileId,
    required this.relativeLoc,
    required this.name,
    required this.volumeName,
    required this.lastModified,
  });

  final int thumbFileId;
  final String bucketId;
  final String name;
  final String relativeLoc;
  final String volumeName;

  final int lastModified;
}

class DirectoryFile {
  const DirectoryFile({
    required this.id,
    required this.bucketId,
    required this.lastModified,
    required this.originalUri,
    required this.name,
    required this.bucketName,
    required this.size,
    required this.isGif,
    required this.height,
    required this.width,
    required this.isVideo,
  });

  final int id;
  final String bucketId;
  final String bucketName;

  final String name;
  final String originalUri;

  final int lastModified;

  final int height;
  final int width;

  final int size;

  final bool isVideo;
  final bool isGif;
}

class UriFile {
  const UriFile(
    this.uri,
    this.name,
    this.size,
    this.lastModified,
    this.height,
    this.width,
    this.isVideo,
    this.isGif,
  );

  final String uri;
  final String name;

  final int lastModified;

  final int height;
  final int width;

  final bool isVideo;
  final bool isGif;

  final int size;
}

@HostApi()
abstract class GalleryHostApi {
  @async
  int mediaVersion();

  @async
  List<UriFile> getUriPicturesDirectly(List<String> uris);
}

@HostApi()
abstract class DirectoriesCursor {
  String acquire();

  @async
  Map<String, Directory> advance(String token);

  void destroy(String token);
}

enum FilesCursorType { trashed, normal }

enum FilesSortingMode { none, size }

@HostApi()
abstract class FilesCursor {
  String acquire({
    required List<String> directories,
    required FilesCursorType type,
    required FilesSortingMode sortingMode,
    required int limit,
  });

  String acquireFilter({
    required String name,
    required FilesSortingMode sortingMode,
    required int limit,
  });

  String acquireIds(List<int> ids);

  @async
  List<DirectoryFile> advance(String token);

  void destroy(String token);
}

@FlutterApi()
abstract class PlatformGalleryApi {
  void notifyNetworkStatus(bool hasInternet);

  void notify(String? target);
  void galleryTapDownEvent();

  void galleryPageChangeEvent(GalleryPageChangeEvent e);

  void webLinkEvent(String link);
}

@FlutterApi()
abstract class GalleryVideoEvents {
  void playbackStateEvent(VideoPlaybackState state);
  void volumeEvent(double volume);
  void durationEvent(int duration);
  void progressEvent(int progress);
  void loopingEvent(bool looping);
}

enum VideoPlaybackState { stopped, playing, buffering }

@FlutterApi()
abstract class FlutterGalleryData {
  @async
  GalleryMetadata metadata();

  @async
  double? initialVolume();

  @async
  DirectoryFile atIndex(int index);

  void setCurrentIndex(int index);
}

@HostApi()
abstract class PlatformGalleryEvents {
  void metadataChanged();
  void seekToIndex(int i);

  void volumeButtonPressed(double? volume);
  void playButtonPressed();
  void loopingButtonPressed();
  void durationChanged(int d);
}

class GalleryMetadata {
  const GalleryMetadata({required this.count});

  final int count;
}

class CopyOp {
  const CopyOp({required this.from, required this.to});

  final String from;
  final String to;
}

class Notification {
  const Notification({
    required this.maxProgress,
    required this.currentProgress,
    required this.indeterminate,
    required this.payload,
    required this.id,
    required this.title,
    required this.body,
    required this.group,
  });

  final int id;
  final String title;
  final String? body;

  final NotificationGroup group;

  final int maxProgress;
  final int currentProgress;
  final bool indeterminate;

  final String? payload;
}

@HostApi()
abstract class NotificationsApi {
  @async
  void post(NotificationChannel channel, Notification notif);

  @async
  void cancel(int id);
}

@FlutterApi()
abstract class OnNotificationPressed {
  void onPressed(NotificationRouteEvent r);
}

enum NotificationGroup { downloader, misc }

enum NotificationChannel { downloader, misc }

enum NotificationRouteEvent { downloads }

enum GalleryPageChangeEvent { left, right }
