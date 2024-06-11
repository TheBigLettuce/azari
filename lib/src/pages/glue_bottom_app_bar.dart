// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";

class GlueBottomAppBar extends StatelessWidget {
  const GlueBottomAppBar(this.glue, {super.key, required this.controller});

  final AnimationController controller;
  final SelectionGlueState glue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = glue.actions?.$1 ?? [];

    return Animate(
      autoPlay: false,
      controller: controller,
      value: 0,
      effects: [
        MoveEffect(
          duration: 220.ms,
          curve: Easing.emphasizedDecelerate,
          end: Offset.zero,
          begin: Offset(0, 100 + MediaQuery.viewPaddingOf(context).bottom),
        ),
      ],
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const SizedBox(
            height: 80,
            child: AbsorbPointer(
              child: SizedBox.shrink(),
            ),
          ),
          BottomAppBar(
            color: theme.colorScheme.surface.withOpacity(0.95),
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
                            (e) => PopupMenuItem<void>(
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
                                actions.length,
                              )
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.primary.withOpacity(0.8),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8),
                            child: Text(
                              glue.count.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary
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
          ),
        ],
      ),
    );
  }
}
