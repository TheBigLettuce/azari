// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart';

class GlueBottomAppBar extends StatelessWidget {
  final SelectionGlueState glue;

  const GlueBottomAppBar(this.glue, {super.key});

  @override
  Widget build(BuildContext context) {
    final actions = glue.actions?.$1 ?? [];

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (actions.length > 4)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) {
                    return actions
                        .getRange(0, actions.length - 3)
                        .map(
                          (e) => PopupMenuItem(
                            onTap: e.$2,
                            child: AbsorbPointer(child: e.$1),
                          ),
                        )
                        .toList();
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 4,
                    children: actions.length < 4
                        ? actions.map((e) => e.$1).toList()
                        : actions
                            .getRange(
                                actions.length != 4
                                    ? actions.length - 3
                                    : actions.length - 3 - 1,
                                actions.length)
                            .map((e) => e.$1)
                            .toList(),
                  ),
                ),
              ),
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 28,
                      minWidth: 28,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text(
                            glue.count.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.8),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 4)),
                  IconButton.filledTonal(
                    onPressed: () {
                      glue.actions?.$2();
                      HapticFeedback.mediumImpact();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
