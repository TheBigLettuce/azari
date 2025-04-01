// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:flutter/widgets.dart";

typedef ChainedFilterFnc<V> = (Iterable<V>, dynamic) Function(
  Iterable<V> e,
  FilteringMode filteringMode,
  SortingMode sortingMode,
  bool end, [
  dynamic data,
]);

typedef ChainedFilter<K, V> = ChainedFilterResourceSource<K, V>;

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

  static FilteringData? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_FilteringDataNotifier>();

    return widget?.data;
  }

  final ResourceSource<K, V> _original;
  final SourceStorage<int, V> _filterStorage;

  @override
  SourceStorage<int, V> get backingStorage => _filterStorage;

  late final StreamSubscription<int> _originalSubscr;

  final Set<FilteringMode> allowedFilteringModes;
  final Set<SortingMode> allowedSortingModes;

  final VoidCallback prefilter;
  final VoidCallback onCompletelyEmpty;

  FilteringMode _mode;
  SortingMode _sorting;

  final StreamController<FilteringData> _filterEvents =
      StreamController.broadcast();

  FilteringMode get filteringMode => _mode;
  SortingMode get sortingMode => _sorting;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

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
    _filterEvents.add(FilteringData(_mode, _sorting));

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
    _filterEvents.add(FilteringData(_mode, _sorting));

    if (_original is SortingResourceSource<K, V>) {
      _original.sortingMode = sortingMode;
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
    if (_original.progress.inRefreshing || progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;
    progress.error = null;

    backingStorage.clear(true);

    if (_original.backingStorage.count == 0) {
      backingStorage.addAll([]);
      progress.inRefreshing = false;
      onCompletelyEmpty();
      return 0;
    }

    prefilter();

    dynamic data;

    final buffer = <V>[];

    try {
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
    } catch (e) {
      progress.error = e;
    } finally {
      progress.inRefreshing = false;
    }

    return count;
  }

  @override
  Future<int> next() {
    assert(() {
      throw "ChainedFilterResourceSource is currently whole pass only";
    }());

    return Future.value(count);
  }

  Widget inject(Widget child) => _FilteringDataHolder(
        instance: this,
        child: child,
      );

  @override
  void destroy() {
    progress.close();
    _filterEvents.close();
    backingStorage.destroy();
    _originalSubscr.cancel();
  }

  StreamSubscription<FilteringData> watchFilter(
    void Function(FilteringData) f,
  ) =>
      _filterEvents.stream.listen(f);

  Stream<FilteringData> get filterEvents => _filterEvents.stream;
}

@immutable
class FilteringData {
  const FilteringData(this.filteringMode, this.sortingMode);

  final FilteringMode filteringMode;
  final SortingMode sortingMode;

  @override
  bool operator ==(Object other) {
    if (other is! FilteringData) {
      return false;
    }

    return filteringMode == other.filteringMode &&
        sortingMode == other.sortingMode;
  }

  @override
  int get hashCode => Object.hash(filteringMode, sortingMode);
}

class _FilteringDataNotifier extends InheritedWidget {
  const _FilteringDataNotifier({
    // super.key,
    required this.data,
    required super.child,
  });

  final FilteringData data;

  @override
  bool updateShouldNotify(_FilteringDataNotifier oldWidget) =>
      data != oldWidget.data || data != oldWidget.data;
}

class _FilteringDataHolder extends StatefulWidget {
  const _FilteringDataHolder({
    // super.key,
    required this.instance,
    required this.child,
  });

  final ChainedFilterResourceSource<dynamic, dynamic> instance;

  final Widget child;

  @override
  State<_FilteringDataHolder> createState() => __FilteringDataHolderState();
}

class __FilteringDataHolderState extends State<_FilteringDataHolder> {
  late final StreamSubscription<FilteringData> events;

  late FilteringData data;

  @override
  void initState() {
    super.initState();

    data = FilteringData(
      widget.instance.filteringMode,
      widget.instance.sortingMode,
    );

    events = widget.instance._filterEvents.stream.listen((e) {
      setState(() {
        data = e;
      });
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FilteringDataNotifier(
      data: data,
      child: widget.child,
    );
  }
}
