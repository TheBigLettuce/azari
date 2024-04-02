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
  final T? overrideCell;

  final GridFunctionality<T> functionality;

  final Widget child;

  const WrapSelection({
    super.key,
    this.overrideCell,
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
      return _WrappedSelectionCore(
        thisIndx: thisIndx,
        overrideCell: overrideCell,
        selectFrom: selectFrom,
        selection: null,
        functionality: functionality,
        child: child,
      );
    }

    return thisIndx.isNegative || selection.ignoreSwipe
        ? _WrappedSelectionCore<T>(
            selection: selection,
            overrideCell: overrideCell,
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
              final c = selection.controller();
              if (!c.hasClients) {
                return;
              }

              if (c.position.isScrollingNotifier.value &&
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
                  overrideCell: overrideCell,
                  selectFrom: selectFrom,
                  selection: selection,
                  child: child,
                ),
              );
            },
          );
  }
}

class _WrappedSelectionCore<T extends Cell> extends StatefulWidget {
  final int thisIndx;
  final GridSelection<T>? selection;
  final List<int>? selectFrom;
  final GridFunctionality<T> functionality;

  final T? overrideCell;

  final Widget child;

  const _WrappedSelectionCore({
    required this.thisIndx,
    required this.selectFrom,
    required this.selection,
    required this.overrideCell,
    required this.functionality,
    required this.child,
  });

  @override
  State<_WrappedSelectionCore<T>> createState() =>
      __WrappedSelectionCoreState<T>();
}

class __WrappedSelectionCoreState<T extends Cell>
    extends State<_WrappedSelectionCore<T>>
    with SingleTickerProviderStateMixin {
  GridSelection<T> get selection => widget.selection!;
  GridFunctionality<T> get functionality => widget.functionality;
  int get thisIndx => widget.thisIndx;

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selection == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(15),
        onDoubleTap: widget.functionality.download != null
            ? () {
                controller.reset();
                controller.forward().then((value) => controller.reverse());
                HapticFeedback.selectionClick();
                widget.functionality.download!(thisIndx);
              }
            : null,
        onTap: thisIndx.isNegative && widget.overrideCell == null
            ? null
            : () {
                functionality.onPressed.launch<T>(
                  context,
                  thisIndx,
                  functionality,
                  useCellInsteadIdx: widget.overrideCell,
                );
              },
        child: widget.child,
      );
    }

    final child = Stack(
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
                  onDoubleTap: widget.functionality.download != null &&
                          widget.selection!.isEmpty
                      ? () {
                          controller.reset();
                          controller
                              .forward()
                              .then((value) => controller.reverse());
                          HapticFeedback.selectionClick();
                          widget.functionality.download!(thisIndx);
                        }
                      : null,
                  onTap: selection.isEmpty
                      ? thisIndx.isNegative && widget.overrideCell == null
                          ? null
                          : () {
                              functionality.onPressed.launch<T>(
                                context,
                                thisIndx,
                                functionality,
                                useCellInsteadIdx: widget.overrideCell,
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
                              selectFrom: widget.selectFrom);
                          HapticFeedback.vibrate();
                        },
                  child: widget.child,
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

    return Animate(
      autoPlay: false,
      controller: controller,
      effects: [
        MoveEffect(
          duration: 220.ms,
          curve: Easing.emphasizedAccelerate,
          begin: Offset.zero,
          end: const Offset(0, -10),
        ),
        TintEffect(
            duration: 220.ms,
            begin: 0,
            end: 0.1,
            curve: Easing.standardAccelerate,
            color: Theme.of(context).colorScheme.primary)
      ],
      child: child,
    );
  }
}
