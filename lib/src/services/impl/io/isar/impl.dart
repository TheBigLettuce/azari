// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io" as io;

import "package:azari/src/logic/buffered_storage.dart";
import "package:azari/src/logic/event_table.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/posts_source.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/impl/io/isar/foundation/dbs.dart";
import "package:azari/src/services/impl/io/isar/foundation/favorite_posts_isolate.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/favorite_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/post.dart";
import "package:azari/src/services/impl/io/isar/schemas/booru/visited_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/downloader/download_file.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/blacklisted_directory.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/directory_metadata.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/directory_tags.dart";
import "package:azari/src/services/impl/io/isar/schemas/gallery/thumbnail.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/booru.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/directories.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/favorites.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_settings/files.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/bookmark.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_booru_paging.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_state.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/grid_time.dart";
import "package:azari/src/services/impl/io/isar/schemas/grid_state/updates_available.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/accounts.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/colors_names.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/hidden_booru_post.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/settings.dart";
import "package:azari/src/services/impl/io/isar/schemas/settings/video_settings.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/daily_statistics.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_booru.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_gallery.dart";
import "package:azari/src/services/impl/io/isar/schemas/statistics/statistics_general.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/hottest_tag.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/hottest_tag_refresh_date.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/local_tag_dictionary.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/local_tags.dart";
import "package:azari/src/services/impl/io/isar/schemas/tags/tags.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:isar/isar.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;

part "foundation/initalize_db.dart";
part "settings.dart";

abstract class IsarGridSettingsData implements ShellConfigurationData {
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
    required this.entry,
    required this.tags,
    required this.filters,
    required this.onNextCompleted,
    required this.onClearRefreshCompleted,
  }) : backingStorage = _IsarPostsStorage(db, closeOnDestroy: false),
       updatesAvailable = IsarUpdatesAvailableImpl(
         db,
         api,
         safeMode_,
         () => tags,
       );

  @override
  final void Function(GridPostSource)? onNextCompleted;
  @override
  final void Function(GridPostSource)? onClearRefreshCompleted;

  @override
  final BooruAPI api;
  @override
  final PagingEntry entry;

  final SafeMode Function() safeMode_;

  @override
  SafeMode get safeMode => safeMode_();

  @override
  bool get extraSafeFilters => const SettingsService().current.extraSafeFilters;

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
    _timeTicker = Stream<void>.periodic(const Duration(minutes: 15)).listen((
      _,
    ) {
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

      _future = api
          .totalPosts(tags_(), safeMode_())
          .then((count) {
            if (db.isOpen) {
              db.writeTxnSync(() {
                db.isarUpdatesAvailables.putSync(
                  IsarUpdatesAvailable(postCount: count, time: DateTime.now()),
                );
              });
            }

            return null;
          })
          .onError((e, trace) {
            Logger.root.warning("tryRefreshIfNeeded", e, trace);
            return null;
          })
          .whenComplete(() {
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
  ) => _events.stream.listen(f);
}

class IsarCollectionIterator<T> implements Iterator<T> {
  IsarCollectionIterator(
    this.collection, {
    required this.reversed,
    this.loader,
    int bufferLen = 40,
  }) {
    _storage = BufferedStorage<T>(bufferLen);
  }

  final IsarCollection<T> collection;
  final bool reversed;

  final QueryBuilder<T, T, QAfterLimit> Function(
    QueryBuilder<T, T, QWhere> q,
    int offset,
    int limit,
  )?
  loader;

  late final BufferedStorage<T> _storage;

  @override
  T get current => _storage.current;

  QueryBuilder<T, T, QAfterLimit> defaultLoader(
    QueryBuilder<T, T, QWhere> q,
    int offset,
    int limit,
  ) => q.offset(offset).limit(limit);

  Iterable<T> _nextItems(int offset, int limit) => (loader ?? defaultLoader)(
    collection.where(sort: reversed ? Sort.asc : Sort.desc),
    offset,
    limit,
  ).findAllSync();

  @override
  bool moveNext() => _storage.moveNext(_nextItems);
}

class IsarCollectionReverseIterable<V> extends Iterable<V> {
  const IsarCollectionReverseIterable(this.iterator);

  @override
  final Iterator<V> iterator;
}

class _IsarPostsStorage extends SourceStorage<int, Post> {
  _IsarPostsStorage(this.db, {required this.closeOnDestroy});

  final Isar db;
  final bool closeOnDestroy;

  IsarCollection<PostIsar> get _collection => db.postIsars;

  @override
  Iterable<Post> get reversed => IsarCollectionReverseIterable(
    IsarCollectionIterator<PostIsar>(_collection, reversed: true),
  );

  @override
  int get count => _collection.countSync();

  @override
  Iterator<Post> get iterator =>
      IsarCollectionIterator<PostIsar>(_collection, reversed: false);

  @override
  void add(Post e, [bool silent = true]) => db.writeTxnSync(
    () => _collection.putByIdBooruSync(
      e is PostIsar ? e : PostIsar.copyTo([e])[0],
    ),
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

    db.writeTxnSync(() => _collection.putAllByIdBooruSync(res), silent: silent);
  }

  @override
  void clear([bool silent = false]) =>
      db.writeTxnSync(() => _collection.clearSync(), silent: silent);

  @override
  Post? get(int idx) => _collection.getSync(idx + 1);

  @override
  List<Post> removeAll(Iterable<int> idx, [bool silent = false]) {
    final k = idx.map((e) => e + 1).toList();

    final ret = _collection.getAllSync(k);
    db.writeTxnSync(() => _collection.deleteAllSync(k), silent: silent);

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
  Stream<int> get countEvents => _collection.watchLazy().map((_) => count);

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

  final IsarCollectionIterator<V> Function(SortingMode sort)? sortFnc;

  IsarCollection<CollectionType> get _collection =>
      db.collection<CollectionType>();

  @override
  Iterable<V> get reversed => IsarCollectionReverseIterable(
    IsarCollectionIterator(_collection, reversed: true),
  );

  @override
  int get count => _collection.countSync();

  @override
  Iterator<V> get iterator =>
      IsarCollectionIterator(_collection, reversed: false);

  @override
  Iterable<V> trySorted(SortingMode sort) =>
      sortFnc == null ? this : IsarCollectionReverseIterable(sortFnc!(sort));

  @override
  void add(V e, [bool silent = true]) =>
      db.writeTxnSync(() => txPut(_collection, [e]), silent: silent);

  @override
  void addAll(Iterable<V> l, [bool silent = false]) =>
      db.writeTxnSync(() => txPut(_collection, l), silent: silent);

  @override
  void clear([bool silent = false]) =>
      db.writeTxnSync(() => _collection.clearSync(), silent: silent);

  @override
  V? get(K idx) => txGet(_collection, idx);

  @override
  List<V> removeAll(Iterable<K> idx, [bool silent = false]) =>
      db.writeTxnSync(() => txRemove(_collection, idx), silent: silent);

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

  @override
  Stream<int> get countEvents => _collection.watchLazy().map((_) => count);
}

class IsarVideoService implements VideoSettingsService {
  const IsarVideoService();

  Isar get db => Dbs().main;

  IsarCollection<IsarVideoSettings> get collection => db.isarVideoSettings;

  @override
  VideoSettingsData get current =>
      collection.getSync(0) ??
      const IsarVideoSettings(looping: true, volume: 1);

  @override
  void add(VideoSettingsData data) {
    db.writeTxnSync(() => collection.putSync(data as IsarVideoSettings));
  }

  @override
  StreamSubscription<VideoSettingsData> watch(
    void Function(VideoSettingsData p1) f,
  ) => collection.watchLazy().map((_) => current).listen(f);
}

// class IsarMiscSettingsService implements MiscSettingsService {
//   const IsarMiscSettingsService();

//   Isar get db => Dbs().main;

//   @visibleForTesting
//   void clearStorageTest_() {
//     collection.clearSync();
//   }

//   IsarCollection<IsarMiscSettings> get collection => db.isarMiscSettings;

//   @override
//   MiscSettingsData get current =>
//       collection.getSync(0) ??
//       const IsarMiscSettings(
//         filesExtendedActions: false,
//         themeType: ThemeType.systemAccent,
//         favoritesThumbId: 0,
//         favoritesPageMode: FilteringMode.tag,
//         randomVideosAddTags: "",
//         randomVideosOrder: RandomPostsOrder.latest,
//       );

//   @override
//   void add(MiscSettingsData data) {
//     db.writeTxnSync(
//       () => collection.putSync(data as IsarMiscSettings),
//     );
//   }

//   @override
//   StreamSubscription<MiscSettingsData> watch(
//     void Function(MiscSettingsData) f, [
//     bool fire = false,
//   ]) =>
//       collection.watchLazy(fireImmediately: fire).map((e) => current).listen(f);
// }

class IsarHiddenBooruPostService implements HiddenBooruPostsService {
  const IsarHiddenBooruPostService();

  Isar get db => Dbs().main;

  IsarCollection<IsarHiddenBooruPost> get collection => db.isarHiddenBooruPosts;

  @override
  Map<(int, Booru), String> get cachedValues =>
      Dbs().hiddenBooruPostCachedValues;

  @override
  void addAll(List<HiddenBooruPostData> booru) {
    if (booru.isEmpty) {
      return;
    }

    db.writeTxnSync(() {
      collection.putAllSync(booru.cast());

      for (final e in booru) {
        cachedValues[(e.postId, e.booru)] = e.thumbUrl;
      }
    });
  }

  @override
  void removeAll(List<(int, Booru)> booru) {
    if (booru.isEmpty) {
      return;
    }

    db.writeTxnSync(() {
      collection.deleteAllByPostIdBooruSync(
        booru.map((e) => e.$1).toList(),
        booru.map((e) => e.$2).toList(),
      );

      for (final e in booru) {
        cachedValues.remove(e);
      }
    });
  }

  @override
  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]) =>
      collection
          .watchLazy(fireImmediately: fire)
          .map((e) => collection.countSync())
          .listen(f);

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

  @override
  late final _FavoritePostCache cache = _FavoritePostCache();

  @override
  void addRemove(List<PostBase> posts) {
    final toAdd = <IsarFavoritePost>[];
    final toRemove = <(int, Booru)>[];

    for (final post in posts) {
      if (!cache.isFavorite(post.id, post.booru)) {
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
                  size: post.size,
                  isarId: null,
                  stars: FavoriteStars.zero,
                  filteringColors: FilteringColors.noColor,
                ),
        );
      } else {
        toRemove.add((post.id, post.booru));
      }
    }

    if (toAdd.isEmpty && toRemove.isEmpty) {
      return;
    }

    addAll(toAdd);
    removeAll(toRemove);
  }

  @override
  void addAll(List<FavoritePost> posts) {
    Dbs().favorites.add(posts);
  }

  @override
  void removeAll(List<(int, Booru)> idxs) {
    Dbs().favorites.remove(idxs);
  }

  void dispose() {
    cache.destroy();
  }
}

class IsarAccountsService implements AccountsService {
  const IsarAccountsService();

  Isar get db => Dbs().main;

  IsarCollection<IsarAccounts> get collection => db.isarAccounts;

  @override
  AccountsData get current =>
      collection.getSync(0) ??
      const IsarAccounts(
        danbooruApiKey: "",
        danbooruUsername: "",
        gelbooruApiKey: "",
        gelbooruUserId: "",
      );

  @override
  Stream<AccountsData> get events => collection.watchLazy().map((_) => current);

  @override
  void add(AccountsData data) =>
      db.writeTxnSync(() => collection.putSync(data as IsarAccounts));
}

class _FavoritePostCache extends FavoritePostCache {
  _FavoritePostCache() {
    _events = Dbs().favorites.events.listen((e) {
      switch (e) {
        case PostsAddedResult():
          addAll(e.posts);
        case PostsRemovedResult():
          removeAll(e.posts);
        case PostsClearResult():
          clear();
      }
    });

    eventsTable = EventStreamsTable.basic(
      _singleEvents.stream,
      const _FavoritePostsConditions(),
    );
  }

  late final StreamSubscription<FavoritePostResult> _events;
  late final EventStreamsTable eventsTable;

  final _singleEvents = StreamController<EventData>.broadcast();
  final _countEvents = StreamController<int>.broadcast();

  final _map = <(int, Booru), FavoritePost>{};

  @override
  int get count => _map.length;

  @override
  Iterator<FavoritePost> get iterator => _map.values.iterator;

  @override
  Stream<int> get countEvents => _countEvents.stream;

  @override
  FavoritePost operator []((int, Booru) index) => _map[index]!;

  void addAll(Iterable<FavoritePost> l) {
    for (final e in l) {
      final cond = _FavoritesEventCondition((e.id, e.booru));

      if (eventsTable.hasListeners(cond)) {
        _singleEvents.add(cond);
      }

      _map[(e.id, e.booru)] = e;
    }

    _countEvents.add(_map.length);
  }

  void clear() {
    _map.clear();
    eventsTable.clear();
    _countEvents.add(_map.length);
  }

  void removeAll(Iterable<(int, Booru)> idx) {
    for (final e in idx) {
      final cond = _FavoritesEventCondition(e);

      if (eventsTable.hasListeners(cond)) {
        _singleEvents.add(cond);
      }

      _map.remove(e);
    }

    _countEvents.add(_map.length);
  }

  @override
  FavoritePost? get((int, Booru) idx) => _map[idx];

  @override
  bool isFavorite(int id, Booru booru) => _map.containsKey((id, booru));

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) {
    if (fire) {
      _countEvents.add(count);
    }

    return countEvents.listen(f);
  }

  @override
  Stream<bool> streamSingle(int postId, Booru booru, [bool fire = false]) {
    final stream = eventsTable.forCondition(
      _FavoritesEventCondition((postId, booru)),
      fire,
    );

    return stream.map((_) => _map.containsKey((postId, booru)));
  }

  void destroy() {
    _events.cancel();
    _countEvents.close();
    _singleEvents.close();
    eventsTable.destroy();
  }
}

class _FavoritePostsConditions implements Conditions {
  const _FavoritePostsConditions();

  @override
  bool isOfThis(EventCondition c) => c is _FavoritesEventCondition;

  @override
  dynamic describeUnique(EventCondition c) {
    return (c as _FavoritesEventCondition).key;
  }

  @override
  dynamic processEvent(EventData e) {
    return (e as _FavoritesEventCondition).key;
  }
}

class _FavoritesEventCondition implements EventCondition, EventData {
  const _FavoritesEventCondition(this.key);

  final (int, Booru) key;

  @override
  bool operator ==(Object other) {
    if (other is! _FavoritesEventCondition) {
      return false;
    }

    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

class IsarDownloadFileService implements DownloadFileService {
  const IsarDownloadFileService();

  Isar get db => Dbs().main;

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
    db.writeTxnSync(() => collection.putAllSync(l.cast()));
  }

  @override
  void deleteAll(List<String> urls) {
    db.writeTxnSync(() => collection.deleteAllByUrlSync(urls));
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

  Isar get db => Dbs().main;

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
    db.writeTxnSync(() => collection.putSync(data as IsarStatisticsGeneral));
  }

  @override
  StreamSubscription<StatisticsGeneralData> watch(
    void Function(StatisticsGeneralData d) f, [
    bool fire = false,
  ]) => collection
      .watchObjectLazy(0, fireImmediately: fire)
      .map((e) => current)
      .listen(f);
}

class IsarStatisticsGalleryService implements StatisticsGalleryService {
  const IsarStatisticsGalleryService();

  Isar get db => Dbs().main;

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
    db.writeTxnSync(() => collection.putSync(data as IsarStatisticsGallery));
  }

  @override
  StreamSubscription<StatisticsGalleryData> watch(
    void Function(StatisticsGalleryData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObjectLazy(0, fireImmediately: fire)
      .map((e) => current)
      .listen(f);
}

class IsarStatisticsBooruService implements StatisticsBooruService {
  const IsarStatisticsBooruService();

  Isar get db => Dbs().main;

  IsarCollection<IsarStatisticsBooru> get collection => db.isarStatisticsBoorus;

  @override
  StatisticsBooruData get current =>
      collection.getSync(0) ??
      const IsarStatisticsBooru(
        booruSwitches: 0,
        downloaded: 0,
        swiped: 0,
        viewed: 0,
      );

  @override
  void add(StatisticsBooruData data) {
    db.writeTxnSync(() => collection.putSync(data as IsarStatisticsBooru));
  }

  @override
  StreamSubscription<StatisticsBooruData> watch(
    void Function(StatisticsBooruData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObjectLazy(0, fireImmediately: fire)
      .map((e) => current)
      .listen(f);
}

class IsarDailyStatisticsService implements StatisticsDailyService {
  const IsarDailyStatisticsService();

  Isar get db => Dbs().main;

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
    db.writeTxnSync(() => collection.putSync(data as IsarDailyStatistics));
  }

  @override
  StreamSubscription<StatisticsDailyData> watch(
    void Function(StatisticsDailyData d) f, [
    bool fire = false,
  ]) => collection
      .watchObjectLazy(0, fireImmediately: fire)
      .map((e) => current)
      .listen(f);
}

class IsarBlacklistedDirectoryService implements BlacklistedDirectoryService {
  IsarBlacklistedDirectoryService();

  Isar get db => Dbs().blacklisted;

  IsarCollection<IsarDailyStatistics> get collection => db.isarDailyStatistics;

  @override
  late final IsarSourceStorage<
    String,
    BlacklistedDirectoryData,
    IsarBlacklistedDirectory
  >
  backingStorage = IsarSourceStorage(
    db,
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

class IsarDirectoryMetadataCache extends MapStorage<String, DirectoryMetadata>
    implements DirectoryMetadataCache {
  IsarDirectoryMetadataCache(super.getKey);

  // @override
  // DirectoryMetadata getOrCreate(String id) {
  //   var d = get(id);
  //   if (d == null) {
  //     d = IsarDirectoryMetadata(
  //       isarId: null,
  //       categoryName: id,
  //       time: DateTime.now(),
  //       flags: 0,
  //     );

  //     db.writeTxnSync(
  //       () => collection.putByCategoryNameSync(d! as IsarDirectoryMetadata),
  //     );
  //   }

  //   return d;
  // }

  // @override
  // void put(
  //   String id, {
  //   required bool blur,
  //   required bool auth,
  //   required bool sticky,
  // }) {
  //   if (id.isEmpty) {
  //     return;
  //   }

  //   db.writeTxnSync(
  //     () {
  //       collection.putByCategoryNameSync(
  //         IsarDirectoryMetadata(
  //           categoryName: id,
  //           time: DateTime.now(),
  //           flags: IsarDirectoryMetadata.makeFlags(
  //             requireAuth: auth,
  //             sticky: sticky,
  //             blur: blur,
  //           ),
  //           isarId: null,
  //         ),
  //       );
  //     },
  //   );
  // }

  // @override
  // StreamSubscription<void> watch(
  //   void Function(void p1) f, [
  //   bool fire = false,
  // ]) =>
  //     collection.watchLazy(fireImmediately: fire).listen(f);
}

class IsarDirectoryMetadataService implements DirectoryMetadataService {
  IsarDirectoryMetadataService();

  Isar get db => Dbs().blacklisted;

  IsarCollection<IsarDirectoryMetadata> get collection =>
      db.isarDirectoryMetadatas;

  @override
  final IsarDirectoryMetadataCache cache = IsarDirectoryMetadataCache(
    (e) => e.categoryName,
  );

  @override
  void addAll(List<DirectoryMetadata> data) {
    db.writeTxnSync(() {
      collection.putAllByCategoryNameSync(data.cast());
      cache.addAll(data);
    });
  }
}

class IsarThumbnailService implements ThumbnailService {
  const IsarThumbnailService();

  Isar get db => Dbs().thumbnail!;

  IsarCollection<IsarThumbnail> get collection => db.isarThumbnails;

  @override
  ThumbnailData? get(int id) => collection.getSync(id);

  @override
  void clear() {
    db.writeTxnSync(() => collection.clearSync());
  }

  @override
  void delete(int id) => db.writeTxnSync(() => collection.deleteSync(id));

  @override
  void addAll(List<ThumbId> l) {
    if (collection.countSync() >= 3000) {
      final List<int> toDelete = db.writeTxnSync(() {
        final toDelete = collection
            .where()
            .sortByUpdatedAt()
            .limit(l.length)
            .findAllSync()
            .map((e) => e.id)
            .toList();

        if (toDelete.isEmpty) {
          return [];
        }

        collection.deleteAllSync(toDelete);

        return toDelete;
      });

      ThumbsApi.safe()?.removeAll(toDelete);
    }

    db.writeTxnSync(() {
      collection.putAllSync(
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

class IsarFilesGridSettingsData implements GridSettingsData<FilesData> {
  const IsarFilesGridSettingsData();

  Isar get db => Dbs().main;

  IsarCollection<IsarGridSettingsFiles> get collection =>
      db.isarGridSettingsFiles;

  @override
  ShellConfigurationData get current =>
      collection.getSync(0) ??
      IsarGridSettingsFiles(
        aspectRatio: GridAspectRatio.one,
        columns: io.Platform.isAndroid ? GridColumn.three : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: true,
      );

  @override
  set current(ShellConfigurationData d) {
    db.writeTxnSync(() => collection.putSync(d as IsarGridSettingsFiles));
  }

  @override
  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObject(0, fireImmediately: fire)
      .map((event) => event ?? current)
      .listen(f);
}

class IsarFavoritesGridSettingsData
    implements GridSettingsData<FavoritePostsData> {
  const IsarFavoritesGridSettingsData();

  Isar get db => Dbs().main;

  IsarCollection<IsarGridSettingsFavorites> get collection =>
      db.isarGridSettingsFavorites;

  @override
  ShellConfigurationData get current =>
      collection.getSync(0) ??
      const IsarGridSettingsFavorites(
        aspectRatio: GridAspectRatio.one,
        columns: GridColumn.five,
        layoutType: GridLayoutType.gridQuilted,
        hideName: true,
      );

  @override
  set current(ShellConfigurationData d) {
    db.writeTxnSync(() => collection.putSync(d as IsarGridSettingsFavorites));
  }

  @override
  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObject(0, fireImmediately: fire)
      .map((event) => event ?? current)
      .listen(f);
}

class IsarDirectoriesGridSettingsData
    implements GridSettingsData<DirectoriesData> {
  const IsarDirectoriesGridSettingsData();

  Isar get db => Dbs().main;

  IsarCollection<IsarGridSettingsDirectories> get collection =>
      db.isarGridSettingsDirectories;

  @override
  ShellConfigurationData get current =>
      collection.getSync(0) ??
      IsarGridSettingsDirectories(
        aspectRatio: GridAspectRatio.oneTwo,
        columns: io.Platform.isAndroid ? GridColumn.three : GridColumn.six,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  set current(ShellConfigurationData d) {
    db.writeTxnSync(() => collection.putSync(d as IsarGridSettingsDirectories));
  }

  @override
  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObject(0, fireImmediately: fire)
      .map((event) => event ?? current)
      .listen(f);
}

class IsarBooruGridSettingsData implements GridSettingsData<BooruData> {
  const IsarBooruGridSettingsData();

  Isar get db => Dbs().main;

  IsarCollection<IsarGridSettingsBooru> get collection =>
      db.isarGridSettingsBoorus;

  @override
  ShellConfigurationData get current =>
      collection.getSync(0) ??
      IsarGridSettingsBooru(
        aspectRatio: GridAspectRatio.one,
        columns: io.Platform.isAndroid ? GridColumn.two : GridColumn.six,
        layoutType: GridLayoutType.gridQuilted,
        hideName: true,
      );

  @override
  set current(ShellConfigurationData d) {
    db.writeTxnSync(() => collection.putSync(d as IsarGridSettingsBooru));
  }

  @override
  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData p1) f, [
    bool fire = false,
  ]) => collection
      .watchObject(0, fireImmediately: fire)
      .map((event) => event ?? current)
      .listen(f);
}

class IsarGridSettinsService implements GridSettingsService {
  const IsarGridSettinsService();

  @override
  GridSettingsData<BooruData> get booru => const IsarBooruGridSettingsData();

  @override
  GridSettingsData<DirectoriesData> get directories =>
      const IsarDirectoriesGridSettingsData();

  @override
  GridSettingsData<FavoritePostsData> get favoritePosts =>
      const IsarFavoritesGridSettingsData();

  @override
  GridSettingsData<FilesData> get files => const IsarFilesGridSettingsData();
}

class IsarLocalTagsService implements LocalTagsService {
  const IsarLocalTagsService();

  Isar get db => Dbs().localTags;

  IsarCollection<IsarLocalTags> get collection => db.isarLocalTags;
  IsarCollection<IsarLocalTagDictionary> get collectionDict =>
      db.isarLocalTagDictionarys;

  @override
  List<TagData> mostFrequent(int count) => count.isNegative
      ? collectionDict
            .where()
            .sortByFrequencyDesc()
            .limit(100)
            .findAllSync()
            .map(
              (e) => TagData(
                tag: e.tag,
                count: e.frequency,
                time: null,
                type: TagType.normal,
              ),
            )
            .toList()
      : collectionDict
            .where()
            .sortByFrequencyDesc()
            .limit(count)
            .findAllSync()
            .map(
              (e) => TagData(
                tag: e.tag,
                count: e.frequency,
                time: null,
                type: TagType.normal,
              ),
            )
            .toList();

  @override
  void addFrequency(List<String> tags) {
    db.writeTxnSync(
      () => collectionDict.putAllSync(
        tags
            .map(
              (e) => IsarLocalTagDictionary(
                e,
                (collectionDict.getByTagSync(e)?.frequency ?? 0) + 1,
                isarId: null,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Future<List<TagData>> complete(String string) async {
    final result = collectionDict
        .filter()
        .tagContains(string)
        .sortByFrequencyDesc()
        .limit(10)
        .findAllSync();

    return result
        .map(
          (e) => TagData(
            tag: e.tag,
            count: e.frequency,
            type: TagType.normal,
            time: null,
          ),
        )
        .toList();
  }

  @override
  int get count => collection.countSync();

  /// Returns tags for the [filename], or empty list if there are none.
  @override
  List<String> get(String filename) {
    return collection.getByFilenameSync(filename)?.tags ?? [];
  }

  @override
  void add(String filename, List<String> tags) {
    db.writeTxnSync(() {
      collection.putByFilenameSync(
        IsarLocalTags(filename: filename, tags: tags, isarId: null),
      );
    });
  }

  @override
  void addAll(List<LocalTagsData> tags) {
    db.writeTxnSync(() {
      collection.putAllByFilenameSync(tags.cast());
    });
  }

  @override
  void addMultiple(List<String> filenames, String tag) {
    if (filenames.isEmpty || tag.isEmpty) {
      return;
    }

    final newTags = collection
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

    return db.writeTxnSync(() {
      collection.putAllByFilenameSync(newTags);
    });
  }

  @override
  void delete(String filename) {
    db.writeTxnSync(() {
      collection.deleteByFilenameSync(filename);
    });
  }

  @override
  void removeSingle(List<String> filenames, String tag) {
    final List<IsarLocalTags> newTags = [];

    for (final e
        in collection.getAllByFilenameSync(filenames).cast<LocalTagsData>()) {
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

    return db.writeTxnSync(() {
      collection.putAllByFilenameSync(newTags);
    });
  }

  @override
  StreamSubscription<LocalTagsData> watch(
    String filename,
    void Function(LocalTagsData) f,
  ) => collection
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

  Isar get db => Dbs().localTags;

  IsarCollection<DirectoryTag> get collection => db.directoryTags;

  @override
  String? get(String bucketId) => collection.getByBuckedIdSync(bucketId)?.tag;

  @override
  bool searchByTag(String tag) =>
      collection.filter().tagStartsWith(tag).limit(1).findFirstSync() != null;

  @override
  void add(Iterable<String> bucketIds, String tag) {
    db.writeTxnSync(
      () => collection.putAllSync(
        bucketIds
            .map((e) => DirectoryTag(buckedId: e, tag: tag, isarId: null))
            .toList(),
      ),
    );
  }

  @override
  void delete(Iterable<String> buckedIds) {
    db.writeTxnSync(
      () => collection.deleteAllByBuckedIdSync(buckedIds.toList()),
    );
  }
}

class IsarTagManager implements TagManagerService {
  const IsarTagManager();

  @override
  IsarBooruTagging<Excluded> get excluded =>
      const IsarBooruTagging(mode: TagType.excluded);
  @override
  IsarBooruTagging<Latest> get latest =>
      const IsarBooruTagging(mode: TagType.normal);
  @override
  IsarBooruTagging<Pinned> get pinned =>
      const IsarBooruTagging(mode: TagType.pinned);
}

class IsarBooruTagging<T extends BooruTaggingType> implements BooruTagging<T> {
  const IsarBooruTagging({required this.mode});

  final TagType mode;
  Isar get tagDb => Dbs().localTags;

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
  Future<List<TagData>> complete(String string) => Future.value(
    tagDb.isarTags
        .filter()
        .tagStartsWith(string)
        .typeEqualTo(mode)
        .sortByTimeDesc()
        .limit(15)
        .findAllSync(),
  );

  @override
  Future<List<TagData>> search(String string, [int limit = 15]) => Future.value(
    tagDb.isarTags
        .filter()
        .tagContains(string, caseSensitive: false)
        .typeEqualTo(mode)
        .sortByTimeDesc()
        .limit(limit)
        .findAllSync(),
  );

  @override
  void add(String t) {
    tagDb.writeTxnSync(
      () => tagDb.isarTags.putByTagTypeSync(
        IsarTag(
          time: DateTime.now(),
          tag: t.trim(),
          type: mode,
          isarId: null,
          count: 0,
        ),
      ),
    );
  }

  @override
  void delete(String t) {
    tagDb.writeTxnSync(() => tagDb.isarTags.deleteByTagTypeSync(t, mode));
  }

  @override
  void clear() {
    tagDb.writeTxnSync(
      () => tagDb.isarTags.filter().typeEqualTo(mode).deleteAllSync(),
    );
  }

  @override
  Stream<int> get events => tagDb.isarTags.watchLazy().map(
    (_) => tagDb.isarTags.filter().typeEqualTo(mode).countSync(),
  );

  @override
  int get count => tagDb.isarTags.filter().typeEqualTo(mode).countSync();

  // @override
  // StreamSubscription<void> watch(void Function(void) f, [bool fire = false]) {
  //   return tagDb.isarTags.watchLazy(fireImmediately: fire).listen(f);
  // }

  // @override
  // StreamSubscription<int> watchCount(
  //   void Function(int) f, [
  //   bool fire = false,
  // ]) {
  //   return tagDb.isarTags
  //       .watchLazy(fireImmediately: fire)
  //       .map((_) => tagDb.isarTags.filter().typeEqualTo(mode).countSync())
  //       .listen(f);
  // }

  // @override
  // StreamSubscription<List<ImageTag>> watchImage(
  //   List<String> tags,
  //   void Function(List<ImageTag> l) f, {
  //   bool fire = false,
  // }) {
  //   return tagDb.isarTags.watchLazy().map<List<ImageTag>>((event) {
  //     return tags
  //         .map(
  //           (e) => ImageTag(
  //             e,
  //             type: tagDb.isarTags.getByTagTypeSync(e, TagType.pinned) != null
  //                 ? ImageTagType.favorite
  //                 : tagDb.isarTags.getByTagTypeSync(e, TagType.excluded) != null
  //                     ? ImageTagType.excluded
  //                     : ImageTagType.normal,
  //           ),
  //         )
  //         .toList();
  //   }).listen(f);
  // }

  // @override
  // StreamSubscription<List<ImageTag>> watchImageLocal(
  //   String filename,
  //   void Function(List<ImageTag> l) f, {
  //   bool fire = false,
  // }) {
  //   return StreamGroup.merge<void>([
  //     Dbs()
  //         .localTags
  //         .isarLocalTags
  //         .where()
  //         .filenameEqualTo(filename)
  //         .watchLazy(),
  //     tagDb.isarTags.watchLazy(),
  //   ]).map<List<ImageTag>>((event) {
  //     final t = Dbs().localTags.isarLocalTags.getByFilenameSync(filename)?.tags;
  //     if (t == null) {
  //       return const [];
  //     }

  //     return t
  //         .map(
  //           (e) => ImageTag(
  //             e,
  //             type: tagDb.isarTags.getByTagTypeSync(e, TagType.pinned) != null
  //                 ? ImageTagType.favorite
  //                 : tagDb.isarTags.getByTagTypeSync(e, TagType.excluded) != null
  //                     ? ImageTagType.excluded
  //                     : ImageTagType.normal,
  //           ),
  //         )
  //         .toList();
  //   }).listen(f);
  // }
}

class IsarGridStateBooruService implements GridBookmarkService {
  const IsarGridStateBooruService();

  Isar get db => Dbs().main;

  IsarCollection<IsarBookmark> get collection => db.isarBookmarks;

  @override
  int get count => collection.countSync();

  @override
  List<GridBookmark> get all =>
      collection.where().sortByTimeDesc().findAllSync();

  @override
  void add(GridBookmark state) {
    db.writeTxnSync(() => collection.putByNameSync(state as IsarBookmark));
  }

  @override
  List<GridBookmark> firstNumber(int n) {
    if (n.isNegative) {
      return all;
    } else if (n == 0) {
      return const [];
    }

    return collection.where().sortByTimeDesc().limit(n).findAllSync();
  }

  @override
  GridBookmark? get(String name) => collection.getByNameSync(name);

  @override
  GridBookmark? getFirstByTags(String tags, Booru preferBooru) => collection
      .filter()
      .tagsStartsWith(tags)
      .booruEqualTo(preferBooru)
      .or()
      .tagsStartsWith(tags)
      .not()
      .booruEqualTo(preferBooru)
      .limit(1)
      .findFirstSync();

  @override
  List<GridBookmark> complete(String str) =>
      collection.filter().tagsContains(str).limit(15).findAllSync();

  @override
  void delete(String name) {
    db.writeTxnSync(() => collection.deleteByNameSync(name));
  }

  @override
  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]) =>
      collection
          .watchLazy(fireImmediately: fire)
          .map<int>((e) => count)
          .listen(f);
}

class IsarSecondaryGridService implements SecondaryGridHandle {
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
    final dbMain = Dbs().openPrimaryGrid(booru, DbPaths());
    final dbSecondary = Dbs().openSecondaryGridName(name, create, DbPaths());

    return IsarSecondaryGridService._(dbSecondary, dbMain, name);
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
    GridState? state = _mainGrid.isarGridStates.getByNameSync(
      _secondaryGrid.name,
    );
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
    PagingEntry entry,
    String tags, {
    void Function(GridPostSource)? onNextCompleted,
    void Function(GridPostSource)? onClearRefreshCompleted,
  }) => IsarCurrentBooruSource(
    db: _secondaryGrid,
    api: api,
    entry: entry,
    tags: tags,
    onClearRefreshCompleted: onClearRefreshCompleted,
    onNextCompleted: onNextCompleted,
    safeMode_: () => currentState.safeMode,
    filters: [
      if (HiddenBooruPostsService.available)
        (p) => !const HiddenBooruPostsService().isHidden(p.id, p.booru),
    ],
  );

  @override
  StreamSubscription<GridState> watch(
    void Function(GridState s) f, [
    bool fire = false,
  ]) => _mainGrid.isarGridStates
      .where()
      .nameEqualTo(name)
      .watchLazy(fireImmediately: fire)
      .map((e) => currentState)
      .listen(f);
}

class IsarMainGridService implements MainGridHandle {
  const IsarMainGridService._(this._mainGrid);

  factory IsarMainGridService.booru(Booru booru) {
    final db = Dbs().openPrimaryGrid(booru, DbPaths());

    return IsarMainGridService._(db);
  }

  @override
  DateTime get time =>
      _mainGrid.isarGridTimes.getSync(0)?.time ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  set time(DateTime d) => _mainGrid.writeTxnSync(
    () => _mainGrid.isarGridTimes.putSync(IsarGridTime(d)),
  );

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
    PagingEntry entry, {
    void Function(GridPostSource)? onNextCompleted,
    void Function(GridPostSource)? onClearRefreshCompleted,
  }) => IsarCurrentBooruSource(
    db: _mainGrid,
    api: api,
    entry: entry,
    tags: "",
    safeMode_: () => const SettingsService().current.safeMode,
    onClearRefreshCompleted: onClearRefreshCompleted,
    onNextCompleted: onNextCompleted,
    filters: [
      if (HiddenBooruPostsService.available)
        (p) => !const HiddenBooruPostsService().isHidden(p.id, p.booru),
    ],
  );
}

class IsarVisitedPostsService implements VisitedPostsService {
  const IsarVisitedPostsService();

  Isar get db => Dbs().main;

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
    final (ids, boorus) = _foldTulpeListFnc(
      visitedPosts,
      (e) => (e.id, e.booru),
    );

    db.writeTxnSync(() => collection.deleteAllByIdBooruSync(ids, boorus));
  }

  @override
  void clear() => db.writeTxnSync(() => collection.clearSync());

  @override
  StreamSubscription<void> watch(void Function(void p1) f) =>
      collection.watchLazy().listen(f);
}

// (List<A>, List<B>) _foldTulpeList<A, B>(Iterable<(A, B)> t) {
//   final (listA, listB) = t.fold((<A>[], <B>[]), (lists, e) {
//     lists.$1.add(e.$1);
//     lists.$2.add(e.$2);

//     return lists;
//   });

//   return (listA, listB);
// }

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

class IsarHottestTagsService implements HottestTagsService {
  const IsarHottestTagsService();

  Isar get db => Dbs().localTags;

  IsarCollection<IsarHottestTag> get collection => db.isarHottestTags;

  @override
  DateTime? refreshedAt(Booru booru) =>
      db.isarHottestTagDates.getByBooruSync(booru)?.date;

  @override
  List<HottestTag> all(Booru booru) =>
      collection.where().booruEqualTo(booru).findAllSync();

  @override
  void replace(List<HottestTag> tags, Booru booru) {
    db.writeTxnSync(() {
      collection.where().booruEqualTo(booru).deleteAllSync();
      collection.putAllSync(tags.cast());

      db.isarHottestTagDates.putByBooruSync(
        IsarHottestTagDate(isarId: null, booru: booru, date: DateTime.now()),
      );
    });
  }

  @override
  StreamSubscription<void> watch(Booru booru, void Function(void p1) f) =>
      collection.where().booruEqualTo(booru).watchLazy().listen(f);
}

class IsarColorsNamesService implements ColorsNamesService {
  IsarColorsNamesService();

  Isar get db => Dbs().main;

  IsarCollection<IsarColorsNamesData> get collection => db.isarColorsNamesDatas;

  @override
  late IsarColorsNamesData current =
      collection.getSync(0) ??
      const IsarColorsNamesData(
        red: "",
        blue: "",
        yellow: "",
        green: "",
        purple: "",
        orange: "",
        pink: "",
        white: "",
        brown: "",
        black: "",
      );

  @override
  Stream<ColorsNamesData> get events =>
      collection.watchObjectLazy(0).map((_) => current);

  @override
  void add(ColorsNamesData data) {
    current = data as IsarColorsNamesData;

    db.writeTxnSync(() {
      collection.putSync(data);
    });
  }
}
