// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/anime/saved_anime_characters.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'anime_entry.dart';

abstract class AnimeAPI {
  Future<AnimeEntry?> info(int id);
  Future<List<AnimeCharacter>> characters(AnimeEntry entry);
  Future<List<AnimeEntry>> search(String title, int page, [int? genreId]);
  Future<Map<int, AnimeGenre>> genres();
  Future<List<AnimeEntry>> top(int page);
  Future<List<AnimeNewsEntry>> news(int page);

  bool get charactersIsSync;
}

class AnimeNewsEntry {}

enum AnimeMetadata {
  jikan;
}
