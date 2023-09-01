// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
      dartOut: "lib/src/gallery/android_api/api.g.dart",
      dartTestOut: "test/test_api.g.dart",
      kotlinOut:
          "android/app/src/main/kotlin/lol/bruh19/azari/gallery/Gallery.kt",
      kotlinOptions: KotlinOptions(
        package: "lol.bruh19.azari.gallery",
      ),
      copyrightHeader: "pigeons/copyright.txt"),
)
class Directory {
  final int thumbFileId;
  final String bucketId;
  final String name;
  final String relativeLoc;
  final String volumeName;

  final int lastModified;

  const Directory(
      {required this.bucketId,
      required this.thumbFileId,
      required this.relativeLoc,
      required this.name,
      required this.volumeName,
      required this.lastModified});
}

class DirectoryFile {
  final int id;
  final String bucketId;

  final String name;
  final String originalUri;

  final int lastModified;

  final int height;
  final int width;

  final int size;

  final bool isVideo;
  final bool isGif;

  const DirectoryFile(
      {required this.id,
      required this.bucketId,
      required this.lastModified,
      required this.originalUri,
      required this.name,
      required this.size,
      required this.isGif,
      required this.height,
      required this.width,
      required this.isVideo});
}

@FlutterApi()
abstract class GalleryApi {
  void updateDirectories(List<Directory> d, bool inRefresh, bool empty);
  void updatePictures(List<DirectoryFile?> f, String bucketId, int startTime,
      bool inRefresh, bool empty);
  void addThumbnails(List<ThumbnailId> thumbs);

  void notify(String? target);

  List<int> thumbsExist(List<int> ids);

  void finish(String newVersion);
}

class ThumbnailId {
  final int id;
  final Uint8List thumb;
  final int differenceHash;

  const ThumbnailId(this.id, this.thumb, this.differenceHash);
}

class CopyOp {
  final String from;
  final String to;

  const CopyOp({required this.from, required this.to});
}
