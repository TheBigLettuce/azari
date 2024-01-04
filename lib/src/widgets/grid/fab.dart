// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

class _Fab extends StatefulWidget {
  final ScrollController controller;
  final void Function(double, {double? infoPos, int? selectedCell})? scrollPos;
  final SelectionGlue selectionGlue;
  final EdgeInsets systemNavigationInsets;
  final bool addFabPadding;
  final PreferredSizeWidget? footer;

  const _Fab(
      {super.key,
      required this.controller,
      required this.selectionGlue,
      required this.systemNavigationInsets,
      required this.addFabPadding,
      required this.scrollPos,
      required this.footer});

  @override
  State<_Fab> createState() => __FabState();
}

class __FabState extends State<_Fab> {
  bool showFab = false;

  @override
  Widget build(BuildContext context) {
    return !showFab
        ? const SizedBox.shrink()
        : GestureDetector(
            onLongPress: () {
              final scroll = widget.controller.position.maxScrollExtent;
              if (scroll.isInfinite || scroll == 0) {
                return;
              }

              widget.controller.animateTo(scroll,
                  duration: 200.ms, curve: Easing.emphasizedAccelerate);
              widget.scrollPos?.call(scroll);
            },
            child: Padding(
              padding: EdgeInsets.only(
                  right: 4,
                  bottom: widget.systemNavigationInsets.bottom +
                      (!widget.addFabPadding
                          ? 0
                          : (widget.selectionGlue.isOpen() &&
                                      !widget.selectionGlue.keyboardVisible()
                                  ? 84
                                  : 0) +
                              (widget.footer != null
                                  ? widget.footer!.preferredSize.height
                                  : 0))),
              child: FloatingActionButton(
                onPressed: () {
                  widget.controller.animateTo(0,
                      duration: 200.ms, curve: Easing.emphasizedAccelerate);
                  StatisticsGeneral.addScrolledUp();
                },
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          ).animate().fadeIn(curve: Easing.standard);
  }
}
