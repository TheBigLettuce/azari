// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:flutter/widgets.dart";

class SelectionGlue {
  const SelectionGlue({
    required this.updateCount,
    required this.open,
    required this.barHeight,
    required this.isOpen,
    required this.keyboardVisible,
    required this.hideNavBar,
    required this.persistentBarHeight,
  });
  factory SelectionGlue.empty(BuildContext context) => SelectionGlue(
        updateCount: (_) {},
        open: _emptyOpen,
        hideNavBar: (_) {},
        isOpen: () => false,
        barHeight: () => 0,
        persistentBarHeight: false,
        keyboardVisible: () => MediaQuery.viewInsetsOf(context).bottom != 0,
      );

  final void Function<T extends CellBase>(
    BuildContext context,
    List<GridAction<T>> actions,
    GridSelection<T> selection,
  ) open;
  final void Function(int) updateCount;
  final bool Function() isOpen;
  final bool Function() keyboardVisible;
  final void Function(bool hide) hideNavBar;
  final int Function() barHeight;
  final bool persistentBarHeight;

  static void _emptyOpen<T extends CellBase>(
    BuildContext context,
    List<GridAction<T>> actions,
    GridSelection<T> selection,
  ) {}

  SelectionGlue chain({
    void Function(SelectionGlue parent, int count)? updateCount,
  }) {
    return SelectionGlue(
      updateCount: updateCount != null
          ? (i) {
              updateCount(this, i);
            }
          : this.updateCount,
      open: open,
      barHeight: barHeight,
      isOpen: isOpen,
      keyboardVisible: keyboardVisible,
      hideNavBar: hideNavBar,
      persistentBarHeight: persistentBarHeight,
    );
  }
}
