// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension SavedAnimeEntryDataExt on SavedAnimeEntryData {
  void save() =>
      _currentDb.savedAnimeEntries.addAll([this], _currentDb.watchedAnime);
}

extension SavedAnimeEntryDataListExt on List<AnimeEntryData> {
  List<(int id, AnimeMetadata site)> get toIds =>
      map((e) => (e.id, e.site)).toList();
}

abstract interface class SavedAnimeEntriesService implements ServiceMarker {
  int get count;

  List<SavedAnimeEntryData> get backlogAll;
  List<SavedAnimeEntryData> get currentlyWatchingAll;

  void unsetIsWatchingAll(List<SavedAnimeEntryData> entries);
  SavedAnimeEntryData? maybeGet(int id, AnimeMetadata site);
  void update(AnimeEntryData e);

  (bool, bool) isWatchingBacklog(int id, AnimeMetadata site);
  void deleteAll(List<(int, AnimeMetadata)> ids);
  void reAdd(List<SavedAnimeEntryData> entries);

  void addAll(
    List<AnimeEntryData> entries,
    WatchedAnimeEntryService watchedAnime,
  );

  StreamSubscription<void> watchAll(
    void Function(void) f, [
    bool fire = false,
  ]);

  StreamSubscription<int> watchCount(
    void Function(int) f, [
    bool fire = false,
  ]);

  StreamSubscription<SavedAnimeEntryData?> watch(
    int id,
    AnimeMetadata site,
    void Function(SavedAnimeEntryData?) f, [
    bool fire = false,
  ]);
}
