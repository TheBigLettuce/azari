// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:isar/isar.dart";

part "saved_anime_entry.g.dart";

@embedded
class IsarAnimeGenre implements $AnimeGenre {
  const IsarAnimeGenre({
    this.id = 0,
    this.title = "",
    this.unpressable = false,
    this.explicit = false,
  });

  const IsarAnimeGenre.required({
    required this.id,
    required this.title,
    required this.unpressable,
    required this.explicit,
  });

  @override
  final String title;
  @override
  final int id;
  @override
  final bool unpressable;
  @override
  final bool explicit;
}

@embedded
class IsarAnimeRelation implements $AnimeRelation {
  const IsarAnimeRelation({
    this.thumbUrl = "",
    this.title = "",
    this.type = "",
    this.id = 0,
  });

  const IsarAnimeRelation.required({
    required this.thumbUrl,
    required this.title,
    required this.type,
    required this.id,
  });

  @override
  final String thumbUrl;
  @override
  final String title;
  @override
  final String type;
  @override
  final int id;
}

@collection
class IsarSavedAnimeEntry extends AnimeEntryDataImpl
    with DefaultSavedAnimeEntryPressable
    implements $SavedAnimeEntryData {
  const IsarSavedAnimeEntry({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.isarId,
    required this.inBacklog,
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

  const IsarSavedAnimeEntry.noIdList({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.inBacklog,
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
  final bool inBacklog;

  @override
  final String background;

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
  IsarSavedAnimeEntry copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) {
    return IsarSavedAnimeEntry(
      isarId: isarId,
      imageUrl: e.imageUrl,
      id: e.id,
      type: e.type,
      inBacklog: inBacklog,
      site: e.site,
      explicit: e.explicit,
      thumbUrl: e.thumbUrl,
      title: e.title,
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
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      synopsis: e.synopsis,
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
  IsarSavedAnimeEntry copy({
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
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  }) {
    return IsarSavedAnimeEntry(
      isarId: isarId,
      imageUrl: imageUrl ?? this.imageUrl,
      id: id ?? this.id,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      relations: (relations is List<IsarAnimeRelation>
              ? relations
              : relations?.cast()) ??
          this.relations,
      staff: (staff is List<IsarAnimeRelation> ? staff : staff?.cast()) ??
          this.staff,
      genres: (genres is List<IsarAnimeGenre> ? genres : genres?.cast()) ??
          this.genres,
      background: background ?? this.background,
      inBacklog: inBacklog ?? this.inBacklog,
      site: site ?? this.site,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
      airedFrom: airedFrom ?? this.airedFrom,
      airedTo: airedTo ?? this.airedTo,
    );
  }
}
