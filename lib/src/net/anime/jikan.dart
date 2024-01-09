// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/foundation.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_characters.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/logging/logging.dart';
import 'package:jikan_api/jikan_api.dart' as api;

class Jikan implements AnimeAPI {
  const Jikan();

  static const _log = LogTarget.anime;

  @override
  bool get charactersIsSync => false;

  @override
  Future<AnimeEntry?> info(int id) async {
    try {
      final response = await api.Jikan(debug: kDebugMode).getAnime(id);

      return _fromJikenAnime(response);
    } catch (e, trace) {
      _log.logDefaultImportant("Jikan API info".errorMessage(e), trace);
      return null;
    }
  }

  @override
  Future<List<AnimeCharacter>> characters(AnimeEntry entry) async {
    final response =
        await api.Jikan(debug: kDebugMode).getAnimeCharacters(entry.id);

    return response.map((e) => _fromJikanCharacter(e)).toList();
  }

  @override
  Future<List<AnimeEntry>> search(String title, int page) async {
    final response = await api.Jikan(debug: kDebugMode)
        .searchAnime(query: title, page: page + 1);

    return response.map((e) => _fromJikenAnime(e)).toList();
  }

  @override
  Future<List<AnimeEntry>> top(int page) async {
    try {
      final response =
          await api.Jikan(debug: kDebugMode).getTopAnime(page: page + 1);

      return response.map((e) => _fromJikenAnime(e)).toList();
    } catch (e, trace) {
      _log.logDefaultImportant("Jikan API top".errorMessage(e), trace);
      return const [];
    }
  }
}

AnimeCharacter _fromJikanCharacter(api.CharacterMeta e) =>
    AnimeCharacter(imageUrl: e.imageUrl, name: e.name, role: e.role);

List<Relation> _fromMeta(api.BuiltList<api.Meta> l) {
  return l.map((e) => Relation(thumbUrl: e.url, title: e.name)).toList();
}

AnimeEntry _fromJikenAnime(api.Anime e) {
  return AnimeEntry(
    thumbUrl: e.imageUrl,
    title: e.title,
    site: AnimeMetadata.jikan,
    score: e.score ?? 0,
    synopsis: e.synopsis ?? "",
    relations:
        e.relations?.map((e) => _fromMeta(e.entry)).reduce((value, element) {
              value.addAll(element);

              return value;
            }) ??
            const [],
    year: e.year ?? 0,
    siteUrl: e.url,
    isAiring: e.airing,
    titleEnglish: e.titleEnglish ?? "",
    titleJapanese: e.titleJapanese ?? "",
    titleSynonyms: e.titleSynonyms.toList(),
    genres: e.genres.map((e) => e.name).toList() +
        e.explicitGenres.map((e) => e.name).toList() +
        e.demographics.map((e) => e.name).toList() +
        e.studios.map((e) => e.name).toList(),
    trailerUrl: e.trailerUrl ?? "",
    episodes: e.episodes ?? 0,
    background: e.background ?? "",
    id: e.malId,
  );
}
