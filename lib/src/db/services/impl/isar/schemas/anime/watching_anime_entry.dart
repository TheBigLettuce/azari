// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/impl/isar/schemas/anime/anime_entry_base.dart";
import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:isar/isar.dart";

part "watching_anime_entry.g.dart";

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
class IsarWatchingAnimeEntry extends IsarAnimeEntry {
  const IsarWatchingAnimeEntry({
    required super.imageUrl,
    required super.airedFrom,
    required super.airedTo,
    required this.isarId,
    required super.relations,
    required super.explicit,
    required super.type,
    required super.site,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.background,
    required super.trailerUrl,
    required super.episodes,
    required super.genres,
    required super.staff,
  });

  final Id? isarId;

  @override
  Null properties() => null;

  @override
  IsarWatchingAnimeEntry copy({
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
    return IsarWatchingAnimeEntry(
      isarId: isarId,
      imageUrl: imageUrl ?? this.imageUrl,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
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
