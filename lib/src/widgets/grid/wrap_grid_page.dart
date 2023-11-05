// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../interfaces/cell.dart';
import 'callback_grid.dart';
import 'selection_glue_state.dart';

class WrappedGridPage<T extends Cell> extends StatefulWidget {
  final Widget Function(SelectionGlue<T> glue) f;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const WrappedGridPage(
      {super.key, required this.scaffoldKey, required this.f});

  @override
  State<WrappedGridPage<T>> createState() => _WrappedGridPageState();
}

class _WrappedGridPageState<T extends Cell> extends State<WrappedGridPage<T>>
    with SingleTickerProviderStateMixin {
  final glueState = SelectionGlueState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      extendBody: true,
      bottomNavigationBar: glueState.actions == null
          ? null
          : Animate(
              effects: const [
                  MoveEffect(
                      curve: Curves.easeOutQuint,
                      end: Offset.zero,
                      begin: Offset(0, kBottomNavigationBarHeight)),
                ],
              child: glueState.actions?.isNotEmpty ?? false
                  ? GlueBottomAppBar(glueState.actions!)
                  : const SizedBox.shrink()),
      body: widget.f(glueState.glue<T>(
          () => MediaQuery.viewInsetsOf(context).bottom != 0, setState)),
    );
  }
}
