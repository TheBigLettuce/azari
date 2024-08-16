// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:async/async.dart";
import "package:azari/init_main/app_info.dart";
import "package:azari/src/db/services/impl/isar/schemas/anime/backlog_anime_entry.dart";
import "package:azari/src/db/services/impl/isar/schemas/anime/newest_anime.dart";
import "package:azari/src/db/services/impl/isar/schemas/anime/saved_anime_characters.dart";
import "package:azari/src/db/services/impl/isar/schemas/anime/watched_anime_entry.dart";
import "package:azari/src/db/services/impl/isar/schemas/anime/watching_anime_entry.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:azari/src/db/services/impl/isar/schemas/booru/visited_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/directory_metadata.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/directory_tags.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/favorite_file.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/pinned_thumbnail.dart";
import "package:azari/src/db/services/impl/isar/schemas/gallery/thumbnail.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_settings/anime_discovery.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_settings/booru.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_settings/directories.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_settings/favorites.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_settings/files.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/grid_booru_paging.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/grid_time.dart";
import "package:azari/src/db/services/impl/isar/schemas/grid_state/updates_available.dart";
import "package:azari/src/db/services/impl/isar/schemas/manga/chapters_settings.dart";
import "package:azari/src/db/services/impl/isar/schemas/manga/compact_manga_data.dart";
import "package:azari/src/db/services/impl/isar/schemas/manga/pinned_manga.dart";
import "package:azari/src/db/services/impl/isar/schemas/manga/read_manga_chapter.dart";
import "package:azari/src/db/services/impl/isar/schemas/manga/saved_manga_chapters.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/misc_settings.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/settings.dart";
import "package:azari/src/db/services/impl/isar/schemas/settings/video_settings.dart";
import "package:azari/src/db/services/impl/isar/schemas/statistics/daily_statistics.dart";
import "package:azari/src/db/services/impl/isar/schemas/statistics/statistics_booru.dart";
import "package:azari/src/db/services/impl/isar/schemas/statistics/statistics_gallery.dart";
import "package:azari/src/db/services/impl/isar/schemas/statistics/statistics_general.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/local_tag_dictionary.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/local_tags.dart";
import "package:azari/src/db/services/impl/isar/schemas/tags/tags.dart";
import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/net/manga/manga_api.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/plugs/gallery_management_api.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:isar/isar.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;

part "foundation/dbs.dart";
part "foundation/initalize_db.dart";
part "settings.dart";

final _futures = <(int, AnimeMetadata), Future<void>>{};

abstract class IsarGridSettingsData implements GridSettingsData {
  const IsarGridSettingsData({
    required this.aspectRatio,
    required this.columns,
    required this.hideName,
    required this.layoutType,
  });

  @override
  @enumerated
  final GridAspectRatio aspectRatio;

  @override
  @enumerated
  final GridColumn columns;

  @override
  final bool hideName;

  @override
  @enumerated
  final GridLayoutType layoutType;
}

class IsarCurrentBooruSource extends GridPostSource
    with GridPostSourceRefreshNext {
  IsarCurrentBooruSource({
    required this.safeMode_,
    required Isar db,
    required this.api,
    required this.excluded,
    required this.entry,
    required this.tags,
    required this.filters,
  })  : backingStorage = _IsarPostsStorage(db, closeOnDestroy: false),
        updatesAvailable =
            IsarUpdatesAvailableImpl(db, api, safeMode_, () => tags);

  @override
  final BooruAPI api;
  @override
  final BooruTagging excluded;
  @override
  final PagingEntry entry;

  final SafeMode Function() safeMode_;

  @override
  SafeMode get safeMode => safeMode_();

  @override
  final _IsarPostsStorage backingStorage;

  @override
  final List<FilterFnc<Post>> filters;

  @override
  final IsarUpdatesAvailableImpl updatesAvailable;

  @override
  List<Post> get lastFive => backingStorage._collection
      .where()
      .ratingEqualTo(PostRating.general)
      .sortById()
      .limit(5)
      .findAllSync();

  @override
  Post? get currentlyLast =>
      backingStorage._collection.where().sortById().limit(1).findFirstSync();

  @override
  bool get hasNext => true;

  @override
  String tags;

  @override
  void destroy() {
    updatesAvailable.dispose();
    backingStorage.destroy();
    progress.close();
  }
}

class IsarUpdatesAvailableImpl implements UpdatesAvailable {
  IsarUpdatesAvailableImpl(this.db, this.api, this.safeMode_, this.tags_) {
    _timeTicker =
        Stream<void>.periodic(const Duration(minutes: 15)).listen((_) {
      tryRefreshIfNeeded(true);
    });

    // if (_isAfterNow(_current.time)) {
    //   tryRefreshIfNeeded();
    // }
  }

  final Isar db;
  final BooruAPI api;
  final SafeMode Function() safeMode_;
  final String Function() tags_;

  final _events = StreamController<UpdatesAvailableStatus>.broadcast();
  late final StreamSubscription<void> _timeTicker;

  Future<void>? _future;

  void dispose() {
    _events.close();
    _future?.ignore();
    _timeTicker.cancel();
  }

  IsarUpdatesAvailable get _current =>
      db.isarUpdatesAvailables.getSync(0) ??
      IsarUpdatesAvailable(postCount: -1, time: DateTime.now());

  bool _isAfterNow(DateTime time) =>
      DateTime.now().isAfter(time.add(const Duration(minutes: 5)));

  @override
  bool tryRefreshIfNeeded([bool force = false]) {
    if (_future != null) {
      return true;
    }

    final u = _current;

    if (force || u.postCount == -1 || _isAfterNow(u.time)) {
      _events.add(const UpdatesAvailableStatus(false, true));

      _future = api.totalPosts(tags_(), safeMode_()).then((count) {
        if (db.isOpen) {
          db.writeTxnSync(() {
            db.isarUpdatesAvailables.putSync(
              IsarUpdatesAvailable(postCount: count, time: DateTime.now()),
            );
          });
        }

        return null;
      }).onError((e, trace) {
        Logger.root.warning("tryRefreshIfNeeded", e, trace);
        return null;
      }).whenComplete(() {
        if (!_events.isClosed) {
          _events.add(
            UpdatesAvailableStatus(_current.postCount > u.postCount, false),
          );
        }
        _future = null;
      });

      return true;
    } else {
      return false;
    }
  }

  @override
  void setCount(int count) {
    db.writeTxnSync(() {
      db.isarUpdatesAvailables.putSync(
        IsarUpdatesAvailable(postCount: count, time: DateTime.now()),
      );
    });
  }

  @override
  StreamSubscription<UpdatesAvailableStatus> watch(
    void Function(UpdatesAvailableStatus) f,
  ) =>
      _events.stream.listen(f);
}

class _IsarCollectionIterator<T> implements Iterator<T> {
  _IsarCollectionIterator(
    this.collection, {
    required this.reversed,
    this.loader,
  });

  final IsarCollection<T> collection;
  final bool reversed;

  final QueryBuilder<T, T, QAfterLimit> Function(
    QueryBuilder<T, T, QWhere> q,
    int offset,
    int limit,
  )? loader;

  final _storage = BufferedStorage<T>();

  @override
  T get current => _storage.current;

  QueryBuilder<T, T, QAfterLimit> defaultLoader(
    QueryBuilder<T, T, QWhere> q,
    int offset,
    int limit,
  ) =>
      q.offset(offset).limit(limit);

  Iterable<T> _nextItems(int offset, int limit) => (loader ?? defaultLoader)(
        collection.where(sort: reversed ? Sort.asc : Sort.desc),
        offset,
        limit,
      ).findAllSync();

  @override
  bool moveNext() => _storage.moveNext(_nextItems);
}

class _IsarCollectionReverseIterable<V> extends Iterable<V> {
  const _IsarCollectionReverseIterable(this.iterator);

  @override
  final Iterator<V> iterator;
}

class _IsarPostsStorage extends SourceStorage<int, Post> {
  _IsarPostsStorage(
    this.db, {
    required this.closeOnDestroy,
  });

  final Isar db;
  final bool closeOnDestroy;

  IsarCollection<PostIsar> get _collection => db.postIsars;

  @override
  Iterable<Post> get reversed => _IsarCollectionReverseIterable(
        _IsarCollectionIterator<PostIsar>(_collection, reversed: true),
      );

  @override
  int get count => _collection.countSync();

  @override
  Iterator<Post> get iterator =>
      _IsarCollectionIterator<PostIsar>(_collection, reversed: false);

  @override
  void add(Post e, [bool silent = true]) => db.writeTxnSync(
        () => _collection
            .putByIdBooruSync(e is PostIsar ? e : PostIsar.copyTo([e])[0]),
        silent: silent,
      );

  @override
  void addAll(Iterable<Post> l, [bool silent = false]) {
    final List<PostIsar> res;
    if (!silent && l.isEmpty) {
      final first = _collection.where().limit(1).findFirstSync();
      if (first != null) {
        res = [first];
      } else {
        res = [];
      }
    } else {
      res = l is List<PostIsar> ? l : PostIsar.copyTo(l);
    }

    db.writeTxnSync(
      () => _collection.putAllByIdBooruSync(res),
      silent: silent,
    );
  }

  @override
  void clear([bool silent = false]) => db.writeTxnSync(
        () => _collection.clearSync(),
        silent: silent,
      );

  @override
  Post? get(int idx) => _collection.getSync(idx + 1);

  @override
  List<Post> removeAll(Iterable<int> idx, [bool silent = false]) {
    final k = idx.map((e) => e + 1).toList();

    final ret = _collection.getAllSync(k);
    db.writeTxnSync(
      () => _collection.deleteAllSync(k),
      silent: silent,
    );

    return ret.map((e) => e != null).cast<Post>().toList();
  }

  @override
  void destroy([bool delete = false]) =>
      closeOnDestroy ? db.close(deleteFromDisk: delete) : null;

  @override
  Post operator [](int index) => get(index)!;

  @override
  void operator []=(int index, Post value) => addAll([value]);

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _collection.watchLazy(fireImmediately: fire).map((_) => count).listen(f);

  @override
  Iterable<Post> trySorted(SortingMode sort) => this;
}

class IsarSourceStorage<K, V, CollectionType extends V>
    extends SourceStorage<K, V> {
  IsarSourceStorage(
    this.db, {
    required this.sortFnc,
    required this.txPut,
    required this.txGet,
    required this.txRemove,
  });

  final Isar db;
  final void Function(IsarCollection<CollectionType> c, Iterable<V> values)
      txPut;
  final V? Function(IsarCollection<CollectionType> c, K key) txGet;
  final List<V> Function(IsarCollection<CollectionType> c, Iterable<K> keys)
      txRemove;

  final _IsarCollectionIterator<V> Function(SortingMode sort)? sortFnc;

  IsarCollection<CollectionType> get _collection =>
      db.collection<CollectionType>();

  @override
  Iterable<V> get reversed => _IsarCollectionReverseIterable(
        _IsarCollectionIterator(_collection, reversed: true),
      );

  @override
  int get count => _collection.countSync();

  @override
  Iterator<V> get iterator =>
      _IsarCollectionIterator(_collection, reversed: false);

  @override
  Iterable<V> trySorted(SortingMode sort) =>
      sortFnc == null ? this : _IsarCollectionReverseIterable(sortFnc!(sort));

  @override
  void add(V e, [bool silent = true]) =>
      db.writeTxnSync(() => txPut(_collection, [e]), silent: silent);

  @override
  void addAll(Iterable<V> l, [bool silent = false]) =>
      db.writeTxnSync(() => txPut(_collection, l), silent: silent);

  @override
  void clear([bool silent = false]) => db.writeTxnSync(
        () => _collection.clearSync(),
        silent: silent,
      );

  @override
  V? get(K idx) => txGet(_collection, idx);

  @override
  List<V> removeAll(Iterable<K> idx, [bool silent = false]) => db.writeTxnSync(
        () => txRemove(_collection, idx),
        silent: silent,
      );

  @override
  void destroy([bool delete = false]) => db.close(deleteFromDisk: delete);

  @override
  V operator [](K index) => get(index)!;

  @override
  void operator []=(K index, V value) =>
      db.writeTxnSync(() => txPut(_collection, [value]));

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _collection.watchLazy(fireImmediately: fire).map((_) => count).listen(f);
}

class IsarSavedAnimeCharatersService implements SavedAnimeCharactersService {
  const IsarSavedAnimeCharatersService();

  Isar get db => _Dbs.g.anime;

  IsarCollection<IsarSavedAnimeCharacters> get collection =>
      db.isarSavedAnimeCharacters;

  @override
  List<AnimeCharacter> load(int id, AnimeMetadata site) =>
      collection.getByIdSiteSync(id, site)?.characters ?? const [];

  @override
  bool addAsync(AnimeEntryData entry, AnimeAPI api) {
    if (_futures.containsKey((entry.id, entry.site))) {
      return true;
    }

    _futures[(entry.id, entry.site)] = api.characters(entry)
      ..then((value) {
        db.writeTxnSync(
          () => collection.putByIdSiteSync(
            IsarSavedAnimeCharacters(
              characters: value.cast(),
              id: entry.id,
              site: entry.site,
              isarId: null,
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
    var e = collection.getByIdSiteSync(id, site)?.isarId;
    e ??= db.writeTxnSync(
      () => collection.putByIdSiteSync(
        IsarSavedAnimeCharacters(
          characters: const [],
          id: id,
          site: site,
          isarId: null,
        ),
      ),
    );

    return collection
        .where()
        .idSiteEqualTo(id, site)
        .watchLazy(fireImmediately: fire)
        .map(
          (event) => collection.getByIdSiteSync(id, site)?.characters,
        )
        .listen(f);
  }
}

class IsarLocalTagDictionaryService implements LocalTagDictionaryService {
  const IsarLocalTagDictionaryService();

  Isar get db => _Dbs.g.localTags;

  IsarCollection<IsarLocalTagDictionary> get collection =>
      db.isarLocalTagDictionarys;

  @override
  void add(List<String> tags) {
    db.writeTxnSync(
      () => collection.putAllSync(
        tags
            .map(
              (e) => IsarLocalTagDictionary(
                e,
                (collection.getByTagSync(e)?.frequency ?? 0) + 1,
                isarId: null,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Future<List<BooruTag>> complete(String string) async {
    final result = collection
        .filter()
        .tagContains(string)
        .sortByFrequencyDesc()
        .limit(10)
        .findAllSync();

    return result.map((e) => BooruTag(e.tag, e.frequency)).toList();
  }
}

enum _IsarAnimeEntriesType {
  backlog,
  watching,
  watched;
}

class IsarSavedAnimeEntriesService implements SavedAnimeEntriesService {
  IsarSavedAnimeEntriesService();

  @override
  AnimeEntriesSource backlog =
      IsarAnimeEntriesSource(_IsarAnimeEntriesType.backlog);

  @override
  AnimeEntriesSource watching =
      IsarAnimeEntriesSource(_IsarAnimeEntriesType.watching);

  @override
  AnimeEntriesSource watched =
      IsarAnimeEntriesSource(_IsarAnimeEntriesType.watched);
}

class IsarAnimeEntriesSource implements AnimeEntriesSource {
  IsarAnimeEntriesSource(this.type)
      : backingStorage = switch (type) {
          _IsarAnimeEntriesType.backlog =>
            IsarBacklogAnimeEntriesStorage(_Dbs.g.anime),
          _IsarAnimeEntriesType.watching =>
            IsarWatchingAnimeEntriesStorage(_Dbs.g.anime),
          _IsarAnimeEntriesType.watched =>
            IsarWatchedAnimeEntriesStorage(_Dbs.g.anime),
        };

  final _IsarAnimeEntriesType type;

  @override
  bool get hasNext => false;

  Isar get db => _Dbs.g.anime;

  @override
  final SourceStorage<(int, AnimeMetadata), AnimeEntryData> backingStorage;

  @override
  final ClosableRefreshProgress progress =
      ClosableRefreshProgress(canLoadMore: false);

  @override
  void update(AnimeEntryData e) {
    final prev = backingStorage.get((e.id, e.site));

    if (prev == null) {
      return;
    }

    backingStorage.add(e);
  }

  @override
  Future<int> clearRefresh() => Future.value(backingStorage.count);

  @override
  Future<int> next() => clearRefresh();

  @override
  void destroy() {
    progress.close();
  }

  @override
  StreamSubscription<AnimeEntryData?> watchSingle(
    int id,
    AnimeMetadata site,
    void Function(AnimeEntryData? p1) f, [
    bool fire = false,
  ]) =>
      switch (type) {
        _IsarAnimeEntriesType.backlog => db.isarBacklogAnimeEntrys
            .where()
            .siteIdEqualTo(site, id)
            .watch()
            .map((e) => e.firstOrNull)
            .listen(f),
        _IsarAnimeEntriesType.watching => db.isarWatchingAnimeEntrys
            .where()
            .siteIdEqualTo(site, id)
            .watch()
            .map((e) => e.firstOrNull)
            .listen(f),
        _IsarAnimeEntriesType.watched => db.isarWatchedAnimeEntrys
            .where()
            .siteIdEqualTo(site, id)
            .watch()
            .map((e) => e.firstOrNull)
            .listen(f),
      };
}

class IsarBacklogAnimeEntriesStorage
    extends _IsarCollectionStorage<(int, AnimeMetadata), IsarBacklogAnimeEntry>
    implements SourceStorage<(int, AnimeMetadata), IsarBacklogAnimeEntry> {
  IsarBacklogAnimeEntriesStorage(
    super.db, {
    super.closeOnDestroy = false,
  });

  @override
  IsarCollection<IsarBacklogAnimeEntry> get _collection =>
      db.isarBacklogAnimeEntrys;

  @override
  IsarBacklogAnimeEntry? get((int, AnimeMetadata) idx) =>
      _collection.getBySiteIdSync(idx.$2, idx.$1);

  @override
  void add(AnimeEntryData e, [bool silent = false]) {
    db.writeTxnSync(
      () => db.isarWatchingAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => db.isarWatchedAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => _collection.putBySiteIdSync(
        e is IsarBacklogAnimeEntry ? e : e.copySuperBacklog(),
      ),
    );
  }

  @override
  void addAll(Iterable<AnimeEntryData> l, [bool silent = false]) {
    final e = l
        .map((e) => e is IsarBacklogAnimeEntry ? e : e.copySuperBacklog())
        .toList();

    final (ids, sites) = _foldTulpeListFnc(e, (e) => (e.id, e.site));

    db.writeTxnSync(
      () => db.isarWatchingAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(
      () => db.isarWatchedAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(() => _collection.putAllBySiteIdSync(e));
  }

  @override
  List<IsarBacklogAnimeEntry> removeAll(
    Iterable<(int, AnimeMetadata)> idx, [
    bool silent = false,
  ]) {
    final (ids, sites) = _foldTulpeList(idx);

    final ret = _collection.getAllBySiteIdSync(sites, ids);

    db.writeTxnSync(
      () => _collection.deleteAllBySiteIdSync(
        sites,
        ids,
      ),
    );

    return ret.where((e) => e != null).cast<IsarBacklogAnimeEntry>().toList();
  }
}

class IsarWatchedAnimeEntriesStorage
    extends _IsarCollectionStorage<(int, AnimeMetadata), IsarWatchedAnimeEntry>
    implements SourceStorage<(int, AnimeMetadata), IsarWatchedAnimeEntry> {
  IsarWatchedAnimeEntriesStorage(
    super.db, {
    super.closeOnDestroy = false,
  });

  @override
  IsarCollection<IsarWatchedAnimeEntry> get _collection =>
      db.isarWatchedAnimeEntrys;

  @override
  IsarWatchedAnimeEntry? get((int, AnimeMetadata) idx) =>
      _collection.getBySiteIdSync(idx.$2, idx.$1);

  @override
  void add(AnimeEntryData e, [bool silent = false]) {
    db.writeTxnSync(
      () => db.isarBacklogAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => db.isarWatchingAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => _collection.putBySiteIdSync(
        e is IsarWatchedAnimeEntry ? e : e.copySuperWatched(),
      ),
    );
  }

  @override
  void addAll(Iterable<AnimeEntryData> l, [bool silent = false]) {
    final e = l
        .map((e) => e is IsarWatchedAnimeEntry ? e : e.copySuperWatched())
        .toList();

    final (ids, sites) = _foldTulpeListFnc(e, (e) => (e.id, e.site));

    db.writeTxnSync(
      () => db.isarBacklogAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(
      () => db.isarWatchingAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(() => _collection.putAllBySiteIdSync(e));
  }

  @override
  List<IsarWatchedAnimeEntry> removeAll(
    Iterable<(int, AnimeMetadata)> idx, [
    bool silent = false,
  ]) {
    final (ids, sites) = _foldTulpeList(idx);

    final ret = _collection.getAllBySiteIdSync(sites, ids);

    db.writeTxnSync(
      () => _collection.deleteAllBySiteIdSync(
        sites,
        ids,
      ),
    );

    return ret.where((e) => e != null).cast<IsarWatchedAnimeEntry>().toList();
  }
}

class IsarWatchingAnimeEntriesStorage
    extends _IsarCollectionStorage<(int, AnimeMetadata), IsarWatchingAnimeEntry>
    implements SourceStorage<(int, AnimeMetadata), IsarWatchingAnimeEntry> {
  IsarWatchingAnimeEntriesStorage(
    super.db, {
    super.closeOnDestroy = false,
  });

  @override
  IsarCollection<IsarWatchingAnimeEntry> get _collection =>
      db.isarWatchingAnimeEntrys;

  @override
  IsarWatchingAnimeEntry? get((int, AnimeMetadata) idx) =>
      _collection.getBySiteIdSync(idx.$2, idx.$1);

  @override
  void add(AnimeEntryData e, [bool silent = false]) {
    db.writeTxnSync(
      () => db.isarBacklogAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => db.isarWatchedAnimeEntrys.deleteBySiteIdSync(e.site, e.id),
    );

    db.writeTxnSync(
      () => _collection.putBySiteIdSync(
        e is IsarWatchingAnimeEntry ? e : e.copySuperWatching(),
      ),
    );
  }

  @override
  void addAll(Iterable<AnimeEntryData> l, [bool silent = false]) {
    final e = l
        .map((e) => e is IsarWatchingAnimeEntry ? e : e.copySuperWatching())
        .toList();

    final (ids, sites) = _foldTulpeListFnc(e, (e) => (e.id, e.site));

    db.writeTxnSync(
      () => db.isarBacklogAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(
      () => db.isarWatchedAnimeEntrys.deleteAllBySiteIdSync(sites, ids),
    );

    db.writeTxnSync(() => _collection.putAllBySiteIdSync(e));
  }

  @override
  List<IsarWatchingAnimeEntry> removeAll(
    Iterable<(int, AnimeMetadata)> idx, [
    bool silent = false,
  ]) {
    final (ids, sites) = _foldTulpeList(idx);

    final ret = _collection.getAllBySiteIdSync(sites, ids);

    db.writeTxnSync(
      () => _collection.deleteAllBySiteIdSync(
        sites,
        ids,
      ),
    );

    return ret.where((e) => e != null).cast<IsarWatchingAnimeEntry>().toList();
  }
}

abstract class _IsarCollectionStorage<K, V> extends SourceStorage<K, V> {
  _IsarCollectionStorage(
    this.db, {
    required this.closeOnDestroy,
  });

  final Isar db;
  final bool closeOnDestroy;

  IsarCollection<V> get _collection;

  @override
  Iterable<V> get reversed => _IsarCollectionReverseIterable(
        _IsarCollectionIterator<V>(_collection, reversed: true),
      );

  @override
  int get count => _collection.countSync();

  @override
  Iterator<V> get iterator =>
      _IsarCollectionIterator<V>(_collection, reversed: false);

  @override
  void clear([bool silent = false]) => db.writeTxnSync(
        _collection.clearSync,
        silent: silent,
      );

  @override
  void destroy([bool delete = false]) =>
      closeOnDestroy ? db.close(deleteFromDisk: delete) : null;

  @override
  V operator [](K index) => get(index)!;

  @override
  void operator []=(K index, V value) => addAll([value]);

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _collection.watchLazy(fireImmediately: fire).map((_) => count).listen(f);

  @override
  Iterable<V> trySorted(SortingMode sort) => this;
}

class IsarVideoService implements VideoSettingsService {
  const IsarVideoService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarVideoSettings> get collection => db.isarVideoSettings;

  @override
  VideoSettingsData get current =>
      collection.getSync(0) ??
      const IsarVideoSettings(looping: true, volume: 1);

  @override
  void add(VideoSettingsData data) {
    db.writeTxnSync(
      () => collection.putSync(data as IsarVideoSettings),
    );
  }

  @override
  StreamSubscription<VideoSettingsData> watch(
    void Function(VideoSettingsData p1) f,
  ) =>
      collection.watchLazy().map((_) => current).listen(f);
}

class IsarMiscSettingsService implements MiscSettingsService {
  const IsarMiscSettingsService();

  Isar get db => _Dbs.g.main;

  @visibleForTesting
  void clearStorageTest_() {
    collection.clearSync();
  }

  IsarCollection<IsarMiscSettings> get collection => db.isarMiscSettings;

  @override
  MiscSettingsData get current =>
      collection.getSync(0) ??
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
    db.writeTxnSync(
      () => collection.putSync(data as IsarMiscSettings),
    );
  }

  @override
  StreamSubscription<MiscSettingsData?> watch(
    void Function(MiscSettingsData?) f, [
    bool fire = false,
  ]) =>
      collection.watchObject(0, fireImmediately: fire).listen(f);
}

class IsarHiddenBooruPostService implements HiddenBooruPostService {
  const IsarHiddenBooruPostService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarHiddenBooruPost> get collection => db.isarHiddenBooruPosts;

  @override
  Map<(int, Booru), String> get cachedValues =>
      _Dbs.g._hiddenBooruPostCachedValues;

  @override
  void addAll(List<HiddenBooruPostData> booru) {
    if (booru.isEmpty) {
      return;
    }

    db.writeTxnSync(
      () {
        collection.putAllSync(booru.cast());

        for (final e in booru) {
          cachedValues[(e.postId, e.booru)] = e.thumbUrl;
        }
      },
    );
  }

  @override
  void removeAll(List<(int, Booru)> booru) {
    if (booru.isEmpty) {
      return;
    }

    db.writeTxnSync(
      () {
        collection.deleteAllByPostIdBooruSync(
          booru.map((e) => e.$1).toList(),
          booru.map((e) => e.$2).toList(),
        );

        for (final e in booru) {
          cachedValues.remove(e);
        }
      },
    );
  }

  @override
  StreamSubscription<void> watch(void Function(void) f) =>
      collection.watchLazy().listen(f);

  @override
  Stream<bool> streamSingle(int id, Booru booru, [bool fire = false]) =>
      collection
          .where()
          .postIdBooruEqualTo(id, booru)
          .watchLazy(fireImmediately: fire)
          .map((e) => cachedValues.containsKey((id, booru)));
}

class IsarFavoritePostService implements FavoritePostSourceService {
  IsarFavoritePostService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarFavoritePost> get collection => db.isarFavoritePosts;

  @override
  bool isFavorite(int id, Booru booru) =>
      backingStorage.map_.containsKey((id, booru));

  @override
  List<PostBase> addRemove(List<PostBase> posts) {
    final toAdd = <IsarFavoritePost>[];
    final toRemoveInts = <int>[];
    final toRemoveBoorus = <Booru>[];

    for (final post in posts) {
      if (!backingStorage.map_.containsKey((post.id, post.booru))) {
        toAdd.add(
          post is IsarFavoritePost
              ? post
              : IsarFavoritePost(
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
                  type: post.type,
                  isarId: null,
                ),
        );
      } else {
        toRemoveInts.add(post.id);
        toRemoveBoorus.add(post.booru);
      }
    }

    if (toAdd.isEmpty && toRemoveInts.isEmpty) {
      return const [];
    }

    final deleteCopy = toRemoveInts.isEmpty
        ? null
        : collection.getAllByIdBooruSync(toRemoveInts, toRemoveBoorus);

    db.writeTxnSync(() {
      collection.putAllByIdBooruSync(toAdd);
      for (final e in toAdd) {
        backingStorage[(e.id, e.booru)] = e;
      }

      collection.deleteAllByIdBooruSync(toRemoveInts, toRemoveBoorus);
      for (final e in toRemoveBoorus.indexed) {
        backingStorage.removeAll([(toRemoveInts[e.$1], e.$2)]);
      }
    });

    return deleteCopy?.where((e) => e != null).cast<PostBase>().toList() ??
        const <Post>[];
  }

  @override
  final MapStorage<(int, Booru), FavoritePost> backingStorage =
      MapStorage((v) => (v.id, v.booru));

  @override
  Future<int> clearRefresh() => Future.value(backingStorage.count);

  @override
  void destroy() {
    backingStorage.destroy();
  }

  @override
  bool get hasNext => false;

  @override
  Future<int> next() => Future.value(backingStorage.count);

  @override
  RefreshingProgress get progress => const RefreshingProgress.empty();

  @override
  StreamSubscription<T> watchSingle<T>(
    int id,
    Booru booru,
    T Function(bool p1) transform,
    void Function(T p1) f, [
    bool fire = false,
  ]) =>
      collection
          .where()
          .idBooruEqualTo(id, booru)
          .watch(fireImmediately: fire)
          .map((e) => transform(e.isNotEmpty))
          .listen(f);
}

// class IsarWatchedAnimeEntryService implements WatchedAnimeEntryService {
//   const IsarWatchedAnimeEntryService();

//   Isar get db => _Dbs.g.anime;

//   IsarCollection<IsarWatchedAnimeEntry> get collection =>
//       db.isarWatchedAnimeEntrys;

//   @override
//   bool watched(int id, AnimeMetadata site) =>
//       collection.getBySiteIdSync(site, id) != null;

//   @override
//   void delete(int id, AnimeMetadata site) {
//     db.writeTxnSync(
//       () => collection.deleteBySiteIdSync(site, id),
//     );
//   }

//   @override
//   void deleteAll(List<(int, AnimeMetadata)> ids) {
//     db.writeTxnSync(
//       () => collection.deleteAllBySiteIdSync(
//         ids.map((e) => e.$2).toList(),
//         ids.map((e) => e.$1).toList(),
//       ),
//     );
//   }

//   @override
//   int get count => collection.countSync();

//   @override
//   List<WatchedAnimeEntryData> get all => collection.where().findAllSync();

//   @override
//   void update(AnimeEntryData e) {
//     final prev = maybeGet(e.id, e.site);

//     if (prev == null) {
//       return;
//     }

//     prev.copySuper(e).save();
//   }

//   @override
//   void add(WatchedAnimeEntryData entry) {
//     db.writeTxnSync(
//       () => collection.putBySiteIdSync(entry as IsarWatchedAnimeEntry),
//     );
//   }

//   @override
//   void reAdd(List<WatchedAnimeEntryData> entries) {
//     db.writeTxnSync(
//       () => collection.putAllSync(entries.cast()),
//     );
//   }

//   @override
//   WatchedAnimeEntryData? maybeGet(int id, AnimeMetadata site) =>
//       collection.getBySiteIdSync(site, id);

//   @override
//   void moveAllReversed(
//     List<WatchedAnimeEntryData> entries,
//     SavedAnimeEntriesService s,
//   ) {
//     deleteAll(entries.toIds);

//     s.addAll(entries, this);
//   }

//   @override
//   void moveAll(List<AnimeEntryData> entries, SavedAnimeEntriesService s) {
//     s.deleteAll(entries.toIds);

//     db.writeTxnSync(
//       () => collection.putAllBySiteIdSync(
//         entries
//             .map(
//               (entry) => IsarWatchedAnimeEntry(
//                 type: entry.type,
//                 explicit: entry.explicit,
//                 date: DateTime.now(),
//                 site: entry.site,
//                 relations: entry.relations.cast(),
//                 background: entry.background,
//                 thumbUrl: entry.thumbUrl,
//                 title: entry.title,
//                 titleJapanese: entry.titleJapanese,
//                 titleEnglish: entry.titleEnglish,
//                 score: entry.score,
//                 synopsis: entry.synopsis,
//                 airedFrom: entry.airedFrom,
//                 airedTo: entry.airedTo,
//                 id: entry.id,
//                 staff: entry.staff.cast(),
//                 siteUrl: entry.siteUrl,
//                 isAiring: entry.isAiring,
//                 titleSynonyms: entry.titleSynonyms,
//                 genres: entry.genres.cast(),
//                 trailerUrl: entry.trailerUrl,
//                 episodes: entry.episodes,
//                 imageUrl: entry.imageUrl,
//                 isarId: null,
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }

//   @override
//   StreamSubscription<void> watchAll(
//     void Function(void) f, [
//     bool fire = false,
//   ]) =>
//       collection.watchLazy(fireImmediately: fire).listen(f);

//   @override
//   StreamSubscription<WatchedAnimeEntryData?> watchSingle(
//     int id,
//     AnimeMetadata site,
//     void Function(WatchedAnimeEntryData?) f, [
//     bool fire = false,
//   ]) =>
//       collection
//           .where()
//           .siteIdEqualTo(site, id)
//           .watchLazy(fireImmediately: fire)
//           .map((event) {
//         return maybeGet(id, site);
//       }).listen(f);

//   @override
//   StreamSubscription<int> watchCount(
//     void Function(int p1) f, [
//     bool fire = false,
//   ]) =>
//       collection
//           .watchLazy(fireImmediately: fire)
//           .map((event) => count)
//           .listen(f);
// }

class IsarDownloadFileService implements DownloadFileService {
  const IsarDownloadFileService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarDownloadFile> get collection => db.isarDownloadFiles;

  @override
  List<IsarDownloadFile> get inProgressAll =>
      collection.where().statusEqualTo(DownloadStatus.inProgress).findAllSync();

  @override
  List<DownloadFileData> get failedAll =>
      collection.where().statusEqualTo(DownloadStatus.failed).findAllSync();

  @override
  void markInProgressAsFailed() {
    final inProgress = inProgressAll;

    db.writeTxnSync(() {
      collection.putAllByUrlSync(
        inProgress.map<IsarDownloadFile>((e) => e.toFailed()).toList(),
      );
    });
  }

  @override
  void saveAll(List<DownloadFileData> l) {
    db.writeTxnSync(
      () => collection.putAllSync(l.cast()),
    );
  }

  @override
  void deleteAll(List<String> urls) {
    db.writeTxnSync(
      () => collection.deleteAllByUrlSync(urls),
    );
  }

  @override
  DownloadFileData? get(String url) => collection.getByUrlSync(url);

  @override
  bool exist(String url) => collection.getByUrlSync(url) != null;

  @override
  bool notExist(String url) => !exist(url);

  @override
  void clear() => db.writeTxnSync(() => collection.clearSync());

  @override
  DownloadFileData? next() {
    return collection
        .where()
        .statusEqualTo(DownloadStatus.onHold)
        .limit(1)
        .findFirstSync();
  }

  @override
  List<DownloadFileData> nextNumber(int minus) {
    if (collection.countSync() < 6) {
      return const [];
    }

    return collection
        .where()
        .statusEqualTo(DownloadStatus.onHold)
        .sortByDateDesc()
        .limit(6 - minus)
        .findAllSync();
  }
}

class IsarStatisticsGeneralService implements StatisticsGeneralService {
  const IsarStatisticsGeneralService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarStatisticsGeneral> get collection =>
      db.isarStatisticsGenerals;

  @override
  StatisticsGeneralData get current =>
      collection.getSync(0) ??
      const IsarStatisticsGeneral(
        timeDownload: 0,
        timeSpent: 0,
        scrolledUp: 0,
        refreshes: 0,
      );

  @override
  void add(StatisticsGeneralData data) {
    db.writeTxnSync(
      () => collection.putSync(data as IsarStatisticsGeneral),
    );
  }
}

class IsarStatisticsGalleryService implements StatisticsGalleryService {
  const IsarStatisticsGalleryService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarStatisticsGallery> get collection =>
      db.isarStatisticsGallerys;

  @override
  StatisticsGalleryData get current =>
      collection.getSync(0) ??
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
    db.writeTxnSync(
      () => collection.putSync(data as IsarStatisticsGallery),
    );
  }

  @override
  StreamSubscription<StatisticsGalleryData> watch(
    void Function(StatisticsGalleryData p1) f, [
    bool fire = false,
  ]) =>
      collection
          .watchObjectLazy(0, fireImmediately: fire)
          .map((e) => current)
          .listen(f);
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

  @override
  StreamSubscription<StatisticsBooruData> watch(
    void Function(StatisticsBooruData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarStatisticsBoorus
          .watchObjectLazy(0, fireImmediately: fire)
          .map((e) => current)
          .listen(f);
}

class IsarDailyStatisticsService implements StatisticsDailyService {
  const IsarDailyStatisticsService();

  Isar get db => _Dbs.g.main;

  IsarCollection<IsarDailyStatistics> get collection => db.isarDailyStatistics;

  @override
  StatisticsDailyData get current =>
      collection.getSync(0) ??
      IsarDailyStatistics(
        swipedBoth: 0,
        date: DateTime.now(),
        durationMillis: 0,
      );

  @override
  void add(StatisticsDailyData data) {
    db.writeTxnSync(
      () => collection.putSync(data as IsarDailyStatistics),
    );
  }
}

class IsarBlacklistedDirectoryService implements BlacklistedDirectoryService {
  IsarBlacklistedDirectoryService();

  Isar get db => _Dbs.g.blacklisted;

  IsarCollection<IsarDailyStatistics> get collection => db.isarDailyStatistics;

  @override
  late final IsarSourceStorage<String, BlacklistedDirectoryData,
      IsarBlacklistedDirectory> backingStorage = IsarSourceStorage(
    _Dbs.g.blacklisted,
    txPut: (c, l) =>
        c.putAllByBucketIdSync(l.cast<IsarBlacklistedDirectory>().toList()),
    txGet: (c, key) => c.getByBucketIdSync(key),
    txRemove: (c, keys) {
      final k = keys.toList();

      final ret = c.getAllByBucketIdSync(k);
      c.deleteAllByBucketIdSync(k);

      return ret
          .where((e) => e != null)
          .cast<IsarBlacklistedDirectory>()
          .toList();
    },
    sortFnc: null,
  );

  @override
  List<BlacklistedDirectoryData> getAll(List<String> bucketIds) =>
      backingStorage._collection
          .getAllByBucketIdSync(bucketIds)
          .where((element) => element != null)
          .cast<BlacklistedDirectoryData>()
          .toList();

  @override
  bool get hasNext => false;

  @override
  Future<int> clearRefresh() => Future.value(backingStorage.count);

  @override
  Future<int> next() => Future.value(backingStorage.count);

  @override
  RefreshingProgress get progress => const RefreshingProgress.empty();

  @override
  void destroy() {}
}

class IsarDirectoryMetadataService implements DirectoryMetadataService {
  const IsarDirectoryMetadataService();

  @override
  SegmentCapability caps(String specialLabel) =>
      _DirectoryMetadataCap(specialLabel, this);

  @override
  DirectoryMetadata? get(String id) =>
      _Dbs.g.blacklisted.isarDirectoryMetadatas.getByCategoryNameSync(id);

  @override
  DirectoryMetadata getOrCreate(String id) {
    var d = get(id);
    if (d == null) {
      d = IsarDirectoryMetadata(
        isarId: null,
        categoryName: id,
        time: DateTime.now(),
        blur: false,
        sticky: false,
        requireAuth: false,
      );

      _Dbs.g.blacklisted.writeTxnSync(
        () => _Dbs.g.blacklisted.isarDirectoryMetadatas
            .putByCategoryNameSync(d! as IsarDirectoryMetadata),
      );
    }

    return d;
  }

  @override
  Future<bool> canAuth(String id, String reason) async {
    if (!AppInfo().canAuthBiometric) {
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
  void add(DirectoryMetadata data) {
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
            categoryName: id,
            time: DateTime.now(),
            blur: blur,
            requireAuth: auth,
            sticky: sticky,
            isarId: null,
          ),
        );
      },
    );
  }

  @override
  StreamSubscription<void> watch(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.blacklisted.isarDirectoryMetadatas
          .watchLazy(fireImmediately: fire)
          .listen(f);
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
                categoryName: segments[element.$1],
                time: DateTime.now(),
                blur: false,
                sticky: false,
                requireAuth: false,
                isarId: null,
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
                categoryName: segments[e.$1],
                time: DateTime.now(),
                blur: false,
                sticky: false,
                requireAuth: false,
                isarId: null,
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
  Map<int, void> get cachedValues => _Dbs.g._favoriteFilesCachedValues;

  @override
  int get thumbnail => _Dbs.g.blacklisted.isarFavoriteFiles
      .where()
      .sortByTimeDesc()
      .limit(1)
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
  List<int> getAllIds(List<int> ids) => _Dbs.g.blacklisted.isarFavoriteFiles
      .getAllSync(ids)
      .where((e) => e != null)
      .map((e) => e!.id)
      .toList();

  @override
  void addAll(List<int> ids) {
    _Dbs.g.blacklisted.writeTxnSync(
      () {
        _Dbs.g.blacklisted.isarFavoriteFiles.putAllSync(
          ids
              .map((e) => IsarFavoriteFile(id: e, time: DateTime.now()))
              .toList(),
        );

        for (final e in ids) {
          cachedValues[e] = null;
        }
      },
    );
  }

  @override
  void deleteAll(List<int> ids) {
    _Dbs.g.blacklisted.writeTxnSync(
      () {
        _Dbs.g.blacklisted.isarFavoriteFiles.deleteAllSync(ids);

        for (final e in ids) {
          cachedValues.remove(e);
        }
      },
    );
  }

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _Dbs.g.blacklisted.isarFavoriteFiles
          .watchLazy(fireImmediately: fire)
          .map<int>((_) => cachedValues.length)
          .listen(f);

  @override
  Stream<bool> streamSingle(int id, [bool fire = false]) =>
      _Dbs.g.blacklisted.isarFavoriteFiles
          .watchObject(id, fireImmediately: fire)
          .map((e) => e != null);
}

class IsarPinnedThumbnailService implements PinnedThumbnailService {
  const IsarPinnedThumbnailService();

  @override
  PinnedThumbnailData? get(int id) =>
      _Dbs.g.thumbnail!.isarPinnedThumbnails.getSync(id);

  @override
  void clear() => _Dbs.g.thumbnail!
      .writeTxnSync(() => _Dbs.g.thumbnail!.isarPinnedThumbnails.clearSync());

  @override
  bool delete(int id) => _Dbs.g.thumbnail!.writeTxnSync(
        () => _Dbs.g.thumbnail!.isarPinnedThumbnails.deleteSync(id),
      );

  @override
  void add(int id, String path, int differenceHash) {
    _Dbs.g.thumbnail!.writeTxnSync(
      () => _Dbs.g.thumbnail!.isarPinnedThumbnails.putSync(
        IsarPinnedThumbnail(
          id: id,
          differenceHash: differenceHash,
          path: path,
        ),
      ),
    );
  }
}

class IsarThumbnailService implements ThumbnailService {
  const IsarThumbnailService();

  @override
  ThumbnailData? get(int id) => _Dbs.g.thumbnail!.isarThumbnails.getSync(id);

  @override
  void clear() {
    _Dbs.g.thumbnail!
        .writeTxnSync(() => _Dbs.g.thumbnail!.isarThumbnails.clearSync());
  }

  @override
  void delete(int id) => _Dbs.g.thumbnail!
      .writeTxnSync(() => _Dbs.g.thumbnail!.isarThumbnails.deleteSync(id));

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

      GalleryManagementApi.current().thumbs.removeAll(toDelete);
    }

    _Dbs.g.thumbnail!.writeTxnSync(() {
      _Dbs.g.thumbnail!.isarThumbnails.putAllSync(
        l
            .map(
              (e) => IsarThumbnail(
                id: e.id,
                updatedAt: DateTime.now(),
                path: e.path,
                differenceHash: e.differenceHash,
              ),
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
      () =>
          _Dbs.g.anime.isarCompactMangaDatas.putAllByMangaIdSiteSync(l.cast()),
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
  void addAll(List<MangaEntry> l) {
    if (l.isEmpty) {
      return;
    }

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarPinnedMangas.putAllByMangaIdSiteSync(
        l
            .map(
              (e) => IsarPinnedManga(
                mangaId: e.id.toString(),
                site: e.site,
                thumbUrl: e.thumbUrl,
                title: e.title,
                isarId: null,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  void reAdd(List<PinnedManga> l) => _Dbs.g.anime.writeTxnSync(
        () => _Dbs.g.anime.isarPinnedMangas.putAllByMangaIdSiteSync(l.cast()),
      );

  @override
  List<PinnedManga> deleteAll(List<(MangaId, MangaMeta)> ids) {
    if (ids.isEmpty) {
      return const [];
    }

    final mIds = ids.map((e) => e.$1.toString()).toList();
    final sites = ids.map((e) => e.$2).toList();

    final saved = _Dbs.g.anime.isarPinnedMangas
        .getAllByMangaIdSiteSync(mIds, sites)
        .where((element) => element != null)
        .cast<PinnedManga>()
        .toList();

    _Dbs.g.anime.writeTxnSync(
      () => _Dbs.g.anime.isarPinnedMangas.deleteAllByMangaIdSiteSync(
        mIds,
        sites,
      ),
    );

    return saved;
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
        .limit(1)
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
          isarId: null,
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
          isarId: null,
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
  StreamSubscription<void> watch(void Function(void) f) =>
      _Dbs.g.anime.isarReadMangaChapters.watchLazy().listen(f);

  @override
  StreamSubscription<int> watchReading(void Function(int) f) =>
      _Dbs.g.anime.isarReadMangaChapters
          .watchLazy()
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
          chapters: (prev?.chapters ?? const []) + (chapters.cast()),
          mangaId: mangaId,
          site: site,
          isarId: null,
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
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarGridSettingsFiles
          .watchObject(0, fireImmediately: fire)
          .map(
            (event) => event ?? current,
          )
          .listen(f);
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
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarGridSettingsFavorites
          .watchObject(0, fireImmediately: fire)
          .map((event) => event ?? current)
          .listen(f);
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
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarGridSettingsDirectories
          .watchObject(0, fireImmediately: fire)
          .map((event) => event ?? current)
          .listen(f);
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
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarGridSettingsBoorus
          .watchObject(0, fireImmediately: fire)
          .map((event) => event ?? current)
          .listen(f);
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
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarGridSettingsAnimeDiscoverys
          .watchObject(0, fireImmediately: fire)
          .map((event) => event ?? current)
          .listen(f);
}

class IsarGridSettinsService implements GridSettingsService {
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

class IsarLocalTagsService implements LocalTagsService {
  const IsarLocalTagsService();

  @override
  int get count => _Dbs.g.localTags.isarLocalTags.countSync();

  /// Returns tags for the [filename], or empty list if there are none.
  @override
  List<String> get(String filename) {
    return _Dbs.g.localTags.isarLocalTags.getByFilenameSync(filename)?.tags ??
        [];
  }

  @override
  void add(String filename, List<String> tags) {
    _Dbs.g.localTags.writeTxnSync(
      () {
        _Dbs.g.localTags.isarLocalTags.putByFilenameSync(
          IsarLocalTags(filename: filename, tags: tags, isarId: null),
        );
      },
    );
  }

  @override
  void addAll(List<LocalTagsData> tags) {
    _Dbs.g.localTags.writeTxnSync(() {
      _Dbs.g.localTags.isarLocalTags.putAllByFilenameSync(
        tags.cast(),
      );
    });
  }

  @override
  void addMultiple(List<String> filenames, String tag) {
    if (filenames.isEmpty || tag.isEmpty) {
      return;
    }

    final newTags = _Dbs.g.localTags.isarLocalTags
        .getAllByFilenameSync(filenames)
        .where((element) => element != null && !element.tags.contains(tag))
        .map(
          (e) => IsarLocalTags(
            filename: e!.filename,
            tags: _addAndSort(e.tags, tag),
            isarId: null,
          ),
        )
        .toList();

    if (newTags.isEmpty) {
      return;
    }

    return _Dbs.g.localTags.writeTxnSync(
      () {
        _Dbs.g.localTags.isarLocalTags.putAllByFilenameSync(newTags);
      },
    );
  }

  @override
  void delete(String filename) {
    _Dbs.g.localTags.writeTxnSync(
      () {
        _Dbs.g.localTags.isarLocalTags.deleteByFilenameSync(filename);
      },
    );
  }

  @override
  void removeSingle(List<String> filenames, String tag) {
    final List<IsarLocalTags> newTags = [];

    for (final e in _Dbs.g.localTags.isarLocalTags
        .getAllByFilenameSync(filenames)
        .cast<LocalTagsData>()) {
      final idx = e.tags.indexWhere((element) => element == tag);
      if (idx.isNegative) {
        continue;
      }

      newTags.add(
        IsarLocalTags(
          filename: e.filename,
          tags: e.tags.toList()..removeAt(idx),
          isarId: null,
        ),
      );
    }

    return _Dbs.g.localTags.writeTxnSync(
      () {
        _Dbs.g.localTags.isarLocalTags.putAllByFilenameSync(newTags);
      },
    );
  }

  @override
  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData) f,
  ) =>
      _Dbs.g.localTags.isarLocalTags
          .where()
          .filenameEqualTo(filename)
          .watch()
          .map((e) => e.first)
          .listen(f);

  List<String> _addAndSort(List<String> tags, String addTag) {
    final l = tags.toList() + [addTag];
    l.sort();

    return l;
  }
}

class IsarDirectoryTagService implements DirectoryTagService {
  const IsarDirectoryTagService();

  @override
  String? get(String bucketId) =>
      _Dbs.g.localTags.directoryTags.getByBuckedIdSync(bucketId)?.tag;

  @override
  bool searchByTag(String tag) =>
      _Dbs.g.localTags.directoryTags
          .filter()
          .tagStartsWith(tag)
          .limit(1)
          .findFirstSync() !=
      null;

  @override
  void add(Iterable<String> bucketIds, String tag) {
    _Dbs.g.localTags.writeTxnSync(
      () => _Dbs.g.localTags.directoryTags.putAllSync(
        bucketIds
            .map((e) => DirectoryTag(buckedId: e, tag: tag, isarId: null))
            .toList(),
      ),
    );
  }

  @override
  void delete(Iterable<String> buckedIds) {
    _Dbs.g.localTags.writeTxnSync(
      () => _Dbs.g.localTags.directoryTags
          .deleteAllByBuckedIdSync(buckedIds.toList()),
    );
  }
}

class IsarTagManager implements TagManager {
  const IsarTagManager();

  @override
  IsarBooruTagging get excluded =>
      const IsarBooruTagging(mode: TagType.excluded);
  @override
  IsarBooruTagging get latest => const IsarBooruTagging(mode: TagType.normal);
  @override
  IsarBooruTagging get pinned => const IsarBooruTagging(mode: TagType.pinned);
}

class IsarBooruTagging implements BooruTagging {
  const IsarBooruTagging({
    required this.mode,
  });

  final TagType mode;
  Isar get tagDb => _Dbs.g.localTags;

  @override
  bool exists(String tag) => tagDb.isarTags.getByTagTypeSync(tag, mode) != null;

  @override
  List<TagData> get(int i) {
    if (i.isNegative) {
      return tagDb.isarTags
          .filter()
          .typeEqualTo(mode)
          .sortByTimeDesc()
          .findAllSync();
    }

    return tagDb.isarTags
        .filter()
        .typeEqualTo(mode)
        .sortByTimeDesc()
        .limit(i)
        .findAllSync();
  }

  @override
  void add(String t) {
    tagDb.writeTxnSync(
      () => tagDb.isarTags.putByTagTypeSync(
        IsarTag(time: DateTime.now(), tag: t, type: mode, isarId: null),
      ),
    );
  }

  @override
  void delete(String t) {
    tagDb.writeTxnSync(
      () => tagDb.isarTags.deleteByTagTypeSync(t, mode),
    );
  }

  @override
  void clear() {
    tagDb.writeTxnSync(
      () => tagDb.isarTags.filter().typeEqualTo(mode).deleteAllSync(),
    );
  }

  @override
  StreamSubscription<void> watch(void Function(void) f, [bool fire = false]) {
    return tagDb.isarTags.watchLazy(fireImmediately: fire).listen(f);
  }

  @override
  StreamSubscription<List<ImageTag>> watchImage(
    List<String> tags,
    void Function(List<ImageTag> l) f, {
    bool fire = false,
  }) {
    return tagDb.isarTags.watchLazy().map<List<ImageTag>>((event) {
      return tags
          .map(
            (e) => ImageTag(
              e,
              favorite:
                  tagDb.isarTags.getByTagTypeSync(e, TagType.pinned) != null,
              excluded:
                  tagDb.isarTags.getByTagTypeSync(e, TagType.excluded) != null,
            ),
          )
          .toList();
    }).listen(f);
  }

  @override
  StreamSubscription<List<ImageTag>> watchImageLocal(
    String filename,
    void Function(List<ImageTag> l) f, {
    required LocalTagsService localTag,
    bool fire = false,
  }) {
    return StreamGroup.merge<void>([
      _Dbs.g.localTags.isarLocalTags
          .where()
          .filenameEqualTo(filename)
          .watchLazy(),
      tagDb.isarTags.watchLazy(),
    ]).map<List<ImageTag>>((event) {
      final t =
          _Dbs.g.localTags.isarLocalTags.getByFilenameSync(filename)?.tags;
      if (t == null) {
        return const [];
      }

      return t
          .map(
            (e) => ImageTag(
              e,
              favorite:
                  tagDb.isarTags.getByTagTypeSync(e, TagType.pinned) != null,
              excluded:
                  tagDb.isarTags.getByTagTypeSync(e, TagType.excluded) != null,
            ),
          )
          .toList();
    }).listen(f);
  }
}

class IsarGridStateBooruService implements GridBookmarkService {
  const IsarGridStateBooruService();

  @override
  int get count => _Dbs.g.main.isarBookmarks.countSync();

  @override
  List<GridBookmark> get all =>
      _Dbs.g.main.isarBookmarks.where().sortByTimeDesc().findAllSync();

  @override
  void add(GridBookmark state) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarBookmarks.putByNameSync(state as IsarBookmark),
    );
  }

  @override
  List<GridBookmark> firstNumber(int n) {
    if (n.isNegative) {
      return all;
    } else if (n == 0) {
      return const [];
    }

    return _Dbs.g.main.isarBookmarks
        .where()
        .sortByTimeDesc()
        .limit(n)
        .findAllSync();
  }

  @override
  GridBookmark? get(String name) =>
      _Dbs.g.main.isarBookmarks.getByNameSync(name);

  @override
  GridBookmark? getFirstByTags(String tags, Booru preferBooru) =>
      _Dbs.g.main.isarBookmarks
          .filter()
          .tagsStartsWith(tags)
          .booruEqualTo(preferBooru)
          .or()
          .not()
          .booruEqualTo(preferBooru)
          .limit(1)
          .findFirstSync();

  @override
  void delete(String name) {
    _Dbs.g.main.writeTxnSync(
      () => _Dbs.g.main.isarBookmarks.deleteByNameSync(
        name,
      ),
    );
  }

  @override
  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]) =>
      _Dbs.g.main.isarBookmarks
          .watchLazy(fireImmediately: fire)
          .map<int>((e) => count)
          .listen(f);
}

class IsarSecondaryGridService implements SecondaryGridService {
  const IsarSecondaryGridService._(
    this._secondaryGrid,
    this._mainGrid,
    this.name,
  );

  factory IsarSecondaryGridService.booru(
    Booru booru,
    String name,
    bool create,
  ) {
    final dbMain = _Dbs.g.booru(booru);
    final dbSecondary = _openSecondaryGridName(name, create);

    return IsarSecondaryGridService._(
      dbSecondary,
      dbMain,
      name,
    );
  }

  @override
  final String name;

  final Isar _secondaryGrid;
  final Isar _mainGrid;

  @override
  int get page => _secondaryGrid.isarGridBooruPagings.getSync(0)?.page ?? 0;

  @override
  set page(int p) {
    _secondaryGrid.writeTxnSync(
      () => _secondaryGrid.isarGridBooruPagings.putSync(IsarGridBooruPaging(p)),
    );
  }

  @override
  GridState get currentState {
    GridState? state =
        _mainGrid.isarGridStates.getByNameSync(_secondaryGrid.name);
    if (state == null) {
      state = IsarGridState(
        tags: "",
        name: _secondaryGrid.name,
        safeMode: SafeMode.normal,
        offset: 0,
        isarId: null,
      );

      _mainGrid.writeTxnSync(
        () => _mainGrid.isarGridStates.putSync(state! as IsarGridState),
      );
    }

    return state;
  }

  @override
  set currentState(GridState state) {
    _mainGrid.writeTxnSync(
      () => _mainGrid.isarGridStates.putSync(state as IsarGridState),
    );
  }

  @override
  Future<void> destroy() => _secondaryGrid.close(deleteFromDisk: true);

  @override
  Future<void> close() => _secondaryGrid.close();

  @override
  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    String tags,
    HiddenBooruPostService hiddenBooruPosts,
  ) =>
      IsarCurrentBooruSource(
        db: _secondaryGrid,
        api: api,
        excluded: excluded,
        entry: entry,
        tags: tags,
        safeMode_: () => currentState.safeMode,
        filters: [
          (p) => !hiddenBooruPosts.isHidden(p.id, p.booru),
        ],
      );

  @override
  StreamSubscription<GridState> watch(
    void Function(GridState s) f, [
    bool fire = false,
  ]) =>
      _mainGrid.isarGridStates
          .where()
          .nameEqualTo(name)
          .watchLazy(fireImmediately: fire)
          .map((e) => currentState)
          .listen(f);
}

class IsarMainGridService implements MainGridService {
  const IsarMainGridService._(this._mainGrid);

  factory IsarMainGridService.booru(Booru booru) {
    final db = _Dbs.g.booru(booru);

    return IsarMainGridService._(db);
  }

  @override
  DateTime get time =>
      _mainGrid.isarGridTimes.getSync(0)?.time ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  set time(DateTime d) => _mainGrid
      .writeTxnSync(() => _mainGrid.isarGridTimes.putSync(IsarGridTime(d)));

  final Isar _mainGrid;

  @override
  int get page => _mainGrid.isarGridBooruPagings.getSync(0)?.page ?? 0;

  @override
  set page(int p) {
    _mainGrid.writeTxnSync(
      () => _mainGrid.isarGridBooruPagings.putSync(IsarGridBooruPaging(p)),
    );
  }

  @override
  GridState get currentState {
    GridState? state = _mainGrid.isarGridStates.getByNameSync(_mainGrid.name);
    if (state == null) {
      state = IsarGridState(
        tags: "",
        name: _mainGrid.name,
        safeMode: SafeMode.normal,
        offset: 0,
        isarId: null,
      );

      _mainGrid.writeTxnSync(
        () => _mainGrid.isarGridStates.putSync(state! as IsarGridState),
      );
    }

    return state;
  }

  @override
  set currentState(GridState state) {
    _mainGrid.writeTxnSync(
      () => _mainGrid.isarGridStates.putSync(state as IsarGridState),
    );
  }

  @override
  GridPostSource makeSource(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
    HiddenBooruPostService hiddenBooruPosts,
  ) =>
      IsarCurrentBooruSource(
        db: _mainGrid,
        api: api,
        excluded: excluded,
        entry: entry,
        tags: "",
        safeMode_: () => SettingsService.db().current.safeMode,
        filters: [
          (p) => !hiddenBooruPosts.isHidden(p.id, p.booru),
        ],
      );
}

class IsarVisitedPostsService implements VisitedPostsService {
  const IsarVisitedPostsService();

  Isar get db => _Dbs.g.anime;

  IsarCollection<IsarVisitedPost> get collection => db.isarVisitedPosts;

  @override
  List<VisitedPost> get all =>
      collection.where().sortByDateDesc().findAllSync();

  @override
  void addAll(List<VisitedPost> visitedPosts) {
    if (visitedPosts.isEmpty) {
      return;
    }

    db.writeTxnSync(() => collection.putAllByIdBooruSync(visitedPosts.cast()));

    if (collection.countSync() >= 500) {
      db.writeTxnSync(
        () => collection
            .where()
            .limit(collection.countSync() - 500)
            .deleteAllSync(),
      );
    }
  }

  @override
  void removeAll(List<VisitedPost> visitedPosts) {
    final (ids, boorus) =
        _foldTulpeListFnc(visitedPosts, (e) => (e.id, e.booru));

    db.writeTxnSync(() => collection.deleteAllByIdBooruSync(ids, boorus));
  }

  @override
  void clear() => db.writeTxnSync(() => collection.clearSync());

  @override
  StreamSubscription<void> watch(void Function(void p1) f) =>
      collection.watchLazy().listen(f);
}

(List<A>, List<B>) _foldTulpeList<A, B>(Iterable<(A, B)> t) {
  final (listA, listB) = t.fold((<A>[], <B>[]), (lists, e) {
    lists.$1.add(e.$1);
    lists.$2.add(e.$2);

    return lists;
  });

  return (listA, listB);
}

(List<A>, List<B>) _foldTulpeListFnc<T, A, B>(
  Iterable<T> t,
  (A, B) Function(T) f,
) {
  final (listA, listB) = t.fold((<A>[], <B>[]), (lists, e) {
    final (a, b) = f(e);

    lists.$1.add(a);
    lists.$2.add(b);

    return lists;
  });

  return (listA, listB);
}

class IsarNewestAnimeService implements NewestAnimeService {
  const IsarNewestAnimeService();

  Isar get db => _Dbs.g.anime;

  IsarCollection<IsarNewestAnime> get collection => db.isarNewestAnimes;

  @override
  (DateTime, List<AnimeEntryData>) get current {
    final e = collection.getSync(0);

    return e == null ? (DateTime(0), const []) : (e.time, e.entries);
  }

  @override
  void set(List<AnimeEntryData> l) {
    db.writeTxnSync(
      () => collection.putSync(
        IsarNewestAnime(
          time: DateTime.now(),
          entries: l
              .map(
                (e) => IsarNewestAnimeEntry.required(
                  imageUrl: e.imageUrl,
                  airedFrom: e.airedFrom,
                  airedTo: e.airedTo,
                  relations: (e.relations is List<IsarAnimeRelation>
                      ? e.relations as List<IsarAnimeRelation>
                      : e.relations.cast()),
                  staff: (e.staff is List<IsarAnimeRelation>
                      ? e.staff as List<IsarAnimeRelation>
                      : e.staff.cast()),
                  genres: (e.genres is List<IsarAnimeGenre>
                      ? e.genres as List<IsarAnimeGenre>
                      : e.genres.cast()),
                  explicit: e.explicit,
                  type: e.type,
                  site: e.site,
                  thumbUrl: e.thumbUrl,
                  title: e.title,
                  titleJapanese: e.titleJapanese,
                  titleEnglish: e.titleEnglish,
                  score: e.score,
                  synopsis: e.synopsis,
                  id: e.id,
                  siteUrl: e.siteUrl,
                  isAiring: e.isAiring,
                  titleSynonyms: e.titleSynonyms,
                  background: e.background,
                  trailerUrl: e.trailerUrl,
                  episodes: e.episodes,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  void clear() => db.writeTxnSync(() => collection.clearSync());

  @override
  StreamSubscription<void> watchAll(
    void Function(void p1) f, [
    bool fire = false,
  ]) =>
      collection.watchObject(0, fireImmediately: fire).listen(f);
}
