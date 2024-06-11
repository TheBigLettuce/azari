// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/foundation.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/logging/logging.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:jikan_api/jikan_api.dart" as api;

class Jikan implements AnimeAPI {
  const Jikan();

  static const _log = LogTarget.anime;

  @override
  bool get charactersIsSync => false;

  @override
  AnimeMetadata get site => AnimeMetadata.jikan;

  @override
  Future<AnimeEntryData> info(int id) async {
    try {
      final response = await api.Jikan(debug: kDebugMode).getAnime(id);

      return _fromJikanAnime(response);
    } catch (e, trace) {
      _log.logDefaultImportant("Jikan API info".errorMessage(e), trace);

      rethrow;
    }
  }

  @override
  Future<List<AnimeCharacter>> characters(AnimeEntryData entry) async {
    final response =
        await api.Jikan(debug: kDebugMode).getAnimeCharacters(entry.id);

    return response.map((e) => _fromJikanCharacter(e)).toList();
  }

  @override
  Future<List<AnimeSearchEntry>> search(
    String title,
    int page,
    int? genreId,
    AnimeSafeMode? mode,
  ) async {
    final response = await api.Jikan(debug: kDebugMode).searchAnime(
      query: title,
      page: page + 1,
      genres: [
        if (genreId != null) genreId,

        /// havent found a good way
        if (mode == AnimeSafeMode.ecchi) 9,
      ],
      orderBy: "score",
      sort: "desc",
      rawQuery: mode == AnimeSafeMode.h
          ? "&rating=rx"
          : mode == AnimeSafeMode.safe
              ? "&sfw=true"
              : null,
    );

    return response.map((e) => _fromJikanAnime(e)).toList();
  }

  @override
  Future<List<AnimeEntryData>> top(int page) async {
    try {
      final response =
          await api.Jikan(debug: kDebugMode).getTopAnime(page: page + 1);

      return response.map((e) => _fromJikanAnime(e)).toList();
    } catch (e, trace) {
      _log.logDefaultImportant("Jikan API top".errorMessage(e), trace);
      return const [];
    }
  }

  @override
  Future<Map<int, AnimeGenre>> genres(AnimeSafeMode mode) async {
    final response = await api.Jikan(debug: kDebugMode).getAnimeGenres(
      type: mode == AnimeSafeMode.h ? api.GenreType.explicit_genres : null,
    );
    final map = <int, AnimeGenre>{};

    for (final e in response) {
      map[e.malId] = objFactory.makeAnimeGenre(
        title: e.name,
        id: e.malId,
        unpressable: false,
        explicit: mode == AnimeSafeMode.h,
      );
    }

    return map;
  }

  @override
  Future<List<AnimeNewsEntry>> animeNews(AnimeEntryData entry, int page) async {
    final response = await api.Jikan(debug: kDebugMode)
        .getAnimeNews(entry.id, page: page + 1);

    return response
        .map(
          (e) => AnimeNewsEntry(
            content: e.excerpt,
            date: DateTime.parse(e.date),
            browserUrl: e.url,
            thumbUrl: e.imageUrl,
            title: e.title,
          ),
        )
        .toList();
  }

  @override
  Future<List<AnimeRecommendations>> recommendations(
    AnimeEntryData entry,
  ) async {
    final response =
        await api.Jikan(debug: kDebugMode).getAnimeRecommendations(entry.id);

    return response
        .map(
          (e) => AnimeRecommendations(
            thumbUrl: e.entry.imageUrl,
            title: e.entry.title,
            id: e.entry.malId,
          ),
        )
        .toList();
  }

  @override
  Future<List<AnimePicture>> pictures(AnimeEntryData entry) async {
    final result =
        await api.Jikan(debug: kDebugMode).getAnimePictures(entry.id);

    return result
        .map(
          (e) => AnimePicture(
            imageUrl: e.largeImageUrl ?? e.imageUrl,
            thumbUrl: e.smallImageUrl ?? e.imageUrl,
          ),
        )
        .toList();
  }
}

AnimeCharacter _fromJikanCharacter(api.CharacterMeta e) => objFactory
    .makeAnimeCharacter(imageUrl: e.imageUrl, name: e.name, role: e.role);

List<AnimeRelation> _fromMeta(api.BuiltList<api.Meta> l) {
  return l
      .map(
        (e) => objFactory.makeAnimeRelation(
          thumbUrl: e.url,
          title: e.name,
          type: e.type,
          id: e.malId,
        ),
      )
      .toList();
}

AnimeSearchEntry _fromJikanAnime(api.Anime e) {
  return AnimeSearchEntry(
    explicit: e.genres.indexWhere((e) => e.name == "Hentai") != -1
        ? AnimeSafeMode.h
        : e.genres.indexWhere((e) => e.name == "Ecchi") != -1
            ? AnimeSafeMode.ecchi
            : AnimeSafeMode.safe,
    type: e.type ?? "",
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
    staff: e.producers
        .map(
          (e) => objFactory.makeAnimeRelation(
            title: e.name,
            type: e.type,
            id: e.malId,
            thumbUrl: "",
          ),
        )
        .toList(),
    isAiring: e.airing,
    titleEnglish: e.titleEnglish ?? "",
    titleJapanese: e.titleJapanese ?? "",
    titleSynonyms: e.titleSynonyms.toList(),
    genres: e.genres
            .map(
              (e) => objFactory.makeAnimeGenre(
                title: e.name,
                id: e.malId,
                unpressable: false,
                explicit: false,
              ),
            )
            .toList() +
        e.explicitGenres
            .map(
              (e) => objFactory.makeAnimeGenre(
                title: e.name,
                id: e.malId,
                unpressable: false,
                explicit: true,
              ),
            )
            .toList() +
        e.demographics
            .map(
              (e) => objFactory.makeAnimeGenre(
                title: e.name,
                id: e.malId,
                unpressable: false,
                explicit: false,
              ),
            )
            .toList() +
        e.themes
            .map(
              (e) => objFactory.makeAnimeGenre(
                title: e.name,
                id: e.malId,
                unpressable: false,
                explicit: false,
              ),
            )
            .toList() +
        e.studios
            .map(
              (e) => objFactory.makeAnimeGenre(
                title: e.name,
                unpressable: true,
                explicit: false,
                id: -1,
              ),
            )
            .toList(),
    trailerUrl: e.trailerUrl ?? "",
    episodes: e.episodes ?? 0,
    background: e.background ?? "",
    id: e.malId,
  );
}
