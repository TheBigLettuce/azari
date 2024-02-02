// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../../interfaces/cell/cell.dart';
import '../../../interfaces/grid/selection_glue.dart';
import '../wrap_grid_action_button.dart';

// class _CountWidget extends StatelessWidget {
//   const _CountWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4, bottom: 4),
//       child: Text(
//         SelectionCountNotifier.countOf(context).toString(),
//         style: Theme.of(context).textTheme.headlineSmall,
//       ),
//     );
//   }
// }

class SelectionGlueState {
  List<Widget>? actions;
  int? count;
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
    int barHeight,
    bool persistentBarHeight,
  ) =>
      SelectionGlue<T>(
        persistentBarHeight: persistentBarHeight,
        barHeight: barHeight,
        updateCount: (c) {
          count = c;

          setState(() {});
        },
        close: () => _close(setState),
        open: (addActions, selection) {
          if (actions != null || addActions.isEmpty) {
            return;
          }
          final a = [
            if (selection.noAppBar)
              WrapGridActionButton(Icons.close, selection.reset, true,
                  onLongPress: null,
                  showOnlyWhenSingle: false,
                  play: false,
                  animate: false),
            ...addActions.map((e) => WrapGridActionButton(
                  e.icon,
                  () {
                    e.onPress(selection.selected.values.toList());

                    if (e.closeOnPress) {
                      selection.selected.clear();
                      actions = null;

                      setState(() {});
                    }
                  },
                  false,
                  animate: e.animate,
                  color: e.color,
                  onLongPress: e.onLongPress == null
                      ? null
                      : () {
                          e.onLongPress!(selection.selected.values.toList());

                          if (e.closeOnPress) {
                            selection.selected.clear();
                            actions = null;

                            setState(() {});
                          }
                        },
                  play: e.play,
                  backgroundColor: e.backgroundColor,
                  showOnlyWhenSingle: e.showOnlyWhenSingle,
                ))
          ];

          if (_playAnimation != null) {
            _playAnimation!(false).then((value) => setState(() {
                  actions = a;
                }));
          } else {
            setState(() {
              actions = a;
            });
          }
        },
        isOpen: () {
          return actions != null;
        },
        keyboardVisible: keyboardVisible,
        hideNavBar: hide,
      );

  SelectionGlueState(
      {required this.hide, Future Function(bool backward)? playAnimation})
      : _playAnimation = playAnimation;
}
