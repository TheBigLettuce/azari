// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:pigeon/pigeon.dart";

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/plugs/gallery/android/api.g.dart",
    dartTestOut: "test/test_api.g.dart",
    kotlinOut:
        "android/app/src/main/kotlin/lol/bruh19/azari/gallery/Gallery.kt",
    kotlinOptions: KotlinOptions(
      package: "lol.bruh19.azari.gallery",
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
  );

  final String uri;
  final String name;

  final int lastModified;

  final int height;
  final int width;

  final int size;
}

@HostApi()
abstract class GalleryHostApi {
  @async
  List<DirectoryFile> getPicturesDirectly(
    String? dir,
    int limit,
    bool onlyLatest,
  );

  @async
  List<DirectoryFile> getPicturesOnlyDirectly(List<int> ids);

  @async
  List<UriFile> getUriPicturesDirectly(List<String> uris);
}

@FlutterApi()
abstract class GalleryApi {
  bool updateDirectories(Map<String, Directory> d, bool inRefresh, bool empty);
  bool updatePictures(
    List<DirectoryFile?> f,
    String bucketId,
    int startTime,
    bool inRefresh,
    bool empty,
  );

  void notifyNetworkStatus(bool hasInternet);

  void notify(String? target);
}

class CopyOp {
  const CopyOp({required this.from, required this.to});

  final String from;
  final String to;
}
