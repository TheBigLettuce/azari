// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:isar/isar.dart";

part "watched_anime_entry.g.dart";

@collection
class IsarWatchedAnimeEntry extends WatchedAnimeEntryData
    implements IsarEntryId {
  IsarWatchedAnimeEntry({
    required super.date,
    required this.relations,
    required super.explicit,
    required super.type,
    required super.site,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.background,
    required super.trailerUrl,
    required super.episodes,
    required this.genres,
    required this.staff,
  });

  @override
  Id? isarId;

  @override
  final List<IsarAnimeGenre> genres;

  @override
  final List<IsarAnimeRelation> relations;

  @override
  final List<IsarAnimeRelation> staff;

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<AnimeEntryData> functionality,
    AnimeEntryData cell,
    int idx,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AnimeInfoPage(
            id: cell.id,
            entry: cell,
            apiFactory: cell.site.api,
            db: DatabaseConnectionNotifier.of(context),
          );
        },
      ),
    );
  }

  @override
  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) {
    return IsarWatchedAnimeEntry(
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
