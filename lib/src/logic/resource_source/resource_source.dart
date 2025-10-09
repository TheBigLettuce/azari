// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:flutter/material.dart";

typedef FilterFnc<T> = bool Function(T);

class _ResourceSourceNotifier<K, V> extends InheritedWidget {
  const _ResourceSourceNotifier({
    super.key,
    required this.source,
    required super.child,
  });

  final ResourceSource<K, V> source;

  @override
  bool updateShouldNotify(_ResourceSourceNotifier<K, V> oldWidget) {
    return source != oldWidget.source;
  }
}

extension ResourceSourceExt<K, V> on ResourceSource<K, V> {
  V? forIdx(K idx) => backingStorage.get(idx);
  V forIdxUnsafe(K idx) => backingStorage[idx];

  int get count => backingStorage.count;

  Widget inject(Widget child) {
    return _ResourceSourceNotifier(source: this, child: child);
  }
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

mixin ResourceSourceWatcher<W extends StatefulWidget> on State<W> {
  ResourceSource<dynamic, dynamic>? get source;

  late final StreamSubscription<int>? _resourceSourceEvents;

  void onResourceEvent() {}

  @override
  void initState() {
    super.initState();

    _resourceSourceEvents = source?.backingStorage.watch((_) {
      onResourceEvent();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _resourceSourceEvents?.cancel();

    super.dispose();
  }
}

/// A generic way of loading data into [SourceStorage].
abstract interface class ResourceSource<K, V> {
  const ResourceSource();

  factory ResourceSource.empty(K Function(V) getKey) = _EmptyResourceSource;
  factory ResourceSource.external(
    ReadOnlyStorage<K, V> backingStorage, {
    Iterable<V> Function(SortingMode sort)? trySorted,
  }) = _ExternalResourceSource;

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

  static ResourceSource<K, V>? maybeOf<K, V>(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_ResourceSourceNotifier<K, V>>();

    return widget?.source;
  }
}

abstract class RefreshingProgress {
  const factory RefreshingProgress.empty() = _EmptyProgress;

  Stream<bool> get stream;

  Object? get error;

  bool get inRefreshing;
  bool get canLoadMore;

  StreamSubscription<bool> watch(void Function(bool) f);
}

class _ExternalResourceSource<K, V> implements ResourceSource<K, V> {
  _ExternalResourceSource(
    ReadOnlyStorage<K, V> backingStorage_, {
    Iterable<V> Function(SortingMode sort)? trySorted,
  }) : backingStorage = backingStorage_ is SourceStorage<K, V>
           ? backingStorage_
           : _WrappedReadOnlyStorage(backingStorage_, trySorted);

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
  const _WrappedReadOnlyStorage(this.backingStorage, this.trySorted_);

  final Iterable<V> Function(SortingMode sort)? trySorted_;

  final ReadOnlyStorage<K, V> backingStorage;

  @override
  int indexWhere(bool Function(V element) test, [int start = 0]) =>
      backingStorage.indexWhere(test, start);

  @override
  V operator [](K index) => backingStorage[index];

  @override
  int get count => backingStorage.count;

  @override
  Stream<int> get countEvents => backingStorage.countEvents;

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
  Iterable<V> trySorted(SortingMode sort) => trySorted_?.call(sort) ?? this;
}

class _EmptyProgress implements RefreshingProgress {
  const _EmptyProgress();

  @override
  Object? get error => null;

  @override
  Stream<bool> get stream => const Stream<bool>.empty();

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
