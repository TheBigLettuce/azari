// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class GridSelection<T extends CellBase> {
  GridSelection(
    this.controller,
    this.actions, {
    required this.noAppBar,
    required this.source,
  }) {
    _countEvents = controller.countEvents.listen((_) {
      if (controller.count == 0 && count != 0) {
        _selected.clear();
      }
    });
  }
  late final StreamSubscription<void> _countEvents;

  final SelectionController controller;
  final ReadOnlyStorage<int, T> source;

  final _selected = <int, T>{};
  final List<GridAction<T>> actions;
  final bool noAppBar;

  int? lastSelected;

  bool get isEmpty => _selected.isEmpty;
  bool get isNotEmpty => _selected.isNotEmpty;

  int get count => _selected.length;

  void _use(
    void Function(List<T> l) f,
    bool closeOnPress,
  ) {
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
            animate: e.animate,
            play: e.play,
          ),
        )
        .toList();
  }

  void reset([bool force = false]) {
    if (_selected.isNotEmpty) {
      _selected.clear();
      lastSelected = null;
      controller.setCount(0, _factory);
    } else if (force) {
      controller.setCount(0, _factory);
    }
  }

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

  bool isSelected(int indx) => _selected.containsKey(indx) && !indx.isNegative;

  void _add(int id, T selection) {
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

  void selectUnselectUntil(
    int indx_, {
    List<int>? selectFrom,
  }) {
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

  void _dispose() {
    _countEvents.cancel();
    _selected.clear();
  }
}
