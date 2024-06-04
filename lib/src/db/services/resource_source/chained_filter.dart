// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";

typedef ChainedFilterFnc<V> = (Iterable<V>, dynamic) Function(
  Iterable<V> e,
  FilteringMode filteringMode,
  SortingMode sortingMode,
  bool end, [
  dynamic data,
]);

/// A generic way for filtering data.
class ChainedFilterResourceSource<K, V> implements ResourceSource<int, V> {
  ChainedFilterResourceSource(
    this._original,
    this._filterStorage, {
    this.prefilter = _doNothing,
    this.onCompletelyEmpty = _doNothing,
    required this.filter,
    required this.allowedFilteringModes,
    required this.allowedSortingModes,
    required FilteringMode initialFilteringMode,
    required SortingMode initialSortingMode,
  })  : assert(
          allowedFilteringModes.isEmpty ||
              allowedFilteringModes.contains(initialFilteringMode),
        ),
        assert(
          allowedSortingModes.isEmpty ||
              allowedSortingModes.contains(initialSortingMode),
        ),
        _mode = initialFilteringMode,
        _sorting = initialSortingMode {
    _originalSubscr = _original.backingStorage.watch((c) {
      clearRefresh();
    });
  }

  factory ChainedFilterResourceSource.basic(
    ResourceSource<K, V> original,
    SourceStorage<int, V> filterStorage, {
    required ChainedFilterFnc<V> filter,
  }) =>
      ChainedFilterResourceSource(
        original,
        filterStorage,
        filter: filter,
        allowedFilteringModes: const {},
        allowedSortingModes: const {},
        initialFilteringMode: FilteringMode.noFilter,
        initialSortingMode: SortingMode.none,
      );

  static void _doNothing() {}

  final ResourceSource<K, V> _original;
  final SourceStorage<int, V> _filterStorage;

  @override
  SourceStorage<int, V> get backingStorage => _filterStorage;

  late final StreamSubscription<int> _originalSubscr;

  final Set<FilteringMode> allowedFilteringModes;
  final Set<SortingMode> allowedSortingModes;

  final StreamController<FilteringMode> _filterEvents =
      StreamController.broadcast();

  final void Function() prefilter;
  final void Function() onCompletelyEmpty;

  FilteringMode _mode;
  SortingMode _sorting;

  FilteringMode get filteringMode => _mode;
  SortingMode get sortingMode => _sorting;

  @override
  RefreshingProgress get progress => _original.progress;

  set filteringMode(FilteringMode f) {
    if (allowedFilteringModes.isEmpty) {
      return;
    }

    if (!allowedFilteringModes.contains(f)) {
      assert(() {
        throw "filteringMode setter called with unknown value";
      }());

      return;
    }

    _mode = f;
    _filterEvents.add(f);

    clearRefresh();
  }

  set sortingMode(SortingMode s) {
    if (allowedSortingModes.isEmpty) {
      return;
    }

    if (!allowedSortingModes.contains(s)) {
      assert(() {
        throw "sortingMode setter called with unknown value";
      }());

      return;
    }

    _sorting = s;

    if (_original is SortingResourceSource<K, V>) {
      _original.clearRefreshSorting(sortingMode);
    } else {
      clearRefresh();
    }
  }

  final ChainedFilterFnc<V> filter;

  @override
  bool get hasNext => false;

  Future<int> refreshOriginal() async {
    await _original.clearRefresh();

    return count;
  }

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }

    backingStorage.clear(true);

    if (_original.backingStorage.count == 0) {
      backingStorage.addAll([]);
      onCompletelyEmpty();
      return 0;
    }

    prefilter();

    dynamic data;

    final buffer = <V>[];

    for (final e in _original is SortingResourceSource<K, V> ||
            sortingMode == SortingMode.none
        ? _original.backingStorage
        : _original.backingStorage.trySorted(sortingMode)) {
      buffer.add(e);

      if (buffer.length == 40) {
        final Iterable<V> filtered;
        (filtered, data) =
            filter(buffer, filteringMode, sortingMode, false, data);

        backingStorage.addAll(filtered, true);
        buffer.clear();
      }
    }

    backingStorage
        .addAll(filter(buffer, filteringMode, sortingMode, true, data).$1);

    return count;
  }

  @override
  Future<int> next() {
    assert(() {
      throw "ChainedFilterResourceSource is currently whole pass only";
    }());

    return Future.value(count);
  }

  @override
  void destroy() {
    _filterEvents.close();
    backingStorage.destroy();
    _originalSubscr.cancel();
  }

  StreamSubscription<FilteringMode> watchFilter(
    void Function(FilteringMode) f,
  ) =>
      _filterEvents.stream.listen(f);
}
