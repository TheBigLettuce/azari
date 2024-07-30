// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:isar/isar.dart";

part "watched_anime_entry.g.dart";

@collection
class IsarWatchedAnimeEntry extends AnimeEntryDataImpl
    with DefaultWatchedAnimeEntryPressable
    implements $WatchedAnimeEntryData {
  const IsarWatchedAnimeEntry({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.isarId,
    required this.date,
    required this.relations,
    required this.explicit,
    required this.type,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.background,
    required this.trailerUrl,
    required this.episodes,
    required this.genres,
    required this.staff,
  });

  const IsarWatchedAnimeEntry.noIdList({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.date,
    required this.explicit,
    required this.type,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.background,
    required this.trailerUrl,
    required this.episodes,
  })  : isarId = null,
        staff = const [],
        genres = const [],
        relations = const [];

  final Id? isarId;

  @override
  final List<IsarAnimeGenre> genres;

  @override
  final List<IsarAnimeRelation> relations;

  @override
  final List<IsarAnimeRelation> staff;

  @override
  final String background;

  @override
  final DateTime date;

  @override
  final int episodes;

  @override
  @enumerated
  final AnimeSafeMode explicit;

  @override
  final int id;

  @override
  final bool isAiring;

  @override
  final double score;

  @override
  @Index(unique: true, replace: true, composite: [CompositeIndex("id")])
  @enumerated
  final AnimeMetadata site;

  @override
  final String siteUrl;

  @override
  final String synopsis;

  @override
  @Index(unique: true, replace: true)
  final String thumbUrl;

  @override
  final String title;

  @override
  final String titleEnglish;

  @override
  final String titleJapanese;

  @override
  final List<String> titleSynonyms;

  @override
  final String trailerUrl;

  @override
  final String type;

  @override
  final DateTime? airedFrom;

  @override
  final DateTime? airedTo;

  @override
  final String imageUrl;

  @override
  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) {
    return IsarWatchedAnimeEntry(
      imageUrl: e.imageUrl,
      relations: ignoreRelations
          ? relations
          : (e.relations is List<IsarAnimeRelation>
              ? e.relations as List<IsarAnimeRelation>
              : e.relations.cast()),
      staff: (e.staff is List<IsarAnimeRelation>
          ? e.staff as List<IsarAnimeRelation>
          : e.staff.cast()),
      genres: (e.genres is List<IsarAnimeGenre>
          ? e.genres as List<IsarAnimeGenre>
          : e.genres.cast()),
      isarId: isarId,
      date: date,
      type: e.type,
      explicit: e.explicit,
      site: e.site,
      thumbUrl: e.thumbUrl,
      title: e.title,
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      synopsis: e.synopsis,
      id: e.id,
      siteUrl: e.siteUrl,
      isAiring: e.isAiring,
      titleSynonyms: e.titleSynonyms,
      background: e.background,
      trailerUrl: e.trailerUrl,
      episodes: e.episodes,
      airedFrom: e.airedFrom,
      airedTo: e.airedTo,
    );
  }

  @override
  WatchedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? siteUrl,
    String? imageUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    double? score,
    String? thumbUrl,
    String? synopsis,
    DateTime? date,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  }) {
    return IsarWatchedAnimeEntry(
      isarId: isarId,
      imageUrl: imageUrl ?? this.imageUrl,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      date: date ?? this.date,
      site: site ?? this.site,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      id: id ?? this.id,
      relations: (relations is List<IsarAnimeRelation>
              ? relations
              : relations?.cast()) ??
          this.relations,
      staff: (staff is List<IsarAnimeRelation> ? staff : staff?.cast()) ??
          this.staff,
      genres: (genres is List<IsarAnimeGenre> ? genres : genres?.cast()) ??
          this.genres,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      background: background ?? this.background,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
      airedFrom: airedFrom ?? this.airedFrom,
      airedTo: airedTo ?? this.airedTo,
    );
  }
}
