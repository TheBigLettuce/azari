// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../shell_scope.dart";

extension ShellSelectionInjectSelfExt on ShellSelectionHolder {
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: countEvents,
      builder: (context, _) =>
          _SelectionNotifier(gridSelection: this, count: count, child: child),
    );
  }
}

abstract interface class ShellSelectionHolder {
  factory ShellSelectionHolder.source(
    SelectionController controller,
    List<SelectionBarAction> actions, {
    required ReadOnlyStorage<int, CellBuilder> source,
  }) = _SelectionHolder;

  Stream<void> get countEvents;

  bool get isEmpty;
  bool get isNotEmpty;
  List<SelectionBarAction> get actions;

  int get count;

  bool isSelected(int indx);

  void selectUnselectAll();
  void selectAll();
  void selectUnselectUntil(int indx_, {List<int>? selectFrom});

  void selectOrUnselect(int index);

  void reset([bool force = false]);
  void dispose();

  static ShellSelectionHolder of(BuildContext context) => maybeOf(context)!;

  static ShellSelectionHolder? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_SelectionNotifier>();

    return widget?.gridSelection;
  }
}

class _SelectionHolder implements ShellSelectionHolder {
  _SelectionHolder(this.controller, this.actions, {required this.source}) {
    _countEvents = controller.countEvents.listen((_) {
      if (controller.count == 0 && count != 0) {
        _selected.clear();
      }
    });
  }
  late final StreamSubscription<void> _countEvents;

  final SelectionController controller;
  final ReadOnlyStorage<int, CellBuilder> source;

  @override
  final List<SelectionBarAction> actions;

  final _selected = <int, CellBuilder>{};

  int? lastSelected;

  @override
  bool get isEmpty => _selected.isEmpty;
  @override
  bool get isNotEmpty => _selected.isNotEmpty;

  @override
  Stream<void> get countEvents => controller.countEvents;

  @override
  int get count => _selected.length;

  void _use(void Function(List<CellBuilder> l) f, bool closeOnPress) {
    f(_selected.values.toList());
    if (closeOnPress) {
      reset();
    }
  }

  List<SelectionButton> _factory() {
    return actions
        .map(
          (e) => SelectionButton(
            e.icon,
            () => _use(e.onPress, e.closeOnPress),
            e.closeOnPress,
            e.taskTag,
            animate: e.animate,
            play: e.play,
          ),
        )
        .toList();
  }

  @override
  void selectUnselectAll() {
    if (count == source.count) {
      reset();
    } else {
      selectAll();
    }
  }

  @override
  void reset([bool force = false]) {
    if (_selected.isNotEmpty) {
      _selected.clear();
      lastSelected = null;
      controller.setCount(0, _factory);
    } else if (force) {
      controller.setCount(0, _factory);
    }
  }

  @override
  void selectAll() {
    final m = source.count;

    if (m <= _selected.length) {
      return;
    }

    if (!controller.isExpanded) {
      controller.setExpanded(true);
    }

    _selected.clear();

    for (var i = 0; i != m; i++) {
      _selected[i] = source[i];
    }

    controller.setCount(_selected.length, _factory);
  }

  @override
  bool isSelected(int indx) => _selected.containsKey(indx) && !indx.isNegative;

  void _add(int id, CellBuilder selection) {
    if (id.isNegative) {
      return;
    }

    if (_selected.isEmpty || !controller.isExpanded) {
      controller.setExpanded(true);
    }

    _selected[id] = selection;
    lastSelected = id;

    controller.setCount(_selected.length, _factory);
  }

  void _remove(int id) {
    _selected.remove(id);
    if (_selected.isEmpty) {
      _selected.clear();
      lastSelected = null;
    } else if (_selected.isNotEmpty && !controller.isExpanded) {
      controller.setExpanded(true);
    }

    controller.setCount(_selected.length, _factory);
  }

  @override
  void selectUnselectUntil(int indx_, {List<int>? selectFrom}) {
    var indx = indx_;

    if (lastSelected != null) {
      final last = selectFrom?.indexOf(lastSelected!) ?? lastSelected!;
      indx = selectFrom?.indexOf(indx) ?? indx;
      if (lastSelected == indx) {
        return;
      }

      final selection = !isSelected(indx);

      if (indx < last) {
        for (var i = last; i >= indx; i--) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = source[selectFrom?[i] ?? i];
          } else {
            _remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
      } else if (indx > last) {
        for (var i = last; i <= indx; i++) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = source[selectFrom?[i] ?? i];
          } else {
            _remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
      }

      controller.setCount(_selected.length, _factory);
    }
  }

  @override
  void selectOrUnselect(int index) {
    if (controller.isExpanded && _selected.isEmpty) {
      return;
    }

    if (!isSelected(index)) {
      final cell = source[index];

      _add(index, cell);
    } else {
      _remove(index);
    }

    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _countEvents.cancel();
    _selected.clear();
  }
}

class _SelectionNotifier extends InheritedWidget {
  const _SelectionNotifier({
    // super.key,
    required this.count,
    required this.gridSelection,
    required super.child,
  });

  final int count;
  final ShellSelectionHolder gridSelection;

  @override
  bool updateShouldNotify(_SelectionNotifier oldWidget) {
    return gridSelection != oldWidget.gridSelection || count != oldWidget.count;
  }
}
