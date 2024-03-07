// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../../interfaces/cell/cell.dart';
import 'selection_glue.dart';
import '../wrappers/wrap_grid_action_button.dart';

class SelectionGlueState {
  SelectionGlueState({
    required this.hide,
    Future Function(bool backward)? playAnimation,
  }) : _playAnimation = playAnimation;

  (List<Widget> actions, void Function() reset)? actions;
  int count = 0;
  final void Function(bool) hide;
  final Future Function(bool backward)? _playAnimation;

  void _close(void Function(void Function()) setState) {
    if (actions == null) {
      return;
    }

    if (_playAnimation != null) {
      _playAnimation!(true).then((value) {
        actions = null;
        setState(() {});
      });
    } else {}
    try {
      actions = null;

      setState(() {});
    } catch (_) {}
  }

  SelectionGlue<T> glue<T extends Cell>(
    bool Function() keyboardVisible,
    void Function(Function()) setState,
    int Function() barHeight,
    bool persistentBarHeight,
  ) =>
      SelectionGlue<T>(
        persistentBarHeight: persistentBarHeight,
        barHeight: barHeight,
        updateCount: (c) {
          if (c != count) {
            count = c;

            setState(() {});
          }
        },
        close: () => _close(setState),
        open: (addActions, selection) {
          if (actions != null || addActions.isEmpty) {
            return;
          }
          final a = addActions
              .map((e) => WrapGridActionButton(
                    e.icon,
                    () {
                      selection.use(e.onPress, e.closeOnPress);
                    },
                    false,
                    animate: e.animate,
                    color: e.color,
                    onLongPress: e.onLongPress == null
                        ? null
                        : () {
                            selection.use(e.onLongPress!, e.closeOnPress);
                          },
                    play: e.play,
                    // backgroundColor: e.backgroundColor,
                    showOnlyWhenSingle: e.showOnlyWhenSingle,
                  ))
              .toList();

          if (_playAnimation != null) {
            _playAnimation!(false).then((value) => setState(() {
                  actions = (
                    a,
                    () {
                      selection.reset();
                    }
                  );
                }));
          } else {
            setState(() {
              actions = (
                a,
                () {
                  selection.reset();
                }
              );
            });
          }
        },
        isOpen: () {
          return actions != null;
        },
        keyboardVisible: keyboardVisible,
        hideNavBar: hide,
      );
}
