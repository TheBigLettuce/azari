// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CallbackGridFab extends StatefulWidget {
  // final ScrollController controller;
  // final SelectionGlue selectionGlue;
  // final EdgeInsets systemNavigationInsets;
  // final bool addFabPadding;
  final double? footerHeight;

  const CallbackGridFab(
      {super.key,
      // required this.controller,
      // required this.selectionGlue,
      // required this.systemNavigationInsets,
      // required this.addFabPadding,
      this.footerHeight});

  @override
  State<CallbackGridFab> createState() => _CallbackGridFabState();
}

class _CallbackGridFabState extends State<CallbackGridFab> {
  bool showFab = true;

  @override
  Widget build(BuildContext context) {
    return !showFab
        ? const SizedBox.shrink()
        : GestureDetector(
            onLongPress: () {
              final c = PrimaryScrollController.maybeOf(context);
              final scroll = c?.position.maxScrollExtent;
              if (scroll == null || scroll.isInfinite || scroll == 0) {
                return;
              }

              c?.animateTo(scroll, duration: 200.ms, curve: Curves.linear);
            },
            child: Padding(
              padding: EdgeInsets.only(
                  right: 4,
                  bottom: MediaQuery.of(context).systemGestureInsets.bottom
                  // +
                  //     (!widget.addFabPadding
                  //         ? 0
                  //         : (widget.selectionGlue.isOpen() &&
                  //                     !widget.selectionGlue.keyboardVisible()
                  //                 ? 84
                  //                 : 0) +
                  //             (widget.footer != null
                  //                 ? widget.footer!.preferredSize.height
                  //                 : 0))
                  ),
              child: FloatingActionButton(
                onPressed: () {
                  PrimaryScrollController.maybeOf(context)
                      ?.animateTo(0, duration: 200.ms, curve: Curves.linear);
                },
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          ).animate().fadeIn(curve: Curves.easeInOutCirc);
  }
}
