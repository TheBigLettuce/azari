// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../interfaces/cell.dart';
import 'callback_grid.dart';

class SelectionGlueState {
  List<Widget>? actions;
  final Future Function(bool backward)? _playAnimation;

  SelectionGlue<T> glue<T extends Cell>(
          BuildContext context, void Function(Function()) setState) =>
      SelectionGlue<T>(close: () {
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
      }, open: (addActions, selection) {
        if (actions != null || addActions.isEmpty) {
          return;
        }
        actions = addActions
            .map((e) => WrapSheetButton(
                e.icon,
                e.showOnlyWhenSingle && selection.selected.length != 1
                    ? null
                    : () {
                        e.onPress(selection.selected.values.toList());

                        if (e.closeOnPress) {
                          selection.selected.clear();
                          actions = null;

                          setState(() {});
                        }
                      },
                false,
                selection.selected.length.toString(),
                e.explanation,
                animate: e.animate,
                color: e.color,
                play: e.play,
                backgroundColor: e.backgroundColor))
            .toList();

        if (_playAnimation != null) {
          _playAnimation!(false).then((value) => setState(() {}));
        } else {
          setState(() {});
        }
      }, isOpen: () {
        return actions != null;
      });

  Widget? widget(BuildContext context) => actions?.isNotEmpty ?? false
      ? Stack(
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
                children: actions!,
              ),
            )
          ],
        )
      : null;

  SelectionGlueState({Future Function(bool backward)? playAnimation})
      : _playAnimation = playAnimation;
}
