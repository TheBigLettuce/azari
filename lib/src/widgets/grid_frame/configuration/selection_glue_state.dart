// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";

class SelectionGlueState {
  SelectionGlueState({
    required this.hide,
    Future<void> Function(bool backward)? playAnimation,
  }) : _playAnimation = playAnimation;

  (List<(Widget, void Function())> actions, void Function() reset)? actions;
  int count = 0;
  int countUpdateTimes = 0;

  final void Function(bool) hide;
  final Future<void> Function(bool backward)? _playAnimation;

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
    void Function(void Function()) setState,
    int Function() barHeight,
    bool persistentBarHeight,
  ) {
    void open<T extends CellBase>(
      BuildContext context,
      List<GridAction<T>> addActions,
      GridSelection<T> selection,
    ) {
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
            animate: e.animate,
            color: e.color,
            onLongPress: e.onLongPress == null
                ? null
                : () {
                    selection.use(e.onLongPress!, e.closeOnPress);
                  },
            play: e.play,
            animation: const [],
            whenSingleContext: e.showOnlyWhenSingle ? context : null,
          ),
          c
        );
      }).toList();

      if (_playAnimation != null) {
        _playAnimation(false).then(
          (value) => setState(() {
            actions = (
              a,
              selection.reset,
            );
          }),
        );
      } else {
        setState(() {
          actions = (
            a,
            selection.reset,
          );
        });
      }
    }

    return SelectionGlue(
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
      open: open,
      isOpen: () {
        return actions != null;
      },
      keyboardVisible: keyboardVisible,
      hideNavBar: hide,
    );
  }
}
