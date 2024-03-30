// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class WrapSelection<T extends Cell> extends StatelessWidget {
  final GridSelection<T> selection;
  final List<int>? selectFrom;
  final int thisIndx;

  final GridFunctionality<T> functionality;

  final Widget child;

  const WrapSelection({
    super.key,
    required this.thisIndx,
    required this.selectFrom,
    required this.selection,
    required this.functionality,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    SelectionCountNotifier.countOf(context);

    if (selection.addActions.isEmpty) {
      return child;
    }

    return thisIndx.isNegative || selection.ignoreSwipe
        ? _WrappedSelectionCore<T>(
            selection: selection,
            functionality: functionality,
            selectFrom: selectFrom,
            thisIndx: thisIndx,
            child: child,
          )
        : DragTarget(
            onAcceptWithDetails: (data) {
              selection.selectOrUnselect(context, thisIndx);
            },
            onLeave: (data) {
              if (selection.controller().position.isScrollingNotifier.value &&
                  selection.isSelected(thisIndx)) {
                return;
              }

              selection.selectOrUnselect(context, thisIndx);
            },
            onWillAcceptWithDetails: (data) => true,
            builder: (context, _, __) {
              return Draggable(
                data: 1,
                affinity: Axis.horizontal,
                feedback: const SizedBox(),
                child: _WrappedSelectionCore(
                  functionality: functionality,
                  thisIndx: thisIndx,
                  selectFrom: selectFrom,
                  selection: selection,
                  child: child,
                ),
              );
            },
          );
  }
}

class _WrappedSelectionCore<T extends Cell> extends StatelessWidget {
  final int thisIndx;
  final GridSelection<T> selection;
  final List<int>? selectFrom;
  final GridFunctionality<T> functionality;

  final Widget child;

  const _WrappedSelectionCore({
    required this.thisIndx,
    required this.selectFrom,
    required this.selection,
    required this.functionality,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
              padding: const EdgeInsets.all(0.5),
              child: AnimatedContainer(
                decoration: BoxDecoration(
                  color: selection.isSelected(thisIndx)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0),
                  borderRadius: BorderRadius.circular(15),
                ),
                duration: const Duration(milliseconds: 160),
                curve: Easing.emphasizedAccelerate,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: thisIndx.isNegative || selection.isEmpty
                      ? () {
                          functionality.onPressed.launch<T>(
                            context,
                            thisIndx,
                            functionality,
                            useCellInsteadIdx: null,
                          );
                        }
                      : () {
                          selection.selectOrUnselect(context, thisIndx);
                        },
                  onLongPress: selection.isEmpty
                      ? thisIndx.isNegative || selection.addActions.isEmpty
                          ? null
                          : () {
                              selection.selectOrUnselect(context, thisIndx);
                            }
                      : () {
                          selection.selectUnselectUntil(context, thisIndx,
                              selectFrom: selectFrom);
                          HapticFeedback.vibrate();
                        },
                  child: child,
                ),
              )),
        ),
        if (selection.isSelected(thisIndx))
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: Theme.of(context).iconTheme.size,
                height: Theme.of(context).iconTheme.size,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_outlined,
                    color: Theme.of(context).brightness != Brightness.light
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer,
                    shadows: const [Shadow(blurRadius: 0, color: Colors.black)],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 160),
                curve: Easing.emphasizedAccelerate,
              ),
      ],
    );
  }
}


//     final isSelected = widget.selection?.isSelected(widget.indx) ?? false;

//  InkWell(
//           borderRadius: BorderRadius.circular(15.0),
//           onTap: widget.onPressed == null
//               ? null
//               : () {
//                   widget.onPressed!(context);
//                 },
//           focusColor: Theme.of(context).colorScheme.primary,
//           onLongPress: widget.onLongPress,
//           onDoubleTap: widget.download != null
//               ? () {
//                   controller.reset();
//                   controller.forward().then((value) => controller.reverse());
//                   HapticFeedback.selectionClick();
//                   widget.download!(widget.indx);
//                 }
//               : null,
//           child:,
//         );

    // onPressed: (context) => ,
      // onLongPress: idx.isNegative || selection.addActions.isEmpty
      //     ? null
        