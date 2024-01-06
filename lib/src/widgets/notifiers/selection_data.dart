// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';

import '../grid2/selection/selection_interface.dart';
import 'is_selecting.dart';
import 'selection_count.dart';

class GridSelectionHolder<T extends Cell> extends StatefulWidget {
  final Widget child;

  const GridSelectionHolder({
    super.key,
    required this.child,
  });

  @override
  State<GridSelectionHolder<T>> createState() => GridSelectionHolderState<T>();
}

class GridSelectionHolderState<T extends Cell>
    extends State<GridSelectionHolder<T>> {
  int _count = 0;
  late final _selection = SelectionInterface<T>(_tick);

  void _tick(int newCount) {
    setState(() {
      _count = newCount;
    });
  }

  void use(void Function(List<T> l) f) => _selection.use(f);

  @override
  Widget build(BuildContext context) {
    return SelectionData(
      bundle: SelectionCallbackBundle(
          isSelected: _selection.isSelected,
          selectUnselect: _selection.selectOrUnselect,
          selectUntil: _selection.selectUnselectUntil),
      child: SelectionCountNotifier(
        count: _count,
        child: IsSelectingNotifier(
          isSelecting: _count != 0,
          child: widget.child,
        ),
      ),
    );
  }
}

class SelectionData extends InheritedWidget {
  final SelectionCallbackBundle bundle;

  const SelectionData({super.key, required this.bundle, required super.child});

  static SelectionCallbackBundle of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<SelectionData>();

    return widget!.bundle;
  }

  @override
  bool updateShouldNotify(SelectionData oldWidget) =>
      oldWidget.bundle != bundle;
}

class SelectionCallbackBundle {
  final void Function(BuildContext context, int i) selectUnselect;
  final void Function(BuildContext context, int i) selectUntil;
  final bool Function(BuildContext context, int i) isSelected;

  const SelectionCallbackBundle({
    required this.isSelected,
    required this.selectUnselect,
    required this.selectUntil,
  });
}
