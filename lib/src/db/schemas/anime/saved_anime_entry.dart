// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/pages/anime/info_pages/discover_anime_info_page.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:isar/isar.dart';

part 'saved_anime_entry.g.dart';

@embedded
class AnimeGenre {
  final String title;
  final int id;
  final bool unpressable;
  final bool explicit;

  const AnimeGenre({
    this.id = 0,
    this.title = "",
    this.unpressable = false,
    this.explicit = false,
  });
}

@embedded
class Relation {
  final String thumbUrl;
  final String title;
  final String type;
  final int id;

  bool get idIsValid => id != 0 && type != "manga";

  @override
  String toString() {
    return title;
  }

  Relation({
    this.thumbUrl = "",
    this.title = "",
    this.type = "",
    this.id = 0,
  });
}

@collection
class SavedAnimeEntry extends AnimeEntry
    implements IsarEntryId, Pressable<SavedAnimeEntry> {
  SavedAnimeEntry({
    required super.id,
    required this.inBacklog,
    required super.type,
    required super.explicit,
    required super.site,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.relations,
    required super.synopsis,
    required super.year,
    required super.staff,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.genres,
    required super.background,
    required super.trailerUrl,
    required super.episodes,
  });

  final bool inBacklog;

  @override
  Id? isarId;

  @override
  void onPress(BuildContext context,
      GridFunctionality<AnimeEntry> functionality, AnimeEntry cell, int idx) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return DiscoverAnimeInfoPage(
          entry: cell,
        );
      },
    ));
  }

  void save() {
    Dbs.g.anime
        .writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys.putBySiteIdSync(this));
  }

  SavedAnimeEntry copySuper(AnimeEntry e, [bool ignoreRelations = false]) {
    return SavedAnimeEntry(
      id: e.id,
      type: e.type,
      inBacklog: inBacklog,
      site: e.site,
      explicit: e.explicit,
      thumbUrl: e.thumbUrl,
      title: e.title,
      staff: e.staff,
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      relations: ignoreRelations ? relations : e.relations,
      synopsis: e.synopsis,
      year: e.year,
      siteUrl: e.siteUrl,
      isAiring: e.isAiring,
      titleSynonyms: e.titleSynonyms,
      genres: e.genres,
      background: e.background,
      trailerUrl: e.trailerUrl,
      episodes: e.episodes,
    );
  }

  SavedAnimeEntry copy({
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
    List<Relation>? relations,
    bool? isAiring,
    int? year,
    double? score,
    String? thumbUrl,
    String? synopsis,
    String? type,
    AnimeSafeMode? explicit,
    List<Relation>? staff,
  }) {
    return SavedAnimeEntry(
      id: id ?? this.id,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      relations: relations ?? this.relations,
      background: background ?? this.background,
      inBacklog: inBacklog ?? this.inBacklog,
      site: site ?? this.site,
      staff: staff ?? this.staff,
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
      genres: genres ?? this.genres,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  void unsetIsWatching() {
    final current = get(isarId!, false);
    Dbs.g.anime.writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys
        .putBySiteIdSync(current.copy(inBacklog: true)));
  }

  bool setCurrentlyWatching() {
    final current = get(isarId!, false);
    if (!current.inBacklog ||
        Dbs.g.anime.savedAnimeEntrys
                .filter()
                .inBacklogEqualTo(false)
                .countSync() >=
            3) {
      return false;
    }

    Dbs.g.anime.writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys
        .putBySiteIdSync(current.copy(inBacklog: false)));

    return true;
  }

  static void unsetIsWatchingAll(List<SavedAnimeEntry> entries) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.savedAnimeEntrys.putAllBySiteIdSync(
          entries.map((e) => e.copy(inBacklog: true)).toList()),
    );
  }

  static List<SavedAnimeEntry> backlog() {
    return Dbs.g.anime.savedAnimeEntrys
        .filter()
        .inBacklogEqualTo(true)
        .findAllSync();
  }

  static List<SavedAnimeEntry> currentlyWatching() {
    return Dbs.g.anime.savedAnimeEntrys
        .filter()
        .inBacklogEqualTo(false)
        .findAllSync();
  }

  static SavedAnimeEntry get(int id, [bool addOne = true]) =>
      Dbs.g.anime.savedAnimeEntrys.getSync(id + (addOne ? 1 : 0))!;

  static SavedAnimeEntry? maybeGet(int id, AnimeMetadata site) =>
      Dbs.g.anime.savedAnimeEntrys.getBySiteIdSync(site, id);

  static int count() => Dbs.g.anime.savedAnimeEntrys.countSync();

  static (bool, bool) isWatchingBacklog(int id, AnimeMetadata site) {
    final e = Dbs.g.anime.savedAnimeEntrys.getBySiteIdSync(site, id);

    if (e == null) {
      return (false, false);
    }

    return (true, e.inBacklog);
  }

  static void deleteAll(List<IsarEntryId> ids) {
    Dbs.g.anime.writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys
        .deleteAllSync(ids.map((e) => e.isarId!).toList()));
  }

  static void deleteAllIds(List<(int, AnimeMetadata)> ids) {
    if (ids.isEmpty) {
      return;
    }

    Dbs.g.anime
        .writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys.deleteAllBySiteIdSync(
              ids.map((e) => e.$2).toList(),
              ids.map((e) => e.$1).toList(),
            ));
  }

  static void reAdd(List<SavedAnimeEntry> entries) {
    Dbs.g.anime
        .writeTxnSync(() => Dbs.g.anime.savedAnimeEntrys.putAllSync(entries));
  }

  static void addAll(List<AnimeEntry> entries) {
    if (entries.isEmpty) {
      return;
    }

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.savedAnimeEntrys.putAllSync(entries
          .where(
              (element) => !WatchedAnimeEntry.watched(element.id, element.site))
          .map((e) => SavedAnimeEntry(
              id: e.id,
              explicit: e.explicit,
              type: e.type,
              inBacklog: true,
              site: e.site,
              staff: e.staff,
              relations: e.relations,
              thumbUrl: e.thumbUrl,
              title: e.title,
              titleJapanese: e.titleJapanese,
              titleEnglish: e.titleEnglish,
              score: e.score,
              synopsis: e.synopsis,
              year: e.year,
              background: e.background,
              siteUrl: e.siteUrl,
              isAiring: e.isAiring,
              titleSynonyms: e.titleSynonyms,
              genres: e.genres,
              trailerUrl: e.trailerUrl,
              episodes: e.episodes))
          .toList()),
    );
  }

  static StreamSubscription<void> watchAll(void Function(void) f,
      [bool fire = false]) {
    return Dbs.g.anime.savedAnimeEntrys
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  StreamSubscription<SavedAnimeEntry?> watch(void Function(SavedAnimeEntry?) f,
      [bool fire = false]) {
    return Dbs.g.anime.savedAnimeEntrys
        .watchObject(isarId!, fireImmediately: fire)
        .listen(f);
  }
}
