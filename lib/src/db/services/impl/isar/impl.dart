// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io" as io;
import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_characters.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/saved_anime_entry.dart";
import "package:gallery/src/db/services/impl/isar/schemas/anime/watched_anime_entry.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/favorite_booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/directory_metadata.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/directory_tags.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/favorite_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/pinned_thumbnail.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/system_gallery_directory.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/thumbnail.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/anime_discovery.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/directories.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/favorites.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/files.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_booru_paging.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_state.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_state/grid_state_booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/chapters_settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/read_manga_chapter.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/saved_manga_chapters.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/misc_settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/video_settings.dart";
import "package:gallery/src/db/services/impl/isar/schemas/statistics/daily_statistics.dart";
import "package:gallery/src/db/services/impl/isar/schemas/statistics/statistics_booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/statistics/statistics_gallery.dart";
import "package:gallery/src/db/services/impl/isar/schemas/statistics/statistics_general.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tag_dictionary.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/pinned_tag.dart";
import "package:gallery/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/manga/next_chapter_button.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:isar/isar.dart";
import "package:local_auth/local_auth.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";

part "foundation/dbs.dart";
part "foundation/initalize_db.dart";
part "settings.dart";

final _futures = <(int, AnimeMetadata), Future>{};

class IsarSavedAnimeCharatersService implements SavedAnimeCharactersService {
  const IsarSavedAnimeCharatersService();

  @override
  List<AnimeCharacter> load(int id, AnimeMetadata site) =>
      _Dbs.g.anime.isarSavedAnimeCharacters
          .getByIdSiteSync(id, site)
          ?.characters ??
      const [];

  @override
  bool addAsync(AnimeEntryData entry, AnimeAPI api) {
    if (_futures.containsKey((entry.id, entry.site))) {
      return true;
    }

    _futures[(entry.id, entry.site)] = api.characters(entry)
      ..then((value) {
        _Dbs.g.anime.writeTxnSync(
          () => _Dbs.g.anime.isarSavedAnimeCharacters.putByIdSiteSync(
            IsarSavedAnimeCharacters(
              characters: value as List<IsarAnimeCharacter>,
              id: entry.id,
              site: entry.site,
            ),
          ),
        );
      }).whenComplete(() => _futures.remove((entry.id, entry.site)));

    return false;
  }

  @override
  StreamSubscription<List<AnimeCharacter>?> watch(
    int id,
    AnimeMetadata site,
    void Function(List<AnimeCharacter>?) f, [
    bool fire = false,
  ]) {
    var e =
        _Dbs.g.anime.isarSavedAnimeCharacters.getByIdSiteSync(id, site)?.isarId;
    e ??= _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedAnimeCharacters.putByIdSiteSync(
        IsarSavedAnimeCharacters(characters: const [], id: id, site: site),
      ),
    );

    return _Dbs.g.anime.isarSavedAnimeCharacters
        .where()
        .idSiteEqualTo(id, site)
        .watchLazy(fireImmediately: fire)
        .map(
          (event) => _Dbs.g.anime.isarSavedAnimeCharacters
              .getByIdSiteSync(id, site)
              ?.characters,
        )
        .listen(f);
  }
}

class IsarLocalTagDictionaryService implements LocalTagDictionaryService {
  const IsarLocalTagDictionaryService();

  @override
  void addAll(List<String> tags) {
    _Dbs.g.main.writeTxnSync(
      () {
        _Dbs.g.main.localTagDictionarys.putAllSync(
          tags
              .map(
                (e) => LocalTagDictionary(
                  e,
                  (_Dbs.g.main.localTagDictionarys
                              .getSync(fastHash(e))
                              ?.frequency ??
                          0) +
                      1,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class IsarSavedAnimeEntriesService implements SavedAnimeEntriesService {
  const IsarSavedAnimeEntriesService();

  // void _unsetIsWatching() {
  //   final current = get(isarId!, false);
  //   Dbs.g.anime.writeTxnSync(
  //     () => Dbs.g.anime.savedAnimeEntrys
  //         .putBySiteIdSync(current.copy(inBacklog: true)),
  //   );
  // }

  // bool _setCurrentlyWatching() {
  //   final current = get(isarId!, false);
  //   if (!current.inBacklog ||
  //       Dbs.g.anime.savedAnimeEntrys
  //               .filter()
  //               .inBacklogEqualTo(false)
  //               .countSync() >=
  //           3) {
  //     return false;
  //   }

  //   Dbs.g.anime.writeTxnSync(
  //     () => Dbs.g.anime.savedAnimeEntrys
  //         .putBySiteIdSync(current.copy(inBacklog: false)),
  //   );

  //   return true;
  // }

// void deleteAllIds(List<(int, AnimeMetadata)> ids) {
  //   if (ids.isEmpty) {
  //     return;
  //   }

  //   Dbs.g.anime.writeTxnSync(
  //     () => Dbs.g.anime.savedAnimeEntrys.deleteAllBySiteIdSync(
  //       ids.map((e) => e.$2).toList(),
  //       ids.map((e) => e.$1).toList(),
  //     ),
  //   );
  // }

  @override
  void unsetIsWatchingAll(List<SavedAnimeEntryData> entries) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedAnimeEntrys.putAllBySiteIdSync(
        (entries as List<IsarSavedAnimeEntry>)
            .map((e) => e.copy(inBacklog: true))
            .toList(),
      ),
    );
  }

  @override
  List<SavedAnimeEntryData> get backlogAll => _Dbs.g.anime.isarSavedAnimeEntrys
      .filter()
      .inBacklogEqualTo(true)
      .findAllSync();

  @override
  List<SavedAnimeEntryData> get currentlyWatchingAll =>
      _Dbs.g.anime.isarSavedAnimeEntrys
          .filter()
          .inBacklogEqualTo(false)
          .findAllSync();

  @override
  SavedAnimeEntryData get(int id, [bool addOne = true]) =>
      _Dbs.g.anime.isarSavedAnimeEntrys.getSync(id + (addOne ? 1 : 0))!;

  @override
  SavedAnimeEntryData? maybeGet(int id, AnimeMetadata site) =>
      _Dbs.g.anime.isarSavedAnimeEntrys.getBySiteIdSync(site, id);

  @override
  void update(AnimeEntryData e) {
    final prev = maybeGet(e.id, e.site);

    if (prev == null) {
      return;
    }

    prev.copySuper(e).save();
  }

  @override
  int get count => _Dbs.g.anime.isarSavedAnimeEntrys.countSync();

  @override
  (bool, bool) isWatchingBacklog(int id, AnimeMetadata site) {
    final e = _Dbs.g.anime.isarSavedAnimeEntrys.getBySiteIdSync(site, id);

    if (e == null) {
      return (false, false);
    }

    return (true, e.inBacklog);
  }

  @override
  void deleteAll(List<(AnimeMetadata, int)> ids) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedAnimeEntrys.deleteAllBySiteIdSync(
        ids.map((e) => e.$1).toList(),
        ids.map((e) => e.$2).toList(),
      ),
    );
  }

  @override
  void reAdd(List<SavedAnimeEntryData> entries) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedAnimeEntrys
          .putAllSync(entries as List<IsarSavedAnimeEntry>),
    );
  }

  @override
  void addAll(
    List<AnimeEntryData> entries,
    WatchedAnimeEntryService watchedAnime,
  ) {
    if (entries.isEmpty) {
      return;
    }

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedAnimeEntrys.putAllBySiteIdSync(
        entries
            .where(
              (element) => !watchedAnime.watched(element.id, element.site),
            )
            .map(
              (e) => IsarSavedAnimeEntry(
                id: e.id,
                explicit: e.explicit,
                type: e.type,
                inBacklog: true,
                site: e.site,
                staff: e.staff as List<IsarAnimeRelation>,
                relations: e.relations as List<IsarAnimeRelation>,
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
                genres: e.genres as List<IsarAnimeGenre>,
                trailerUrl: e.trailerUrl,
                episodes: e.episodes,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  StreamSubscription<void> watchAll(
    void Function(void) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.anime.isarSavedAnimeEntrys
          .watchLazy(fireImmediately: fire)
          .listen(f);

  @override
  StreamSubscription<SavedAnimeEntryData?> watch(
    int id,
    AnimeMetadata site,
    void Function(SavedAnimeEntryData?) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.anime.isarSavedAnimeEntrys
          .where()
          .siteIdEqualTo(site, id)
          .watchLazy(fireImmediately: fire)
          .map((event) {
        return _Dbs.g.anime.isarSavedAnimeEntrys.getBySiteIdSync(site, id);
      }).listen(f);
}

class IsarVideoService implements VideoSettingsService {
  const IsarVideoService();

  @override
  VideoSettingsData get current =>
      _Dbs.g.main.isarVideoSettings.getSync(0) ??
      const IsarVideoSettings(looping: true, volume: 1);

  @override
  void add(VideoSettingsData data) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarVideoSettings.putSync(data as IsarVideoSettings),
    );
  }
}

class IsarMiscSettingsService implements MiscSettingsService {
  const IsarMiscSettingsService();

  @override
  MiscSettingsData get current =>
      _Dbs.g.main.isarMiscSettings.getSync(0) ??
      const IsarMiscSettings(
        animeWatchingOrderReversed: false,
        animeAlwaysLoadFromNet: false,
        filesExtendedActions: false,
        themeType: ThemeType.systemAccent,
        favoritesThumbId: 0,
        favoritesPageMode: FilteringMode.tag,
      );

  @override
  void add(MiscSettingsData data) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarMiscSettings.putSync(data as IsarMiscSettings),
    );
  }

  @override
  StreamSubscription<MiscSettingsData?> watch(
    void Function(MiscSettingsData?) f, [
    bool fire = false,
  ]) {
    return _Dbs.g.main.isarMiscSettings
        .watchObject(0, fireImmediately: fire)
        .listen(f);
  }
}

class IsarHiddenBooruPostService implements HiddenBooruPostService {
  const IsarHiddenBooruPostService();

  @override
  List<HiddenBooruPostData> get all =>
      _Dbs.g.main.isarHiddenBooruPosts.where().findAllSync();

  @override
  bool isHidden(int postId, Booru booru) =>
      _Dbs.g.main.isarHiddenBooruPosts.getByPostIdBooruSync(postId, booru) !=
      null;

  @override
  void addAll(List<HiddenBooruPostData> booru) {
    if (booru.isEmpty) {
      return;
    }

    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarHiddenBooruPosts
          .putAllSync(booru as List<IsarHiddenBooruPost>),
    );
  }

  @override
  void removeAll(List<(int, Booru)> booru) {
    if (booru.isEmpty) {
      return;
    }

    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarHiddenBooruPosts.deleteAllByPostIdBooruSync(
        booru.map((e) => e.$1).toList(),
        booru.map((e) => e.$2).toList(),
      ),
    );
  }

  @override
  StreamSubscription<void> watch(void Function(void) f) =>
      _Dbs.g.main.isarHiddenBooruPosts.watchLazy().listen(f);
}

class IsarFavoritePostService implements FavoritePostService {
  const IsarFavoritePostService();

  @override
  int get count => _Dbs.g.main.isarFavoriteBoorus.countSync();

  @override
  void addAllFileUrl(List<FavoritePostData> favorites) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarFavoriteBoorus
          .putAllByIdBooruSync(favorites as List<IsarFavoriteBooru>),
    );
  }

  @override
  void addRemove(
    BuildContext context,
    List<Post> posts,
    bool showDeleteSnackbar,
  ) {
    final toAdd = <IsarFavoriteBooru>[];
    final toRemoveInts = <int>[];
    final toRemoveBoorus = <Booru>[];

    for (final post in posts) {
      if (!isFavorite(post.id, post.booru)) {
        toAdd.add(
          IsarFavoriteBooru(
            height: post.height,
            id: post.id,
            md5: post.md5,
            tags: post.tags,
            width: post.width,
            fileUrl: post.fileUrl,
            booru: post.booru,
            previewUrl: post.previewUrl,
            sampleUrl: post.sampleUrl,
            sourceUrl: post.sourceUrl,
            rating: post.rating,
            score: post.score,
            createdAt: post.createdAt,
            group: null,
          ),
        );
      } else {
        toRemoveInts.add(post.id);
        toRemoveBoorus.add(post.booru);
      }
    }

    if (toAdd.isEmpty && toRemoveInts.isEmpty) {
      return;
    }

    final deleteCopy = toRemoveInts.isEmpty
        ? null
        : _Dbs.g.main.isarFavoriteBoorus
            .getAllByIdBooruSync(toRemoveInts, toRemoveBoorus);

    _Dbs.g.main.writeTxnSync(() {
      _Dbs.g.main.isarFavoriteBoorus.putAllByIdBooruSync(toAdd);
      _Dbs.g.main.isarFavoriteBoorus
          .deleteAllByIdBooruSync(toRemoveInts, toRemoveBoorus);
    });

    if (deleteCopy != null && showDeleteSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 20),
          content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undoLabel,
            onPressed: () {
              _Dbs.g.main.writeTxnSync(
                () => _Dbs.g.main.isarFavoriteBoorus
                    .putAllSync(deleteCopy as List<IsarFavoriteBooru>),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  bool isFavorite(int id, Booru booru) =>
      _Dbs.g.main.isarFavoriteBoorus.getByIdBooruSync(id, booru) != null;

  @override
  StreamSubscription<void> watch(
    void Function(void) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarFavoriteBoorus.watchLazy(fireImmediately: fire).listen(f);
}

class IsarWatchedAnimeEntryService implements WatchedAnimeEntryService {
  const IsarWatchedAnimeEntryService();

  @override
  bool watched(int id, AnimeMetadata site) {
    return _Dbs.g.anime.isarWatchedAnimeEntrys.getBySiteIdSync(site, id) !=
        null;
  }

  @override
  void delete(int id, AnimeMetadata site) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarWatchedAnimeEntrys.deleteBySiteIdSync(site, id),
    );
  }

  @override
  void deleteAll(List<(int, AnimeMetadata)> ids) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarWatchedAnimeEntrys.deleteAllBySiteIdSync(
        ids.map((e) => e.$2).toList(),
        ids.map((e) => e.$1).toList(),
      ),
    );
  }

  @override
  int get count => _Dbs.g.anime.isarWatchedAnimeEntrys.countSync();

  @override
  List<WatchedAnimeEntryData> get all =>
      _Dbs.g.anime.isarWatchedAnimeEntrys.where().findAllSync();

  @override
  void update(AnimeEntryData e) {
    final prev = maybeGet(e.id, e.site);

    if (prev == null) {
      return;
    }

    prev.copySuper(e).save();
  }

  @override
  void add(WatchedAnimeEntryData entry) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarWatchedAnimeEntrys
          .putBySiteIdSync(entry as IsarWatchedAnimeEntry),
    );
  }

  @override
  void reAdd(List<WatchedAnimeEntryData> entries) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarWatchedAnimeEntrys
          .putAllSync(entries as List<IsarWatchedAnimeEntry>),
    );
  }

  @override
  WatchedAnimeEntryData? maybeGet(int id, AnimeMetadata site) =>
      _Dbs.g.anime.isarWatchedAnimeEntrys.getBySiteIdSync(site, id);

  // @override
  // void moveAllReversed(List<WatchedAnimeEntry> entries) {
  //   WatchedAnimeEntry.deleteAll(entries);

  //   SavedAnimeEntry.addAll(entries.cast());
  // }

  // @override
  // void moveAll(List<AnimeEntry> entries) {
  //   SavedAnimeEntry.deleteAll(entries.map((e) => (e.site, e.id)).toList());

  //   _Dbs.g.anime.writeTxnSync(
  //     () => _Dbs.g.anime.isarWatchedAnimeEntrys.putAllBySiteIdSync(
  //       entries
  //           .map(
  //             (entry) => WatchedAnimeEntry(
  //               type: entry.type,
  //               explicit: entry.explicit,
  //               date: DateTime.now(),
  //               site: entry.site,
  //               relations: entry.relations,
  //               background: entry.background,
  //               thumbUrl: entry.thumbUrl,
  //               title: entry.title,
  //               titleJapanese: entry.titleJapanese,
  //               titleEnglish: entry.titleEnglish,
  //               score: entry.score,
  //               synopsis: entry.synopsis,
  //               year: entry.year,
  //               id: entry.id,
  //               staff: entry.staff,
  //               siteUrl: entry.siteUrl,
  //               isAiring: entry.isAiring,
  //               titleSynonyms: entry.titleSynonyms,
  //               genres: entry.genres,
  //               trailerUrl: entry.trailerUrl,
  //               episodes: entry.episodes,
  //             ),
  //           )
  //           .toList(),
  //     ),
  //   );
  // }

  @override
  StreamSubscription<void> watchAll(
    void Function(void) f, [
    bool fire = false,
  ]) {
    return _Dbs.g.anime.isarWatchedAnimeEntrys
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  @override
  StreamSubscription<WatchedAnimeEntryData?> watchSingle(
    int id,
    AnimeMetadata site,
    void Function(WatchedAnimeEntryData?) f, [
    bool fire = false,
  ]) {
    return _Dbs.g.anime.isarWatchedAnimeEntrys
        .where()
        .siteIdEqualTo(site, id)
        .watchLazy(fireImmediately: fire)
        .map((event) {
      return maybeGet(id, site);
    }).listen(f);
  }
}

class IsarDownloadFileService implements DownloadFileService {
  const IsarDownloadFileService();

  @override
  List<DownloadFileData> get inProgressAll => _Dbs.g.main.isarDownloadFiles
      .where()
      .inProgressEqualTo(true)
      .findAllSync();

  @override
  List<DownloadFileData> get failedAll =>
      _Dbs.g.main.isarDownloadFiles.where().isFailedEqualTo(true).findAllSync();

  @override
  void saveAll(List<DownloadFileData> l) {
    _Dbs.g.main.writeTxnSync(
      () =>
          _Dbs.g.main.isarDownloadFiles.putAllSync(l as List<IsarDownloadFile>),
    );
  }

  @override
  void deleteAll(List<String> urls) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarDownloadFiles.deleteAllByUrlSync(urls),
    );
  }

  @override
  DownloadFileData? get(String url) =>
      _Dbs.g.main.isarDownloadFiles.getByUrlSync(url);

  @override
  bool exist(String url) =>
      _Dbs.g.main.isarDownloadFiles.getByUrlSync(url) != null;

  @override
  bool notExist(String url) => !exist(url);

  @override
  void clear() =>
      _Dbs.g.main.writeTxnSync(() => _Dbs.g.main.isarDownloadFiles.clearSync());

  @override
  DownloadFileData? next() {
    return _Dbs.g.main.isarDownloadFiles
        .filter()
        .inProgressEqualTo(false)
        .and()
        .isFailedEqualTo(false)
        .findFirstSync();
  }

  @override
  StreamSubscription<void> watch(
    void Function(void) f, [
    bool fire = true,
  ]) {
    return _Dbs.g.main.isarDownloadFiles
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  @override
  List<DownloadFileData> nextNumber(int minus) {
    if (_Dbs.g.main.isarDownloadFiles.countSync() < 6) {
      return const [];
    }

    return _Dbs.g.main.isarDownloadFiles
        .filter()
        .inProgressEqualTo(false)
        .and()
        .isFailedEqualTo(false)
        .sortByDateDesc()
        .limit(6 - minus)
        .findAllSync();
  }
}

class IsarStatisticsGeneralService implements StatisticsGeneralService {
  const IsarStatisticsGeneralService();

  @override
  StatisticsGeneralData get current =>
      _Dbs.g.main.isarStatisticsGenerals.getSync(0) ??
      const IsarStatisticsGeneral(
        timeDownload: 0,
        timeSpent: 0,
        scrolledUp: 0,
        refreshes: 0,
      );

  @override
  void add(StatisticsGeneralData data) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarStatisticsGenerals
          .putSync(data as IsarStatisticsGeneral),
    );
  }
}

class IsarStatisticsGalleryService implements StatisticsGalleryService {
  const IsarStatisticsGalleryService();

  @override
  StatisticsGalleryData get current =>
      _Dbs.g.main.isarStatisticsGallerys.getSync(0) ??
      const IsarStatisticsGallery(
        copied: 0,
        deleted: 0,
        joined: 0,
        moved: 0,
        filesSwiped: 0,
        sameFiltered: 0,
        viewedDirectories: 0,
        viewedFiles: 0,
      );

  @override
  void add(StatisticsGalleryData data) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarStatisticsGallerys
          .putSync(data as IsarStatisticsGallery),
    );
  }
}

class IsarStatisticsBooruService implements StatisticsBooruService {
  const IsarStatisticsBooruService();

  @override
  StatisticsBooruData get current =>
      _Dbs.g.main.isarStatisticsBoorus.getSync(0) ??
      const IsarStatisticsBooru(
        booruSwitches: 0,
        downloaded: 0,
        swiped: 0,
        viewed: 0,
      );

  @override
  void add(StatisticsBooruData data) {
    _Dbs.g.main.writeTxnSync(
      () =>
          _Dbs.g.main.isarStatisticsBoorus.putSync(data as IsarStatisticsBooru),
    );
  }
}

class IsarDailyStatisticsService implements StatisticsDailyService {
  const IsarDailyStatisticsService();

  @override
  StatisticsDailyData get current =>
      _Dbs.g.main.isarDailyStatistics.getSync(0) ??
      IsarDailyStatistics(
        swipedBoth: 0,
        date: DateTime.now(),
        durationMillis: 0,
      );

  @override
  void add(StatisticsDailyData data) {
    _Dbs.g.main.writeTxnSync(
      () =>
          _Dbs.g.main.isarDailyStatistics.putSync(data as IsarDailyStatistics),
    );
  }
}

class IsarBlacklistedDirectoryService implements BlacklistedDirectoryService {
  const IsarBlacklistedDirectoryService();

  @override
  void clear() => _Dbs.g.blacklisted.writeTxnSync(
        () => _Dbs.g.blacklisted.isarBlacklistedDirectorys.clearSync(),
      );

  @override
  void deleteAll(List<String> bucketIds) {
    _Dbs.g.blacklisted.writeTxnSync(() {
      return _Dbs.g.blacklisted.isarBlacklistedDirectorys
          .deleteAllByBucketIdSync(bucketIds);
    });
  }

  @override
  StreamSubscription<void> watch(
    void Function(void) f, [
    bool fire = true,
  ]) =>
      _Dbs.g.blacklisted.isarBlacklistedDirectorys
          .watchLazy(fireImmediately: fire)
          .listen(f);
}

class IsarDirectoryMetadataService implements DirectoryMetadataService {
  const IsarDirectoryMetadataService();

  @override
  SegmentCapability caps(String specialLabel) =>
      _DirectoryMetadataCap(specialLabel, this);

  @override
  DirectoryMetadataData? get(String id) =>
      _Dbs.g.blacklisted.isarDirectoryMetadatas.getByCategoryNameSync(id);

  @override
  Future<bool> canAuth(String id, String reason) async {
    if (!canAuthBiometric) {
      return true;
    }

    if (get(id)?.requireAuth ?? false) {
      final success =
          await LocalAuthentication().authenticate(localizedReason: reason);
      if (!success) {
        return false;
      }
    }

    return true;
  }

  @override
  void add(DirectoryMetadataData data) {
    _Dbs.g.blacklisted.writeTxnSync(
      () {
        _Dbs.g.blacklisted.isarDirectoryMetadatas
            .putByCategoryNameSync(data as IsarDirectoryMetadata);
      },
    );
  }

  @override
  void put(
    String id, {
    required bool blur,
    required bool auth,
    required bool sticky,
  }) {
    if (id.isEmpty) {
      return;
    }

    _Dbs.g.blacklisted.writeTxnSync(
      () {
        _Dbs.g.blacklisted.isarDirectoryMetadatas.putByCategoryNameSync(
          IsarDirectoryMetadata(
            id,
            DateTime.now(),
            blur: blur,
            requireAuth: auth,
            sticky: sticky,
          ),
        );
      },
    );
  }
}

class _DirectoryMetadataCap implements SegmentCapability {
  const _DirectoryMetadataCap(this.specialLabel, this.db);

  final IsarDirectoryMetadataService db;

  final String specialLabel;

  @override
  bool get ignoreButtons => false;

  @override
  Set<SegmentModifier> modifiersFor(String seg) {
    if (seg.isEmpty) {
      return const {};
    }

    if (seg == "Booru" || seg == specialLabel) {
      return const {SegmentModifier.sticky};
    }

    final m = db.get(seg);
    if (m == null) {
      return const {};
    }

    final set = <SegmentModifier>{};

    if (m.blur) {
      set.add(SegmentModifier.blur);
    }

    if (m.requireAuth) {
      set.add(SegmentModifier.auth);
    }

    if (m.sticky) {
      set.add(SegmentModifier.sticky);
    }

    return set;
  }

  @override
  void addModifiers(List<String> segments_, Set<SegmentModifier> m) {
    final segments = segments_
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = _Dbs.g.blacklisted.isarDirectoryMetadatas
        .getAllByCategoryNameSync(segments)
        .indexed
        .map(
          (element) =>
              element.$2 ??
              IsarDirectoryMetadata(
                segments[element.$1],
                DateTime.now(),
                blur: false,
                sticky: false,
                requireAuth: false,
              ),
        );
    final toUpdate = <IsarDirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: true);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: true);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: true);
        }
      }

      toUpdate.add(seg);
    }

    _Dbs.g.blacklisted.writeTxnSync(
      () => _Dbs.g.blacklisted.isarDirectoryMetadatas
          .putAllByCategoryNameSync(toUpdate),
    );
  }

  @override
  void removeModifiers(List<String> segments_, Set<SegmentModifier> m) {
    final segments = segments_
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = _Dbs.g.blacklisted.isarDirectoryMetadatas
        .getAllByCategoryNameSync(segments)
        .indexed
        .map(
          (e) =>
              e.$2 ??
              IsarDirectoryMetadata(
                segments[e.$1],
                DateTime.now(),
                blur: false,
                sticky: false,
                requireAuth: false,
              ),
        );
    final toUpdate = <IsarDirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: false);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: false);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: false);
        }
      }

      toUpdate.add(seg);
    }

    _Dbs.g.blacklisted.writeTxnSync(
      () => _Dbs.g.blacklisted.isarDirectoryMetadatas
          .putAllByCategoryNameSync(toUpdate),
    );
  }
}

class IsarFavoriteFileService implements FavoriteFileService {
  const IsarFavoriteFileService();

  @override
  int get count => _Dbs.g.blacklisted.isarFavoriteFiles.countSync();

  @override
  int get thumbnail => _Dbs.g.blacklisted.isarFavoriteFiles
      .where()
      .sortByTimeDesc()
      .findFirstSync()!
      .id;

  @override
  bool isEmpty() => count == 0;
  @override
  bool isNotEmpty() => !isEmpty();

  @override
  bool isFavorite(int id) =>
      _Dbs.g.blacklisted.isarFavoriteFiles.getSync(id) != null;

  @override
  List<int> getAll({required int offset, required int limit}) =>
      _Dbs.g.blacklisted.isarFavoriteFiles
          .where()
          .offset(offset)
          .limit(limit)
          .findAllSync()
          .map((e) => e.id)
          .toList();

  @override
  void addAll(List<int> ids) {
    _Dbs.g.blacklisted.writeTxnSync(
      () => _Dbs.g.blacklisted.isarFavoriteFiles.putAllSync(
        ids.map((e) => IsarFavoriteFile(e, DateTime.now())).toList(),
      ),
    );
  }

  @override
  void deleteAll(List<int> ids) {
    _Dbs.g.blacklisted.writeTxnSync(
      () => _Dbs.g.blacklisted.isarFavoriteFiles.deleteAllSync(ids),
    );
  }
}

class IsarPinnedThumbnailService implements PinnedThumbnailService {
  const IsarPinnedThumbnailService();

  @override
  void clear() => _Dbs.g.thumbnail!
      .writeTxnSync(() => _Dbs.g.thumbnail!.pinnedThumbnails.clearSync());

  @override
  bool delete(int id) => _Dbs.g.thumbnail!
      .writeTxnSync(() => _Dbs.g.thumbnail!.pinnedThumbnails.deleteSync(id));
}

class IsarThumbnailService implements ThumbnailService {
  const IsarThumbnailService();

  @override
  void clear() {
    _Dbs.g.thumbnail!
        .writeTxnSync(() => _Dbs.g.thumbnail!.isarThumbnails.clearSync());
  }

  @override
  void addAll(List<ThumbId> l) {
    if (_Dbs.g.thumbnail!.isarThumbnails.countSync() >= 3000) {
      final List<int> toDelete = _Dbs.g.thumbnail!.writeTxnSync(() {
        final toDelete = _Dbs.g.thumbnail!.isarThumbnails
            .where()
            .sortByUpdatedAt()
            .limit(l.length)
            .findAllSync()
            .map((e) => e.id)
            .toList();

        if (toDelete.isEmpty) {
          return [];
        }

        _Dbs.g.thumbnail!.isarThumbnails.deleteAllSync(toDelete);

        return toDelete;
      });

      PlatformFunctions.deleteCachedThumbs(toDelete);
    }

    _Dbs.g.thumbnail!.writeTxnSync(() {
      _Dbs.g.thumbnail!.isarThumbnails.putAllSync(
        l
            .map(
              (e) =>
                  IsarThumbnail(e.id, DateTime.now(), e.path, e.differenceHash),
            )
            .toList(),
      );
    });
  }
}

class IsarChapterSettingsService implements ChaptersSettingsService {
  const IsarChapterSettingsService();

  @override
  ChaptersSettingsData get current =>
      _Dbs.g.anime.isarChapterSettings.getSync(0) ??
      const IsarChapterSettings(hideRead: false);

  @override
  void add(ChaptersSettingsData data) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarChapterSettings.putSync(
        data as IsarChapterSettings,
      ),
    );
  }

  @override
  StreamSubscription<ChaptersSettingsData?> watch(
    void Function(ChaptersSettingsData? c) f,
  ) {
    return _Dbs.g.anime.isarChapterSettings.watchObject(0).listen(f);
  }
}

class IsarCompactMangaDataService implements CompactMangaDataService {
  const IsarCompactMangaDataService();

  @override
  void addAll(List<CompactMangaData> l) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarCompactMangaDatas
          .putAllByMangaIdSiteSync(l as List<IsarCompactMangaData>),
    );
  }

  @override
  CompactMangaData? get(String mangaId, MangaMeta site) {
    return _Dbs.g.anime.isarCompactMangaDatas
        .getByMangaIdSiteSync(mangaId, site);
  }
}

class IsarPinnedMangaService implements PinnedMangaService {
  const IsarPinnedMangaService();

  @override
  int get count => _Dbs.g.anime.isarPinnedMangas.countSync();

  @override
  bool exist(String mangaId, MangaMeta site) {
    return _Dbs.g.anime.isarPinnedMangas.getByMangaIdSiteSync(mangaId, site) !=
        null;
  }

  @override
  List<PinnedManga> getAll(int limit) {
    if (limit.isNegative) {
      return _Dbs.g.anime.isarPinnedMangas.where().findAllSync();
    }

    return _Dbs.g.anime.isarPinnedMangas.where().limit(limit).findAllSync();
  }

  @override
  void addAll(List<MangaEntry> l, [bool saveId = false]) {
    if (l.isEmpty) {
      return;
    }

    if (saveId) {
      _Dbs.g.anime.writeTxnSync(
        () => _Dbs.g.anime.isarPinnedMangas.putAllSync(
          l
              .map(
                (e) => IsarPinnedManga(
                  mangaId: e.id.toString(),
                  site: e.site,
                  thumbUrl: e.thumbUrl,
                  title: e.title,
                ),
              )
              .toList(),
        ),
      );

      return;
    }

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarPinnedMangas
          .putAllByMangaIdSiteSync(l as List<IsarPinnedManga>),
    );
  }

  // static void deleteAll(List<int> ids) {
  //   if (ids.isEmpty) {
  //     return;
  //   }

  //   Dbs.g.anime.writeTxnSync(
  //     () => Dbs.g.anime.pinnedMangas.deleteAll(ids),
  //   );
  // }

  @override
  void deleteAll(List<(MangaId, MangaMeta)> ids) {
    if (ids.isEmpty) {
      return;
    }

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarPinnedMangas.deleteAllByMangaIdSiteSync(
        ids.map((e) => e.$1.toString()).toList(),
        ids.map((e) => e.$2).toList(),
      ),
    );
  }

  @override
  void deleteSingle(String mangaId, MangaMeta site) {
    _Dbs.g.anime.writeTxnSync(
      () =>
          _Dbs.g.anime.isarPinnedMangas.deleteByMangaIdSiteSync(mangaId, site),
    );
  }

  @override
  StreamSubscription<void> watch(void Function(void) f) =>
      _Dbs.g.anime.isarPinnedMangas.watchLazy().listen(f);
}

class IsarReadMangaChapterService implements ReadMangaChaptersService {
  const IsarReadMangaChapterService();

  @override
  int get countDistinct => _Dbs.g.anime.isarReadMangaChapters
      .where(distinct: true)
      .distinctBySiteMangaId()
      .countSync();

  @override
  ReadMangaChapterData? firstForId(String siteMangaId) {
    return _Dbs.g.anime.isarReadMangaChapters
        .filter()
        .siteMangaIdEqualTo(siteMangaId)
        .sortByLastUpdatedDesc()
        .findFirstSync();
  }

  @override
  List<ReadMangaChapterData> lastRead(int limit) {
    if (limit == 0) {
      return const [];
    }

    if (limit.isNegative) {
      return _Dbs.g.anime.isarReadMangaChapters
          .where()
          .sortByLastUpdatedDesc()
          .distinctBySiteMangaId()
          .findAllSync();
    }

    return _Dbs.g.anime.isarReadMangaChapters
        .where()
        .sortByLastUpdatedDesc()
        .distinctBySiteMangaId()
        .limit(limit)
        .findAllSync();
  }

  @override
  void touch({
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    final e = _Dbs.g.anime.isarReadMangaChapters
        .getBySiteMangaIdChapterIdSync(siteMangaId, chapterId);
    if (e == null) {
      return;
    }

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarReadMangaChapters.putBySiteMangaIdChapterIdSync(
        IsarReadMangaChapter(
          siteMangaId: siteMangaId,
          chapterId: chapterId,
          chapterName: chapterName,
          chapterNumber: chapterNumber,
          chapterProgress: e.chapterProgress,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  @override
  void setProgress(
    int progress, {
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarReadMangaChapters.putBySiteMangaIdChapterIdSync(
        IsarReadMangaChapter(
          siteMangaId: siteMangaId,
          chapterId: chapterId,
          chapterNumber: chapterNumber,
          chapterName: chapterName,
          chapterProgress: progress,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  @override
  void delete({
    required String siteMangaId,
    required String chapterId,
  }) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarReadMangaChapters
          .deleteBySiteMangaIdChapterIdSync(siteMangaId, chapterId),
    );
  }

  @override
  void deleteAllById(String siteMangaId, bool silent) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarReadMangaChapters
          .filter()
          .siteMangaIdEqualTo(siteMangaId)
          .deleteAllSync(),
      silent: silent,
    );
  }

  @override
  int? progress({
    required String siteMangaId,
    required String chapterId,
  }) {
    final p = _Dbs.g.anime.isarReadMangaChapters
        .getBySiteMangaIdChapterIdSync(siteMangaId, chapterId)
        ?.chapterProgress;

    if (p?.isNegative ?? false) {
      delete(siteMangaId: siteMangaId, chapterId: chapterId);

      return null;
    }

    return p;
  }

  @override
  Future<void> launchReader(
    BuildContext context,
    ReaderData data, {
    bool addNextChapterButton = false,
    bool replace = false,
  }) {
    touch(
      siteMangaId: data.mangaId.toString(),
      chapterId: data.chapterId,
      chapterName: data.chapterName,
      chapterNumber: data.chapterNumber,
    );

    final p = progress(
      siteMangaId: data.mangaId.toString(),
      chapterId: data.chapterId,
    );

    final nextChapterKey = GlobalKey<SkipChapterButtonState>();
    final prevChaterKey = GlobalKey<SkipChapterButtonState>();

    final route = MaterialPageRoute<void>(
      builder: (context) {
        return WrapFutureRestartable(
          newStatus: () {
            return data.api.imagesForChapter(MangaStringId(data.chapterId));
          },
          builder: (context, chapters) {
            return GlueProvider.empty(
              context,
              child: ImageView(
                registerNotifiers: !addNextChapterButton
                    ? null
                    : (child) => MangaReaderNotifier(
                          data: data,
                          child: child,
                        ),
                ignoreLoadingBuilder: true,
                download: (i) {
                  final image = chapters[i];

                  Downloader.g.add(
                    DownloadFile.d(
                      name:
                          "$i / ${image.maxPages} - ${data.chapterId}.${image.url.split(".").last}",
                      url: image.url,
                      thumbUrl: image.url,
                      site: data.mangaTitle,
                    ),
                    SettingsService.currentData,
                  );
                },
                onRightSwitchPageEnd: addNextChapterButton
                    ? () {
                        nextChapterKey.currentState?.findAndLaunchNext();
                      }
                    : null,
                onLeftSwitchPageEnd: addNextChapterButton
                    ? () {
                        prevChaterKey.currentState?.findAndLaunchNext();
                      }
                    : null,
                pageChange: (state) {
                  setProgress(
                    state.currentPage + 1,
                    chapterName: data.chapterName,
                    chapterNumber: data.chapterNumber,
                    siteMangaId: data.mangaId.toString(),
                    chapterId: data.chapterId,
                  );

                  data.onNextPage(
                    state.currentPage,
                    chapters[state.currentPage],
                  );
                },
                cellCount: chapters.length,
                scrollUntill: (_) {},
                startingCell: p != null ? p - 1 : 0,
                onExit: () {},
                getCell: (context, i) => chapters[i].content(context),
                onNearEnd: null,
              ),
            );
          },
        );
      },
    );

    if (replace) {
      return Navigator.of(context, rootNavigator: true).pushReplacement(
        route,
      );
    } else {
      return Navigator.of(context, rootNavigator: true).push(
        route,
      );
    }
  }

  @override
  StreamSubscription<void> watch(void Function(void) f) =>
      _Dbs.g.anime.isarReadMangaChapters.watchLazy().listen(f);

  @override
  StreamSubscription<int> watchReading(void Function(int) f) =>
      _Dbs.g.anime.isarReadMangaChapters
          .watchLazy(fireImmediately: true)
          .map((event) => countDistinct)
          .listen(f);

  @override
  StreamSubscription<int?> watchChapter(
    void Function(int?) f, {
    required String siteMangaId,
    required String chapterId,
  }) {
    return _Dbs.g.anime.isarReadMangaChapters
        .where()
        .siteMangaIdChapterIdEqualTo(siteMangaId, chapterId)
        .watch()
        .map((event) {
      if (event.isEmpty) {
        return null;
      }

      return event.first.chapterProgress;
    }).listen(f);
  }
}

class IsarSavedMangaChaptersService implements SavedMangaChaptersService {
  const IsarSavedMangaChaptersService();

  @override
  void clear(String mangaId, MangaMeta site) {
    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedMangaChapters
          .deleteByMangaIdSiteSync(mangaId, site),
    );
  }

  @override
  void add(
    String mangaId,
    MangaMeta site,
    List<MangaChapter> chapters,
    int page,
  ) {
    final prev =
        _Dbs.g.anime.isarSavedMangaChapters.getByMangaIdSiteSync(mangaId, site);

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarSavedMangaChapters.putByMangaIdSiteSync(
        IsarSavedMangaChapters(
          page: page,
          chapters: (prev?.chapters ?? const []) +
              (chapters as List<IsarMangaChapter>),
          mangaId: mangaId,
          site: site,
        ),
      ),
    );
  }

  @override
  int count(String mangaId, MangaMeta site) {
    return _Dbs.g.anime.isarSavedMangaChapters
        .where()
        .mangaIdSiteEqualTo(mangaId, site)
        .countSync();
  }

  @override
  (List<MangaChapter>, int)? get(
    String mangaId,
    MangaMeta site,
    ChaptersSettingsData? settings,
    ReadMangaChaptersService readManga,
  ) {
    final prev =
        _Dbs.g.anime.isarSavedMangaChapters.getByMangaIdSiteSync(mangaId, site);
    if (prev == null) {
      return null;
    }

    if (settings != null && settings.hideRead) {
      return (
        prev.chapters.where((element) {
          final p = readManga.progress(
            siteMangaId: mangaId,
            chapterId: element.id,
          );
          if (p == null) {
            return true;
          }

          return p != element.pages;
        }).toList(),
        prev.page
      );
    }

    return (prev.chapters, prev.page);
  }
}

class IsarFilesGridSettingsData implements WatchableGridSettingsData {
  const IsarFilesGridSettingsData();

  @override
  GridSettingsData get current =>
      _Dbs.g.main.isarGridSettingsFiles.getSync(0) ??
      IsarGridSettingsFiles(
        aspectRatio: GridAspectRatio.one,
        columns: Platform.isAndroid ? GridColumn.three : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: true,
      );

  @override
  set current(GridSettingsData d) {
    _Dbs.g.main.writeTxnSync(
      () =>
          _Dbs.g.main.isarGridSettingsFiles.putSync(d as IsarGridSettingsFiles),
    );
  }

  @override
  StreamSubscription<GridSettingsData?> watch(
    void Function(GridSettingsData? p1) f,
  ) =>
      _Dbs.g.main.isarGridSettingsFiles.watchObject(0).listen(f);
}

class IsarFavoritesGridSettingsData implements WatchableGridSettingsData {
  const IsarFavoritesGridSettingsData();

  @override
  GridSettingsData get current =>
      _Dbs.g.main.isarGridSettingsFavorites.getSync(0) ??
      const IsarGridSettingsFavorites(
        aspectRatio: GridAspectRatio.one,
        columns: GridColumn.five,
        layoutType: GridLayoutType.gridQuilted,
        hideName: true,
      );

  @override
  set current(GridSettingsData d) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarGridSettingsFavorites
          .putSync(d as IsarGridSettingsFavorites),
    );
  }

  @override
  StreamSubscription<GridSettingsData?> watch(
    void Function(GridSettingsData? p1) f,
  ) =>
      _Dbs.g.main.isarGridSettingsFavorites.watchObject(0).listen(f);
}

class IsarDirectoriesGridSettingsData implements WatchableGridSettingsData {
  const IsarDirectoriesGridSettingsData();

  @override
  GridSettingsData get current =>
      _Dbs.g.main.isarGridSettingsDirectories.getSync(0) ??
      IsarGridSettingsDirectories(
        aspectRatio: GridAspectRatio.oneTwo,
        columns: Platform.isAndroid ? GridColumn.three : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  set current(GridSettingsData d) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarGridSettingsDirectories
          .putSync(d as IsarGridSettingsDirectories),
    );
  }

  @override
  StreamSubscription<GridSettingsData?> watch(
    void Function(GridSettingsData? p1) f,
  ) =>
      _Dbs.g.main.isarGridSettingsDirectories.watchObject(0).listen(f);
}

class IsarBooruGridSettingsData implements WatchableGridSettingsData {
  const IsarBooruGridSettingsData();

  @override
  GridSettingsData get current =>
      _Dbs.g.main.isarGridSettingsBoorus.getSync(0) ??
      IsarGridSettingsBooru(
        aspectRatio: GridAspectRatio.one,
        columns: Platform.isAndroid ? GridColumn.two : GridColumn.six,
        layoutType: GridLayoutType.gridQuilted,
        hideName: true,
      );

  @override
  set current(GridSettingsData d) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarGridSettingsBoorus
          .putSync(d as IsarGridSettingsBooru),
    );
  }

  @override
  StreamSubscription<GridSettingsData?> watch(
    void Function(GridSettingsData? p1) f,
  ) =>
      _Dbs.g.main.isarGridSettingsBoorus.watchObject(0).listen(f);
}

class IsarAnimeDiscoveryGridSettingsData implements WatchableGridSettingsData {
  const IsarAnimeDiscoveryGridSettingsData();

  @override
  GridSettingsData get current =>
      _Dbs.g.main.isarGridSettingsAnimeDiscoverys.getSync(0) ??
      IsarGridSettingsAnimeDiscovery(
        aspectRatio: GridAspectRatio.one,
        columns: Platform.isAndroid ? GridColumn.three : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: true,
      );

  @override
  set current(GridSettingsData d) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarGridSettingsAnimeDiscoverys
          .putSync(d as IsarGridSettingsAnimeDiscovery),
    );
  }

  @override
  StreamSubscription<GridSettingsData?> watch(
    void Function(GridSettingsData? p1) f,
  ) =>
      _Dbs.g.main.isarGridSettingsAnimeDiscoverys.watchObject(0).listen(f);
}

class IsarGridSettinsService implements GridSettinsService {
  const IsarGridSettinsService();

  @override
  WatchableGridSettingsData get animeDiscovery =>
      const IsarAnimeDiscoveryGridSettingsData();

  @override
  WatchableGridSettingsData get booru => const IsarBooruGridSettingsData();

  @override
  WatchableGridSettingsData get directories =>
      const IsarDirectoriesGridSettingsData();

  @override
  WatchableGridSettingsData get favoritePosts =>
      const IsarFavoritesGridSettingsData();

  @override
  WatchableGridSettingsData get files => const IsarFilesGridSettingsData();
}
