// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';

import '../grid_frame.dart';

class SelectionGlue<T extends Cell> {
  final void Function(List<GridAction<T>> actions, GridSelection<T> selection)
      open;
  final void Function(int) updateCount;
  final void Function() close;
  final bool Function() isOpen;
  final bool Function() keyboardVisible;
  final void Function(bool hide) hideNavBar;
  final int Function() barHeight;
  final bool persistentBarHeight;

  static SelectionGlue<T> empty<T extends Cell>(BuildContext context) =>
      SelectionGlue(
        close: () {},
        updateCount: (_) {},
        open: (_, __) {},
        hideNavBar: (_) {},
        isOpen: () => false,
        barHeight: () => 0,
        persistentBarHeight: false,
        keyboardVisible: () => MediaQuery.viewInsetsOf(context).bottom != 0,
      );

  SelectionGlue<T> chain({
    void Function(SelectionGlue<T> parent)? close,
  }) {
    return SelectionGlue(
      close: close != null
          ? () {
              close(this);
            }
          : this.close,
      updateCount: updateCount,
      open: open,
      barHeight: barHeight,
      isOpen: isOpen,
      keyboardVisible: keyboardVisible,
      hideNavBar: hideNavBar,
      persistentBarHeight: persistentBarHeight,
    );
  }

  const SelectionGlue({
    required this.close,
    required this.updateCount,
    required this.open,
    required this.barHeight,
    required this.isOpen,
    required this.keyboardVisible,
    required this.hideNavBar,
    required this.persistentBarHeight,
  });
}
