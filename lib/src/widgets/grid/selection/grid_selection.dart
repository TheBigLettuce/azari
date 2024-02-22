// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class GridSelection<T extends Cell> {
  final selected = <int, T>{};
  final List<GridAction<T>> addActions;
  final bool noAppBar;
  final bool ignoreSwipe;

  int? lastSelected;

  void use(void Function(List<T> l) f) {
    f(selected.values.toList());
    reset();
  }

  final void Function(Function()) _setState;
  final SelectionGlue<T> glue;
  final ScrollController Function() controller;

  void reset() {
    selected.clear();
    glue.close();
    lastSelected = null;

    _setState(() {});
    glue.updateCount(selected.length);
  }

  bool isSelected(int indx) =>
      indx.isNegative ? false : selected.containsKey(indx);

  void add(BuildContext context, int id, T selection,
      double systemNavigationInsets) {
    if (id.isNegative) {
      return;
    }

    if (selected.isEmpty) {
      glue.open(addActions, this);
    }

    _setState(() {
      selected[id] = selection;
      lastSelected = id;
    });

    glue.updateCount(selected.length);
  }

  void remove(int id) {
    _setState(() {
      selected.remove(id);
      if (selected.isEmpty) {
        glue.close();
        lastSelected = null;
      }
    });

    glue.updateCount(selected.length);
  }

  void selectUnselectUntil(int indx, GridMutationInterface<T> state,
      {List<int>? selectFrom}) {
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
            selected[selectFrom?[i] ?? i] = state.getCell(selectFrom?[i] ?? i);
          } else {
            remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
        _setState(() {});
      } else if (indx > last) {
        for (var i = last; i <= indx; i++) {
          if (selection) {
            selected[selectFrom?[i] ?? i] = state.getCell(selectFrom?[i] ?? i);
          } else {
            remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
        _setState(() {});
      }

      glue.updateCount(selected.length);
    }
  }

  void selectOrUnselect(BuildContext context, int index, T selection,
      double systemNavigationInsets) {
    if (addActions.isEmpty) {
      return;
    }

    if (!isSelected(index)) {
      add(context, index, selection, systemNavigationInsets);
    } else {
      remove(index);
    }

    HapticFeedback.selectionClick();
  }

  GridSelection._(this._setState, this.addActions, this.glue, this.controller,
      {required this.noAppBar, required this.ignoreSwipe});
  GridSelection(this._setState, this.addActions, this.glue, this.controller,
      {required this.noAppBar, required this.ignoreSwipe});
}
