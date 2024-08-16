// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension SavedAnimeEntryDataExt on AnimeEntryData {
  void saveWatching() =>
      _currentDb.savedAnimeEntries.watching.backingStorage.add(this);
  void saveBacklog() =>
      _currentDb.savedAnimeEntries.backlog.backingStorage.add(this);
}

extension SavedAnimeEntryDataListExt on List<AnimeEntryData> {
  List<(int id, AnimeMetadata site)> get toIds =>
      map((e) => (e.id, e.site)).toList();
}

abstract interface class SavedAnimeEntriesService implements ServiceMarker {
  AnimeEntriesSource get watching;
  AnimeEntriesSource get backlog;
  AnimeEntriesSource get watched;

  // void unsetIsWatchingAll(List<SavedAnimeEntryData> entries);

  // (bool, bool) isWatchingBacklog(int id, AnimeMetadata site);

  // StreamSubscription<void> watchAll(
  //   void Function(void) f, [
  //   bool fire = false,
  // ]);
}

abstract interface class AnimeEntriesSource
    implements ResourceSource<(int id, AnimeMetadata site), AnimeEntryData> {
  // List<SavedAnimeEntryData> get all;

  // SavedAnimeEntryData? maybeGet(int id, AnimeMetadata site);

  void update(AnimeEntryData e);

  // void reAdd(List<SavedAnimeEntryData> entries);
  // void addAll(
  //   List<AnimeEntryData> entries,
  //   WatchedAnimeEntryService watchedAnime,
  // );

  // void deleteAll(List<(int, AnimeMetadata)> ids);

  // StreamSubscription<int> watchCount(
  //   void Function(int) f, [
  //   bool fire = false,
  // ]);

  StreamSubscription<AnimeEntryData?> watchSingle(
    int id,
    AnimeMetadata site,
    void Function(AnimeEntryData?) f, [
    bool fire = false,
  ]);
}
