//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:isar/isar.dart';

import 'saved_anime_entry.dart';

part 'watched_anime_entry.g.dart';

@collection
class WatchedAnimeEntry extends AnimeEntry {
  WatchedAnimeEntry({
    required this.date,
    required super.explicit,
    required super.type,
    required super.site,
    required super.thumbUrl,
    required super.title,
    required super.relations,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.genres,
    required super.background,
    required super.trailerUrl,
    required super.episodes,
  });

  final DateTime date;

  WatchedAnimeEntry copySuper(AnimeEntry e, [bool ignoreRelations = false]) {
    return WatchedAnimeEntry(
      date: date,
      type: e.type,
      explicit: e.explicit,
      site: e.site,
      thumbUrl: e.thumbUrl,
      title: e.title,
      relations: ignoreRelations ? relations : e.relations,
      titleJapanese: e.titleJapanese,
      titleEnglish: e.titleEnglish,
      score: e.score,
      synopsis: e.synopsis,
      year: e.year,
      id: e.id,
      siteUrl: e.siteUrl,
      isAiring: e.isAiring,
      titleSynonyms: e.titleSynonyms,
      genres: e.genres,
      background: e.background,
      trailerUrl: e.trailerUrl,
      episodes: e.episodes,
    );
  }

  WatchedAnimeEntry copy({
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
    DateTime? date,
    String? type,
    AnimeSafeMode? explicit,
  }) {
    return WatchedAnimeEntry(
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      date: date ?? this.date,
      site: site ?? this.site,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      relations: relations ?? this.relations,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      year: year ?? this.year,
      id: id ?? this.id,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      genres: genres ?? this.genres,
      background: background ?? this.background,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  void save() {
    Dbs.g.anime.writeTxnSync(
        () => Dbs.g.anime.watchedAnimeEntrys.putBySiteIdSync(this));
  }

  static bool watched(int id, AnimeMetadata site) {
    return Dbs.g.anime.watchedAnimeEntrys.getBySiteIdSync(site, id) != null;
  }

  static void delete(int id, AnimeMetadata site) {
    Dbs.g.anime.writeTxnSync(
        () => Dbs.g.anime.watchedAnimeEntrys.deleteBySiteIdSync(site, id));
  }

  static int count() => Dbs.g.anime.watchedAnimeEntrys.countSync();

  static List<WatchedAnimeEntry> get all =>
      Dbs.g.anime.watchedAnimeEntrys.where().findAllSync();

  static void read(WatchedAnimeEntry entry) {
    Dbs.g.anime.writeTxnSync(
        () => Dbs.g.anime.watchedAnimeEntrys.putBySiteIdSync(entry));
  }

  static WatchedAnimeEntry? maybeGet(int id, AnimeMetadata site) =>
      Dbs.g.anime.watchedAnimeEntrys.getBySiteIdSync(site, id);

  static void move(SavedAnimeEntry entry) {
    SavedAnimeEntry.deleteAll([entry.isarId!]);

    Dbs.g.anime
        .writeTxnSync(() => Dbs.g.anime.watchedAnimeEntrys.putBySiteIdSync(
              WatchedAnimeEntry(
                type: entry.type,
                explicit: entry.explicit,
                date: DateTime.now(),
                site: entry.site,
                relations: entry.relations,
                background: entry.background,
                thumbUrl: entry.thumbUrl,
                title: entry.title,
                titleJapanese: entry.titleJapanese,
                titleEnglish: entry.titleEnglish,
                score: entry.score,
                synopsis: entry.synopsis,
                year: entry.year,
                id: entry.id,
                siteUrl: entry.siteUrl,
                isAiring: entry.isAiring,
                titleSynonyms: entry.titleSynonyms,
                genres: entry.genres,
                trailerUrl: entry.trailerUrl,
                episodes: entry.episodes,
              ),
            ));
  }

  static StreamSubscription<void> watchAll(void Function(void) f,
      [bool fire = false]) {
    return Dbs.g.anime.watchedAnimeEntrys
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  StreamSubscription<WatchedAnimeEntry?> watch(
      void Function(WatchedAnimeEntry?) f,
      [bool fire = false]) {
    return Dbs.g.anime.watchedAnimeEntrys
        .watchObject(isarId!, fireImmediately: fire)
        .listen(f);
  }
}
