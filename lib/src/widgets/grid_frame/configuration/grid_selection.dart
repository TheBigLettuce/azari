// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class GridSelection<T extends CellBase> {
  GridSelection(
    this.addActions,
    this.glue,
    this.controller, {
    required this.noAppBar,
    required this.mutation,
  });

  final SelectionGlue glue;
  final ScrollController Function() controller;
  final GridMutationInterface mutation;

  final _selected = <int, T>{};
  final List<GridAction<T>> addActions;
  final bool noAppBar;

  int? lastSelected;

  bool get isEmpty => _selected.isEmpty;
  bool get isNotEmpty => _selected.isNotEmpty;

  int get count => _selected.length;

  void use(void Function(List<T> l) f, bool closeOnPress) {
    f(_selected.values.toList());
    if (closeOnPress) {
      reset();
    }
  }

  void reset([bool force = false]) {
    if (_selected.isNotEmpty) {
      _selected.clear();
      lastSelected = null;
      glue.updateCount(0);
    } else if (force) {
      glue.updateCount(0);
    }
  }

  void selectAll(BuildContext context) {
    final m = mutation.cellCount;

    if (m <= _selected.length) {
      return;
    }

    if (!glue.isOpen()) {
      glue.open<T>(context, addActions, this);
    }

    _selected.clear();
    final getCell = CellProvider.of<T>(context);

    for (var i = 0; i != m; i++) {
      _selected[i] = getCell(i);
    }

    glue.updateCount(_selected.length);
  }

  bool isSelected(int indx) =>
      indx.isNegative ? false : _selected.containsKey(indx);

  void _add(BuildContext context, int id, T selection) {
    if (id.isNegative) {
      return;
    }

    if (_selected.isEmpty || !glue.isOpen()) {
      glue.open<T>(context, addActions, this);
    }

    _selected[id] = selection;
    lastSelected = id;

    glue.updateCount(_selected.length);
  }

  void _remove(BuildContext context, int id) {
    _selected.remove(id);
    if (_selected.isEmpty) {
      _selected.clear();
      lastSelected = null;
    } else if (_selected.isNotEmpty && !glue.isOpen()) {
      glue.open<T>(context, addActions, this);
    }

    glue.updateCount(_selected.length);
  }

  void selectUnselectUntil(BuildContext context, int indx,
      {List<int>? selectFrom}) {
    if (lastSelected != null) {
      final last = selectFrom?.indexOf(lastSelected!) ?? lastSelected!;
      indx = selectFrom?.indexOf(indx) ?? indx;
      if (lastSelected == indx) {
        return;
      }

      final selection = !isSelected(indx);
      final getCell = CellProvider.of<T>(context);

      if (indx < last) {
        for (var i = last; i >= indx; i--) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = getCell(selectFrom?[i] ?? i);
          } else {
            _remove(context, selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
      } else if (indx > last) {
        for (var i = last; i <= indx; i++) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = getCell(selectFrom?[i] ?? i);
          } else {
            _remove(context, selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
      }

      glue.updateCount(_selected.length);
    }
  }

  void selectOrUnselect(BuildContext context, int index) {
    if (addActions.isEmpty) {
      return;
    }

    if (glue.isOpen() && _selected.isEmpty) {
      return;
    }

    if (!isSelected(index)) {
      final cell = CellProvider.getOf<T>(context, index);

      _add(context, index, cell);
    } else {
      _remove(context, index);
    }

    HapticFeedback.selectionClick();
  }
}
