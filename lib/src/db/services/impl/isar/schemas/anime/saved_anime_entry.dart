// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:isar/isar.dart";

part "saved_anime_entry.g.dart";

@embedded
class IsarAnimeGenre implements AnimeGenre {
  const IsarAnimeGenre({
    this.id = 0,
    this.title = "",
    this.unpressable = false,
    this.explicit = false,
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
class IsarAnimeRelation implements AnimeRelation {
  const IsarAnimeRelation({
    this.thumbUrl = "",
    this.title = "",
    this.type = "",
    this.id = 0,
  });

  @override
  final String thumbUrl;
  @override
  final String title;
  @override
  final String type;
  @override
  final int id;

  @override
  @ignore
  bool get idIsValid => id != 0 && type != "manga";

  @override
  String toString() => title;
}

@collection
class IsarSavedAnimeEntry extends SavedAnimeEntryData implements IsarEntryId {
  IsarSavedAnimeEntry({
    required this.genres,
    required super.id,
    required super.inBacklog,
    required super.type,
    required super.explicit,
    required super.site,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required this.relations,
    required super.synopsis,
    required super.year,
    required this.staff,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.background,
    required super.trailerUrl,
    required super.episodes,
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
  IsarSavedAnimeEntry copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]) {
    return IsarSavedAnimeEntry(
      id: e.id,
      type: e.type,
      inBacklog: inBacklog,
      site: e.site,
      explicit: e.explicit,
      thumbUrl: e.thumbUrl,
      title: e.title,
      staff: e.staff as List<IsarAnimeRelation>,
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      relations:
          ignoreRelations ? relations : e.relations as List<IsarAnimeRelation>,
      synopsis: e.synopsis,
      year: e.year,
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
  IsarSavedAnimeEntry copy({
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
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
  }) {
    return IsarSavedAnimeEntry(
      id: id ?? this.id,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      relations: relations as List<IsarAnimeRelation>? ?? this.relations,
      background: background ?? this.background,
      inBacklog: inBacklog ?? this.inBacklog,
      site: site ?? this.site,
      staff: staff as List<IsarAnimeRelation>? ?? this.staff,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      year: year ?? this.year,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      genres: genres as List<IsarAnimeGenre>? ?? this.genres,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
    );
  }
}
