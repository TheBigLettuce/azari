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
  String name;
  List<int?> thumbnail;

  int lastModified;

  Directory(
      {required this.name,
      required this.thumbnail,
      required this.lastModified});
}

class DirectoryFile {
  String directoryId;

  String name;
  List<int?> thumbnail;

  int lastModified;

  DirectoryFile(
      {required this.directoryId,
      required this.lastModified,
      required this.name,
      required this.thumbnail});
}

@FlutterApi()
abstract class GalleryApi {
  int start();
  void updateDirectory(String id, Directory d);
  bool compareTime(String id, int time);
  void updatePicture(String id, DirectoryFile f);
  void finish(int time);
}
