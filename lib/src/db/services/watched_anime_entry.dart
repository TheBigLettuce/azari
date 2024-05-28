// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension WatchedAnimeEntryDataExt on WatchedAnimeEntryData {
  void save() => _currentDb.watchedAnime.add(this);
}

extension WatchedAnimeEntryDataListExt on List<WatchedAnimeEntryData> {
  List<(int id, AnimeMetadata site)> get toIds =>
      map((e) => (e.id, e.site)).toList();
}

abstract class WatchedAnimeEntryData extends AnimeEntryData {
  const WatchedAnimeEntryData({
    required super.site,
    required super.type,
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
    required super.trailerUrl,
    required super.episodes,
    required super.background,
    required super.explicit,
    required this.date,
  });

  final DateTime date;

  WatchedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]);

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
  });

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
}

abstract interface class WatchedAnimeEntryService implements ServiceMarker {
  int get count;

  List<WatchedAnimeEntryData> get all;

  bool watched(int id, AnimeMetadata site);

  void delete(int id, AnimeMetadata site);
  void deleteAll(List<(int id, AnimeMetadata site)> ids);

  void update(AnimeEntryData e);
  void add(WatchedAnimeEntryData entry);
  void reAdd(List<WatchedAnimeEntryData> entries);

  WatchedAnimeEntryData? maybeGet(int id, AnimeMetadata site);
  void moveAllReversed(
    List<WatchedAnimeEntryData> entries,
    SavedAnimeEntriesService savedAnimeEntries,
  );
  void moveAll(
    List<AnimeEntryData> entries,
    SavedAnimeEntriesService savedAnimeEntries,
  );

  StreamSubscription<void> watchAll(
    void Function(void) f, [
    bool fire = false,
  ]);

  StreamSubscription<int> watchCount(
    void Function(int) f, [
    bool fire = false,
  ]);

  StreamSubscription<WatchedAnimeEntryData?> watchSingle(
    int id,
    AnimeMetadata site,
    void Function(WatchedAnimeEntryData?) f, [
    bool fire = false,
  ]);
}