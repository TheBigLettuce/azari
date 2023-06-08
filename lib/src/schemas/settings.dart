// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  int picturesPerRow;
  bool listViewBooru;

  String path;
  @enumerated
  Booru selectedBooru;
  @enumerated
  DisplayQuality quality;
  bool safeMode;

  Settings(
      {required this.path,
      required this.selectedBooru,
      required this.quality,
      required this.listViewBooru,
      required this.picturesPerRow,
      required this.safeMode});
  Settings copy(
      {String? path,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? listViewBooru,
      int? picturesPerRow,
      bool? safeMode}) {
    return Settings(
        path: path ?? this.path,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        listViewBooru: listViewBooru ?? this.listViewBooru,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow,
        safeMode: safeMode ?? this.safeMode);
  }

  Settings.empty()
      : path = "",
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        picturesPerRow = (Platform.isAndroid || Platform.isIOS) ? 2 : 6,
        listViewBooru = false,
        safeMode = false;
}

const _kDanbooruPrefix = "d";
const _kGelbooruPrefix = "g";

enum Booru {
  gelbooru(string: "Gelbooru", prefix: _kGelbooruPrefix),
  danbooru(string: "Danbooru", prefix: _kDanbooruPrefix);

  final String string;
  final String prefix;

  const Booru({required this.string, required this.prefix});
}

Booru? chooseBooruPrefix(String prefix) => switch (prefix) {
      _kGelbooruPrefix => Booru.gelbooru,
      _kDanbooruPrefix => Booru.danbooru,
      String() => null,
    };

enum DisplayQuality {
  original("Original"),
  sample("Sample");

  final String string;

  const DisplayQuality(this.string);
}
