// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  int picturesPerRow;
  bool listViewBooru;

  String path;
  bool booruDefault;
  bool enableGallery;
  @enumerated
  Booru selectedBooru;
  @enumerated
  DisplayQuality quality;

  Settings(
      {required this.path,
      required this.booruDefault,
      required this.selectedBooru,
      required this.quality,
      required this.enableGallery,
      required this.listViewBooru,
      required this.picturesPerRow});
  Settings copy(
      {String? path,
      bool? enableGallery,
      bool? booruDefault,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? listViewBooru,
      int? picturesPerRow}) {
    return Settings(
        path: path ?? this.path,
        enableGallery: enableGallery ?? this.enableGallery,
        booruDefault: booruDefault ?? this.booruDefault,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        listViewBooru: listViewBooru ?? this.listViewBooru,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow);
  }

  Settings.empty()
      : path = "",
        booruDefault = true,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        enableGallery = false,
        picturesPerRow = 2,
        listViewBooru = false;
}

enum Booru {
  gelbooru(string: "Gelbooru"),
  danbooru(string: "Danbooru");

  final String string;

  const Booru({required this.string});
}

enum DisplayQuality {
  original("Original"),
  sample("Sample");

  final String string;

  const DisplayQuality(this.string);
}
