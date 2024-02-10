// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class _WrapSelection extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool selectionEnabled;
  final int thisIndx;
  final double bottomPadding;
  final ScrollController scrollController;
  final void Function() selectUnselect;
  final void Function(int indx) selectUntil;

  final bool ignoreSwipeGesture;

  const _WrapSelection({
    required this.child,
    required this.isSelected,
    required this.ignoreSwipeGesture,
    required this.selectUnselect,
    required this.thisIndx,
    required this.bottomPadding,
    required this.scrollController,
    required this.selectionEnabled,
    required this.selectUntil,
  });

  @override
  Widget build(BuildContext context) {
    return thisIndx.isNegative || ignoreSwipeGesture
        ? _WrappedSelectionCore(
            isSelected: isSelected,
            selectUnselect: selectUnselect,
            thisIndx: thisIndx,
            selectionEnabled: selectionEnabled,
            selectUntil: selectUntil,
            child: child,
          )
        : DragTarget(
            onAcceptWithDetails: (data) {
              selectUnselect();
            },
            onLeave: (data) {
              if (scrollController.position.isScrollingNotifier.value &&
                  isSelected) {
                return;
              }
              selectUnselect();
            },
            onMove: (details) {
              if (scrollController.position.isScrollingNotifier.value) {
                return;
              }

              final height = MediaQuery.of(context).size.height;
              if (details.offset.dy < 120 && scrollController.offset > 100) {
                scrollController.animateTo(scrollController.offset - 100,
                    duration: 200.ms, curve: Easing.emphasizedAccelerate);
              } else if (details.offset.dy + bottomPadding >
                      (height * 0.9) - (bottomPadding) &&
                  scrollController.offset <
                      scrollController.position.maxScrollExtent * 0.99) {
                scrollController.animateTo(scrollController.offset + 100,
                    duration: 200.ms, curve: Easing.emphasizedAccelerate);
              }
            },
            onWillAcceptWithDetails: (data) => true,
            builder: (context, _, __) {
              return Draggable(
                data: 1,
                affinity: Axis.horizontal,
                feedback: const SizedBox(),
                child: _WrappedSelectionCore(
                  isSelected: isSelected,
                  selectUnselect: selectUnselect,
                  thisIndx: thisIndx,
                  selectionEnabled: selectionEnabled,
                  selectUntil: selectUntil,
                  child: child,
                ),
              );
            },
          );
  }
}

class _WrappedSelectionCore extends StatelessWidget {
  final int thisIndx;
  final bool isSelected;
  final void Function() selectUnselect;
  final void Function(int indx) selectUntil;
  final bool selectionEnabled;
  final Widget child;

  const _WrappedSelectionCore({
    required this.isSelected,
    required this.selectUnselect,
    required this.thisIndx,
    required this.selectionEnabled,
    required this.selectUntil,
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
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0),
                  borderRadius: BorderRadius.circular(15),
                ),
                duration: const Duration(milliseconds: 160),
                curve: Easing.emphasizedAccelerate,
                child: GestureDetector(
                  onTap: thisIndx.isNegative
                      ? null
                      : () {
                          selectUnselect();
                        },
                  onLongPress: thisIndx.isNegative
                      ? null
                      : () {
                          selectUntil(thisIndx);
                          HapticFeedback.vibrate();
                        },
                  child: AbsorbPointer(
                    absorbing: selectionEnabled,
                    child: child,
                  ),
                ),
              )),
        ),
        if (isSelected) ...[
          GestureDetector(
            onTap: thisIndx.isNegative
                ? null
                : () {
                    selectUnselect();
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
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 160),
                curve: Easing.emphasizedAccelerate,
              )
        ],
      ],
    );
  }
}
