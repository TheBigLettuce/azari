// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:gallery/src/db/services/impl_table/io.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:isar/isar.dart";

part "watched_anime_entry.g.dart";

@collection
class IsarWatchedAnimeEntry extends AnimeEntryDataImpl
    implements $WatchedAnimeEntryData {
  const IsarWatchedAnimeEntry({
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
    required this.year,
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

  const IsarWatchedAnimeEntry.noId({
    required this.date,
    required List<AnimeRelation> relations,
    required this.explicit,
    required this.type,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.year,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.background,
    required this.trailerUrl,
    required this.episodes,
    required List<AnimeGenre> genres,
    required List<AnimeRelation> staff,
  })  : isarId = null,
        staff = staff as List<IsarAnimeRelation>,
        genres = genres as List<IsarAnimeGenre>,
        relations = relations as List<IsarAnimeRelation>;

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
  final int year;

  @override
  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) {
    return IsarWatchedAnimeEntry(
      isarId: isarId,
      date: date,
      staff: e.staff as List<IsarAnimeRelation>,
      type: e.type,
      explicit: e.explicit,
      site: e.site,
      thumbUrl: e.thumbUrl,
      title: e.title,
      relations:
          ignoreRelations ? relations : e.relations as List<IsarAnimeRelation>,
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      synopsis: e.synopsis,
      year: e.year,
      id: e.id,
      siteUrl: e.siteUrl,
      isAiring: e.isAiring,
      titleSynonyms: e.titleSynonyms,
      genres: e.genres as List<IsarAnimeGenre>,
      background: e.background,
      trailerUrl: e.trailerUrl,
      episodes: e.episodes,
    );
  }

  @override
  WatchedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? siteUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    int? year,
    double? score,
    String? thumbUrl,
    String? synopsis,
    DateTime? date,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
  }) {
    return IsarWatchedAnimeEntry(
      isarId: isarId,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      date: date ?? this.date,
      site: site ?? this.site,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      relations: relations as List<IsarAnimeRelation>? ?? this.relations,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      year: year ?? this.year,
      id: id ?? this.id,
      staff: staff as List<IsarAnimeRelation>? ?? this.staff,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      genres: genres as List<IsarAnimeGenre>? ?? this.genres,
      background: background ?? this.background,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
    );
  }
}
