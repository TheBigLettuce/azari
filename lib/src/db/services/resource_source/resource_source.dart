// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";

typedef FilterFnc<T> = bool Function(T);

extension ResourceSourceExt<K, V> on ResourceSource<K, V> {
  V? forIdx(K idx) => backingStorage.get(idx);
  V forIdxUnsafe(K idx) => backingStorage[idx];

  int get count => backingStorage.count;
}

/// [SortingResourceSource] exists as an optimization,
/// sometimes [ResourceSource] gets data from a third source which has optimized sorting.
/// [ChainedFilterResourceSource] uses [clearRefreshSorting] and [nextSorting] when available.
abstract interface class SortingResourceSource<K, V>
    extends ResourceSource<K, V> {
  SortingMode get sortingMode;
  set sortingMode(SortingMode s);

  Future<int> clearRefreshSilent();
}

/// Helper class to make internal filtering of values simpler.
abstract class FilteringResourceSource<K, V> implements ResourceSource<K, V> {
  const FilteringResourceSource();

  List<FilterFnc<V>> get filters;

  Iterable<V> filter(Iterable<V> l) => l.where((element) {
        for (final e in filters) {
          final res = e(element);
          if (!res) {
            return false;
          }
        }

        return true;
      });
}

/// A generic way of loading data into [SourceStorage].
abstract interface class ResourceSource<K, V> {
  const ResourceSource();

  factory ResourceSource.empty(K Function(V) getKey) = _EmptyResourceSource;
  factory ResourceSource.external(ReadOnlyStorage<K, V> backingStorage) =
      _ExternalResourceSource;

  SourceStorage<K, V> get backingStorage;

  RefreshingProgress get progress;

  /// Not all implementations of [ResourceSource] can have useful [next] implementation.
  /// In such a case, [hasNext] should return true and other classes should not call [next]
  /// if [hasNext] returns false.
  bool get hasNext;

  Future<int> clearRefresh();

  /// If [next] is not needed for a particular [ResourceSource], then it should return
  /// Future.value([count]);
  Future<int> next();

  void destroy();
}

abstract class RefreshingProgress {
  const factory RefreshingProgress.empty() = _EmptyProgress;

  Object? get error;

  bool get inRefreshing;
  bool get canLoadMore;

  StreamSubscription<bool> watch(void Function(bool) f);
}

class _ExternalResourceSource<K, V> implements ResourceSource<K, V> {
  _ExternalResourceSource(ReadOnlyStorage<K, V> backingStorage_)
      : backingStorage = backingStorage_ is SourceStorage<K, V>
            ? backingStorage_
            : _WrappedReadOnlyStorage(backingStorage_);

  @override
  final SourceStorage<K, V> backingStorage;

  @override
  bool get hasNext => false;

  @override
  Future<int> clearRefresh() => Future.value(backingStorage.count);

  @override
  Future<int> next() => Future.value(backingStorage.count);

  @override
  RefreshingProgress get progress => const _EmptyProgress();

  @override
  void destroy() {}
}

class _WrappedReadOnlyStorage<K, V> extends SourceStorage<K, V> {
  const _WrappedReadOnlyStorage(this.backingStorage);

  final ReadOnlyStorage<K, V> backingStorage;

  @override
  V operator [](K index) => backingStorage[index];

  @override
  int get count => backingStorage.count;

  @override
  Stream<int> get countEvents => throw UnimplementedError();

  @override
  V? get(K idx) => backingStorage.get(idx);

  @override
  Iterator<V> get iterator => backingStorage.iterator;

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      backingStorage.watch(f);

  @override
  void operator []=(K index, V value) {}

  @override
  void add(V e, [bool silent = false]) {}

  @override
  void addAll(Iterable<V> l, [bool silent = false]) {}

  @override
  void clear([bool silent = false]) {}

  @override
  void destroy() {}

  @override
  List<V> removeAll(Iterable<K> idx, [bool silent = false]) {
    return const [];
  }

  @override
  Iterable<V> get reversed => this;

  @override
  Iterable<V> trySorted(SortingMode sort) => this;
}

class _EmptyProgress implements RefreshingProgress {
  const _EmptyProgress();

  @override
  Object? get error => null;

  @override
  bool get inRefreshing => false;

  @override
  bool get canLoadMore => false;

  @override
  StreamSubscription<bool> watch(void Function(bool p1) f) =>
      const Stream<bool>.empty().listen(f);
}

class _EmptyResourceSource<K, V> extends ResourceSource<K, V> {
  _EmptyResourceSource(this.getKey);

  final K Function(V) getKey;

  @override
  bool get hasNext => false;

  @override
  late final SourceStorage<K, V> backingStorage = MapStorage(getKey);

  @override
  Future<int> clearRefresh() => Future.value(count);

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    backingStorage.destroy();
  }

  @override
  RefreshingProgress get progress => const _EmptyProgress();
}
