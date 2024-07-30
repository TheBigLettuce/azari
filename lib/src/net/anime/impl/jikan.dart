// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/logging/logging.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:jikan_api/jikan_api.dart" as api;
import "package:logging/logging.dart";

class Jikan implements AnimeAPI {
  const Jikan(this.client);

  static final _log = Logger("Jikan API");

  final Dio client;

  @override
  bool get charactersIsSync => false;

  @override
  AnimeMetadata get site => AnimeMetadata.jikan;

  @override
  Future<AnimeEntryData> info(int id) async {
    try {
      final resp = await client.getUriLog<Map<dynamic, dynamic>>(
        Uri.https(site.apiUrl, "/v4/anime/$id/full"),
        LogReq("search", _log),
      );

      return _fromJson(resp.data!["data"] as Map<dynamic, dynamic>);
    } catch (e, trace) {
      _log.warning(".info", e, trace);

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
    AnimeSafeMode? mode, {
    AnimeSortOrder sortOrder = AnimeSortOrder.normal,
  }) async {
    final url = Uri.https(site.apiUrl, "/v4/anime", {
      if (mode == AnimeSafeMode.ecchi) "rating": "rx",
      if (mode == AnimeSafeMode.safe) "sfw": "true",
      "page": (page + 1).toString(),
      "q": title,
      "order_by": switch (sortOrder) {
        AnimeSortOrder.normal => title.isEmpty ? "score" : "title",
        AnimeSortOrder.latest => "start_date",
      },
      "sort": switch (sortOrder) {
        AnimeSortOrder.normal => title.isEmpty ? "desc" : "asc",
        AnimeSortOrder.latest => "desc",
      },
      if (genreId != null || mode == AnimeSafeMode.ecchi)
        "genres": [
          if (genreId != null) genreId,

          /// havent found a good way
          if (mode == AnimeSafeMode.ecchi) 9,
        ].join(","),
    });

    final resp = await client.getUriLog<Map<dynamic, dynamic>>(
      url,
      LogReq("search", _log),
    );

    final ret = (resp.data!["data"] as List<dynamic>)
        .map<AnimeSearchEntry>((e) => _fromJson(e as Map<dynamic, dynamic>))
        .toList();

    return ret;
  }

  @override
  Future<Map<int, AnimeGenre>> genres(AnimeSafeMode mode) async {
    final response = await api.Jikan(debug: kDebugMode).getAnimeGenres(
      type: mode == AnimeSafeMode.h ? api.GenreType.explicit_genres : null,
    );
    final map = <int, AnimeGenre>{};

    for (final e in response) {
      map[e.malId] = AnimeGenre(
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

AnimeCharacter _fromJikanCharacter(api.CharacterMeta e) =>
    AnimeCharacter(imageUrl: e.imageUrl, name: e.name, role: e.role);

AnimeGenre _metaFromJson(
  Map<dynamic, dynamic> json, {
  required bool unpressable,
  required bool explicit,
  bool minusId = false,
}) {
  return AnimeGenre(
    id: minusId ? -1 : json["mal_id"] as int,
    title: json["name"] as String,
    unpressable: unpressable,
    explicit: explicit,
  );
}

AnimeRelation _relationFromJson(Map<dynamic, dynamic> json, bool addThumbUrl) {
  return AnimeRelation(
    title: (json["name"] as String?) ?? "",
    type: (json["type"] as String?) ?? "",
    id: json["mal_id"] as int,
    thumbUrl: addThumbUrl ? (json["url"] as String?) ?? "" : "",
  );
}

AnimeSearchEntry _fromJson(Map<dynamic, dynamic> json) {
  final images = (json["images"] as Map<dynamic, dynamic>)["webp"]
      as Map<dynamic, dynamic>;
  final trailer = json["trailer"] as Map<dynamic, dynamic>;
  final aired = json["aired"] as Map<dynamic, dynamic>;
  final airedFrom = aired["from"] as String?;
  final airedTo = aired["to"] as String?;
  final titleSynonyms = json["title_synonyms"] as List<dynamic>;
  final genres = (json["genres"] as List<dynamic>)
      .map(
        (e) => _metaFromJson(
          e as Map<dynamic, dynamic>,
          unpressable: false,
          explicit: false,
        ),
      )
      .toList();
  final genresExplicit = (json["explicit_genres"] as List<dynamic>)
      .cast<Map<dynamic, dynamic>>()
      .toList();
  final demographics = (json["demographics"] as List<dynamic>)
      .cast<Map<dynamic, dynamic>>()
      .toList();
  final themes =
      (json["themes"] as List<dynamic>).cast<Map<dynamic, dynamic>>().toList();
  final studios =
      (json["studios"] as List<dynamic>).cast<Map<dynamic, dynamic>>().toList();
  final producers = (json["producers"] as List<dynamic>)
      .cast<Map<dynamic, dynamic>>()
      .toList();
  final relations = json["relations"] == null
      ? null
      : (json["relations"] as List<dynamic>)
          .map((e) => (e as Map<dynamic, dynamic>)["entry"] as List<dynamic>);

  final thumbUrl = images["image_url"] as String;

  return AnimeSearchEntry(
    id: json["mal_id"] as int,
    imageUrl: images["large_image_url"] as String? ?? thumbUrl,
    explicit: genres.indexWhere((e) => e.title == "Hentai") != -1
        ? AnimeSafeMode.h
        : genres.indexWhere((e) => e.title == "Ecchi") != -1
            ? AnimeSafeMode.ecchi
            : AnimeSafeMode.safe,
    type: (json["type"] as String?) ?? "",
    thumbUrl: thumbUrl,
    title: json["title"] as String,
    site: AnimeMetadata.jikan,
    score: (json["score"] is int
            ? (json["score"] as int).toDouble()
            : json["score"] as double?) ??
        0,
    synopsis: (json["synopsis"] as String?) ?? "",
    relations: relations
            ?.reduce((l1, l2) => l1 + l2)
            .map((e) => _relationFromJson(e as Map<dynamic, dynamic>, true))
            .toList() ??
        const [],
    siteUrl: json["url"] as String,
    staff: producers.map((e) => _relationFromJson(e, false)).toList(),
    isAiring: json["airing"] as bool,
    titleEnglish: (json["title_english"] as String?) ?? "",
    titleJapanese: (json["title_japanese"] as String?) ?? "",
    airedFrom: airedFrom == null ? null : DateTime.parse(airedFrom),
    airedTo: airedTo == null ? null : DateTime.parse(airedTo),
    titleSynonyms: titleSynonyms.cast(),
    genres: genres
        .followedBy(
          genresExplicit
              .map((e) => _metaFromJson(e, unpressable: false, explicit: true)),
        )
        .followedBy(
          demographics.map(
            (e) => _metaFromJson(e, unpressable: false, explicit: false),
          ),
        )
        .followedBy(
          themes.map(
            (e) => _metaFromJson(e, unpressable: false, explicit: false),
          ),
        )
        .followedBy(
          studios
              .map((e) => _metaFromJson(e, unpressable: true, explicit: false)),
        )
        .toList(),
    trailerUrl: (trailer["url"] as String?) ?? "",
    episodes: (json["episodes"] as int?) ?? 0,
    background: (json["background"] as String?) ?? "",
  );
}
