// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/notifiers/is_selecting.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';
import 'package:gallery/src/widgets/notifiers/selection_data.dart';

class WrappedSelection extends StatelessWidget {
  final int thisIndx;
  final Widget child;

  const WrappedSelection({
    super.key,
    required this.thisIndx,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final selection = SelectionData.of(context);
    SelectionCountNotifier.countOf(context);

    return thisIndx.isNegative
        ? _WrappedSelectionCore(
            thisIndx: thisIndx,
            selectionEnabled: IsSelectingNotifier.of(context),
            child: child,
          )
        : DragTarget(
            onAcceptWithDetails: (data) {
              selection.selectUnselect(context, thisIndx);
            },
            onLeave: (data) {
              final scrollController = PrimaryScrollController.of(context);

              if (scrollController.position.isScrollingNotifier.value &&
                  selection.isSelected(context, thisIndx)) {
                return;
              }
              selection.selectUnselect(context, thisIndx);
            },
            onMove: (details) {
              final scrollController = PrimaryScrollController.of(context);

              if (scrollController.position.isScrollingNotifier.value) {
                return;
              }

              final height = MediaQuery.of(context).size.height;
              if (details.offset.dy < 120 && scrollController.offset > 100) {
                scrollController.animateTo(scrollController.offset - 100,
                    duration: 200.ms, curve: Curves.linear);
              } else if (details.offset.dy > (height * 0.9) &&
                  scrollController.offset <
                      scrollController.position.maxScrollExtent * 0.99) {
                scrollController.animateTo(scrollController.offset + 100,
                    duration: 200.ms, curve: Curves.linear);
              }
            },
            onWillAcceptWithDetails: (data) => true,
            builder: (context, _, __) {
              return Draggable(
                data: 1,
                affinity: Axis.horizontal,
                feedback: const SizedBox(),
                child: _WrappedSelectionCore(
                  thisIndx: thisIndx,
                  selectionEnabled: IsSelectingNotifier.of(context),
                  child: child,
                ),
              );
            },
          );
  }
}

class _WrappedSelectionCore extends StatelessWidget {
  final int thisIndx;
  final bool selectionEnabled;
  final Widget child;

  const _WrappedSelectionCore({
    required this.thisIndx,
    required this.selectionEnabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final selection = SelectionData.of(context);
    SelectionCountNotifier.countOf(context);

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
              padding: const EdgeInsets.all(0.5),
              child: Container(
                decoration: BoxDecoration(
                  color: selection.isSelected(context, thisIndx)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: GestureDetector(
                  onTap: thisIndx.isNegative
                      ? null
                      : () {
                          selection.selectUnselect(context, thisIndx);
                        },
                  onLongPress: thisIndx.isNegative
                      ? null
                      : () {
                          selection.selectUntil(context, thisIndx);
                          HapticFeedback.vibrate();
                        },
                  child: AbsorbPointer(
                    absorbing: selectionEnabled,
                    child: child,
                  ),
                ),
              )),
        ),
        if (selection.isSelected(context, thisIndx)) ...[
          GestureDetector(
            onTap: thisIndx.isNegative
                ? null
                : () {
                    selection.selectUnselect(context, thisIndx);
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: Theme.of(context).iconTheme.size,
                  height: Theme.of(context).iconTheme.size,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle),
                    child: Icon(
                      Icons.check_outlined,
                      color: Theme.of(context).brightness != Brightness.light
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                      shadows: const [
                        Shadow(blurRadius: 0, color: Colors.black)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ],
    );
  }
}
