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
  int id;
  String name;

  int lastModified;

  Directory({required this.id, required this.name, required this.lastModified});
}

class DirectoryFile {
  int id;
  int directoryId;

  String name;
  String originalUri;

  int lastModified;

  DirectoryFile({
    required this.id,
    required this.directoryId,
    required this.lastModified,
    required this.originalUri,
    required this.name,
  });
}

@FlutterApi()
abstract class GalleryApi {
  //String start();
  void updateDirectories(List<Directory> d);
  //bool compareTime(String id, int time);
  void updatePictures(List<DirectoryFile?> f);
  void addThumbnail(int id, List<int?> thumb);
  bool thumbExist(int id);

  void finish(String newVersion);
}
