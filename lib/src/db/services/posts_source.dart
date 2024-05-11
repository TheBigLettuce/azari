// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/pages/home.dart";
import "package:isar/isar.dart";

abstract interface class PostsSourceService<T>
    extends FilteringResourceSource<T> {
  const PostsSourceService();

  String get tags;
  set tags(String t);

  void clear();
}

class _IsarCollectionIterator<T> implements Iterator<T> {
  _IsarCollectionIterator(this.collection);

  final IsarCollection<T> collection;

  final List<T> _buffer = [];
  int _cursor = -1;
  bool _done = false;

  @override
  T get current => _buffer[_cursor];

  @override
  bool moveNext() {
    if (_done) {
      return false;
    }

    if (_buffer.isNotEmpty && _cursor != _buffer.length) {
      _cursor += 1;
      return true;
    }

    final ret =
        collection.where().offset(_buffer.length).limit(40).findAllSync();
    if (ret.isEmpty) {
      _cursor = -1;
      _buffer.clear();
      return !(_done = true);
    }

    _cursor = 0;
    _buffer.clear();
    _buffer.addAll(ret);

    return true;
  }
}

class IsarSourceStorage<T extends Post> extends SourceStorage<T> {
  IsarSourceStorage(this.db, this.txPut);

  final Isar db;
  final void Function(Isar db, List<T>) txPut;

  IsarCollection<T> get _collection => db.collection<T>();

  @override
  int get count => _collection.countSync();

  @override
  Iterator<T> get iterator => _IsarCollectionIterator(_collection);

  @override
  void add(T e) => db.writeTxnSync(() => txPut(db, [e]));

  @override
  void addAll(List<T> l) => txPut(db, l);

  @override
  void clear() => db.writeTxnSync(() => _collection.clearSync());

  @override
  T? get(int idx) => _collection.getSync(idx + 1);

  @override
  void removeAll(List<int> idx) {
    db.writeTxnSync(() => _collection.deleteAllSync(idx));
  }

  @override
  void destroy() => db.close(deleteFromDisk: true);

  @override
  T operator [](int index) => get(index)!;

  @override
  void operator []=(int index, T value) =>
      db.writeTxnSync(() => txPut(db, [value]));
}

class IsarCurrentBooruSource extends PostsSourceService<Post> {
  IsarCurrentBooruSource({
    required Isar db,
    required void Function(Isar db, List<PostIsar>) txPut,
    required this.api,
    required this.excluded,
    required this.entry,
    required this.tags,
    required HiddenBooruPostService hiddenBooru,
  })  : backingStorage = IsarSourceStorage(db, txPut),
        filters = [(p) => !hiddenBooru.isHidden(p.id, p.booru)];

  final BooruAPI api;
  final BooruTagging excluded;
  final PagingEntry entry;

  @override
  final IsarSourceStorage<PostIsar> backingStorage;

  @override
  StreamSubscription<int> watch(void Function(int p1) f) {
    throw UnimplementedError();
  }

  @override
  final List<FilterFnc<Post>> filters;

  @override
  String tags;

  int? currentSkipped;

  @override
  int get count => backingStorage.count;

  @override
  void destroy() => backingStorage.destroy();

  @override
  Post? forIdx(int idx) => backingStorage.get(idx);

  @override
  Post forIdxUnsafe(int idx) => forIdx(idx)!;

  @override
  void clear() => backingStorage.clear();

  @override
  Future<int> clearRefresh() async {
    clear();

    StatisticsGeneralService.db().current.add(refreshes: 1).save();

    entry.updateTime();

    final list = await api.page(0, "", excluded);
    entry.setOffset(0);
    currentSkipped = list.$2;
    backingStorage.addAll(PostIsar.copyTo(filter(list.$1)));

    entry.reachedEnd = false;

    return count;
  }

  @override
  Future<int> next([int repeatCount = 0]) async {
    if (repeatCount >= 3) {
      return count;
    }

    if (entry.reachedEnd) {
      return count;
    }
    final p = forIdx(count - 1);
    if (p == null) {
      return count;
    }

    try {
      final list = await api.fromPost(
        currentSkipped != null && currentSkipped! < p.id
            ? currentSkipped!
            : p.id,
        "",
        excluded,
      );

      if (list.$1.isEmpty && currentSkipped == null) {
        entry.reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = count;
        backingStorage.addAll(PostIsar.copyTo(filter(list.$1)));

        entry.updateTime();

        if (count - oldCount < 3) {
          return next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return next(repeatCount + 1);
    }

    return count;
  }
}
