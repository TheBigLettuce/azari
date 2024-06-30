// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class GenericListSource<V> implements ResourceSource<int, V> {
  GenericListSource(
    this._clearRefresh, {
    Future<List<V>> Function()? next,
    WatchFire<int>? watchCount,
  }) : _next = next {
    if (watchCount != null) {
      _subscription = watchCount((count) {
        clearRefresh();
      });
    } else {
      _subscription = null;
    }
  }

  final Future<List<V>> Function() _clearRefresh;
  final Future<List<V>> Function()? _next;

  // final WatchFire<int>? watchCount;

  late final StreamSubscription<int>? _subscription;

  @override
  final ListStorage<V> backingStorage = ListStorage();

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  bool get hasNext => _next != null;

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    backingStorage.clear();

    try {
      final ret = await _clearRefresh();
      if (ret.isEmpty) {
        progress.canLoadMore = false;
      } else {
        backingStorage.addAll(ret);
      }
    } catch (e) {
      progress.error = e;
    }

    progress.inRefreshing = false;

    return count;
  }

  @override
  Future<int> next() async {
    if (_next == null || progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    try {
      final ret = await _next();
      if (ret.isEmpty) {
        progress.canLoadMore = false;
      } else {
        backingStorage.addAll(ret);
      }
    } catch (e) {
      progress.error = e;
    }

    progress.inRefreshing = false;

    return count;
  }

  @override
  void destroy() {
    backingStorage.destroy();
    progress.close();
    _subscription?.cancel();
  }
}

class MapStorage<K, V> extends SourceStorage<K, V> {
  MapStorage(
    this.getKey, {
    Map<K, V>? providedMap,
    this.sortFnc,
  }) : map_ = providedMap ?? {};

  final Iterable<V> Function(MapStorage<K, V> instance, SortingMode sort)?
      sortFnc;

  @override
  Iterable<V> trySorted(SortingMode sort) =>
      sortFnc == null ? this : sortFnc!(this, sort);

  final StreamController<int> _events = StreamController.broadcast();

  final Map<K, V> map_;
  final K Function(V) getKey;

  @override
  int get count => map_.length;

  @override
  Iterator<V> get iterator => map_.values.iterator;

  @override
  Iterable<V> get reversed => map_.values.toList().reversed;

  @override
  V? get(K idx) => map_[idx];

  @override
  void add(V e, [bool silent = false]) {
    map_[getKey(e)] = e;

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void addAll(Iterable<V> l, [bool silent = false]) {
    for (final e in l) {
      add(e, true);
    }

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void clear([bool silent = false]) {
    map_.clear();

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  List<V> removeAll(Iterable<K> idx, [bool silent = false]) {
    final l = <V>[];

    for (final e in idx) {
      final v = map_.remove(e);
      if (v != null) {
        l.add(v);
      }
    }

    if (!silent) {
      _events.add(count);
    }

    return l;
  }

  @override
  V operator [](K index) => get(index)!;

  @override
  void operator []=(K index, V value) {
    map_[index] = value;

    _events.add(count);
  }

  @override
  void destroy() {
    _events.close();
  }

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _events.stream.transform<int>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<int>(sync: true);
          controller.onListen = () {
            final subscription = input.listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
              cancelOnError: cancelOnError,
            );
            controller
              ..onPause = subscription.pause
              ..onResume = subscription.resume
              ..onCancel = subscription.cancel;
          };

          if (fire) {
            Timer.run(() {
              controller.add(count);
            });
          }

          return controller.stream.listen(null);
        }),
      ).listen(f);
}

class ListStorage<V> extends SourceStorage<int, V> {
  ListStorage({this.sortFnc, this.reverse = false});

  final Iterable<V> Function(ListStorage<V> instance, SortingMode sort)?
      sortFnc;

  final StreamController<int> _events = StreamController.broadcast();

  final List<V> list = [];

  final bool reverse;

  @override
  int get count => list.length;

  @override
  Iterator<V> get iterator => list.iterator;

  @override
  Iterable<V> get reversed => list.reversed;

  @override
  Iterable<V> trySorted(SortingMode sort) =>
      sortFnc == null ? this : sortFnc!(this, sort);

  @override
  V? get(int idx) =>
      idx >= count ? null : list[reverse ? list.length - 1 - idx : idx];

  @override
  void add(V e, [bool silent = false]) {
    list.add(e);

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void addAll(Iterable<V> l, [bool silent = false]) {
    list.addAll(l);

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  void clear([bool silent = false]) {
    list.clear();

    if (!silent) {
      _events.add(count);
    }
  }

  @override
  List<V> removeAll(Iterable<int> idx, [bool silent = false]) {
    final l = <V>[];

    for (final e in idx) {
      if (e < list.length) {
        l.add(list.removeAt(e));
      }
    }

    if (!silent) {
      _events.add(count);
    }

    return l;
  }

  @override
  V operator [](int index) => get(index)!;

  @override
  void operator []=(int index, V value) => list[index] = value;

  @override
  void destroy() {
    clear();

    _events.close();
  }

  @override
  StreamSubscription<int> watch(void Function(int p1) f, [bool fire = false]) =>
      _events.stream.transform<int>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<int>(sync: true);
          controller.onListen = () {
            final subscription = input.listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
              cancelOnError: cancelOnError,
            );
            controller
              ..onPause = subscription.pause
              ..onResume = subscription.resume
              ..onCancel = subscription.cancel;
          };

          if (fire) {
            Timer.run(() {
              controller.add(count);
            });
          }

          return controller.stream.listen(null);
        }),
      ).listen(f);
}

class ClosableRefreshProgress implements RefreshingProgress {
  ClosableRefreshProgress({
    this.canLoadMore = true,
  });

  final _events = StreamController<bool>.broadcast();

  bool _refresh = false;

  @override
  Object? error;

  @override
  bool get inRefreshing => _refresh;

  @override
  bool canLoadMore;

  set inRefreshing(bool b) {
    _refresh = b;

    if (!_events.isClosed) {
      _events.add(b);
    }
  }

  @override
  StreamSubscription<bool> watch(void Function(bool p1) f) =>
      _events.stream.listen(f);

  void close() {
    _events.close();
  }
}
