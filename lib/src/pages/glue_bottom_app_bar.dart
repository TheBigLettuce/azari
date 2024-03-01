// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart';

class GlueBottomAppBar extends StatelessWidget {
  final SelectionGlueState glue;

  const GlueBottomAppBar(this.glue, {super.key});

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 4,
                children: glue.actions!.$1,
              ),
              Row(
                // textBaseline: TextBaseline.alphabetic,
                // crossAxisAlignment: CrossAxisAlignment.baseline,
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
                  const Text(
                    "・",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 4)),
                  IconButton.filledTonal(
                    onPressed: () {
                      glue.actions?.$2();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              // FloatingActionButton(
              //   elevation: 0,
              //   onPressed: () {},
              //   heroTag: null,
              //   child: ,
              // )
            ],
          ),
        )
      ],
    );
  }
}
