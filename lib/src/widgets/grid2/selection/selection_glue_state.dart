// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';
import 'selection_glue.dart';
import 'selection_interface.dart';

class SelectionGlueState {
  List<Widget>? actions;
  final Future Function(bool backward)? _playAnimation;

  SelectionGlue<T> glue<T extends Cell>(bool Function() keyboardVisible,
          void Function(Function()) setState) =>
      SelectionGlue<T>(
          close: () {
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
          },
          open: (context, selection) {
            final addActions = GridMetadataProvider.gridActionsOf<T>(context);

            if (actions != null || addActions.isEmpty) {
              return;
            }
            actions = addActions
                .map((e) => WrapGridActionButton(
                      e.icon,
                      e.showOnlyWhenSingle && selection.count() != 1
                          ? null
                          : () {
                              // e.onPress(selection.selected.values.toList());

                              selection.use((l) {
                                e.onPress(l);
                              });

                              if (e.closeOnPress) {
                                selection.reset();
                                actions = null;

                                setState(() {});
                              }
                            },
                      false,
                      selection.count().toString(),
                    ))
                .toList();

            if (_playAnimation != null) {
              _playAnimation!(false).then((value) => setState(() {}));
            } else {
              setState(() {});
            }
          },
          isOpen: () {
            return actions != null;
          },
          keyboardVisible: keyboardVisible);

  SelectionGlueState({Future Function(bool backward)? playAnimation})
      : _playAnimation = playAnimation;
}

class GlueBottomAppBar extends StatelessWidget {
  final List<Widget> actions;

  const GlueBottomAppBar(this.actions, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        const SizedBox(
            height: 80,
            child: AbsorbPointer(
              child: SizedBox.shrink(),
            )),
        BottomAppBar(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          child: Wrap(
            spacing: 4,
            children: actions,
          ),
        )
      ],
    );
  }
}
