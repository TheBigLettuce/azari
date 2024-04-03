// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import 'selection_glue.dart';
import '../wrappers/wrap_grid_action_button.dart';

class SelectionGlueState {
  SelectionGlueState({
    required this.hide,
    Future Function(bool backward)? playAnimation,
  }) : _playAnimation = playAnimation;

  (List<(Widget, void Function())> actions, void Function() reset)? actions;
  int count = 0;
  int countUpdateTimes = 0;

  final void Function(bool) hide;
  final Future Function(bool backward)? _playAnimation;

  void _close(void Function(void Function()) setState) {
    if (actions == null) {
      return;
    }

    if (_playAnimation != null) {
      _playAnimation(true).then((value) {
        actions = null;
        count = 0;
        setState(() {});
      });
    } else {}
    try {
      actions = null;
      count = 0;

      setState(() {});
    } catch (_) {}
  }

  SelectionGlue glue(
    bool Function() keyboardVisible,
    void Function(Function()) setState,
    int Function() barHeight,
    bool persistentBarHeight,
  ) =>
      SelectionGlue(
        persistentBarHeight: persistentBarHeight,
        barHeight: barHeight,
        updateCount: (c) {
          count = c;
          countUpdateTimes += 1;

          if (c == 0) {
            _close(setState);
          } else {
            setState(() {});
          }
        },
        open: (context, addActions, selection) {
          if (actions != null || addActions.isEmpty) {
            return;
          }
          final a = addActions.map((e) {
            void c() {
              selection.use(e.onPress, e.closeOnPress);
            }

            return (
              WrapGridActionButton(
                e.icon,
                c,
                false,
                animate: e.animate,
                color: e.color,
                onLongPress: e.onLongPress == null
                    ? null
                    : () {
                        selection.use(e.onLongPress!, e.closeOnPress);
                      },
                play: e.play,
                showOnlyWhenSingle: e.showOnlyWhenSingle,
              ),
              c
            );
          }).toList();

          if (_playAnimation != null) {
            _playAnimation(false).then((value) => setState(() {
                  actions = (
                    a,
                    selection.reset,
                  );
                }));
          } else {
            setState(() {
              actions = (
                a,
                selection.reset,
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
