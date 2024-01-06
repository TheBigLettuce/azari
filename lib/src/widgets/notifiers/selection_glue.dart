// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid2/selection/selection_glue.dart';

class GlueHolder<T extends Cell> extends StatefulWidget {
  final SelectionGlue<T> glue;
  final Widget child;

  const GlueHolder({super.key, required this.glue, required this.child});

  @override
  State<GlueHolder<T>> createState() => _GlueHolderState();
}

class _GlueHolderState<T extends Cell> extends State<GlueHolder<T>> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionGlueNotifier<T>(
      glue: widget.glue,
      child: widget.child,
    );
  }
}

class SelectionGlueNotifier<T extends Cell> extends InheritedWidget {
  final SelectionGlue<T> glue;

  const SelectionGlueNotifier(
      {super.key, required this.glue, required super.child});

  static SelectionGlue<T> of<T extends Cell>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SelectionGlueNotifier<T>>();

    return widget!.glue;
  }

  static bool isOpenOf<T extends Cell>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SelectionGlueNotifier<T>>();

    return widget!.glue.isOpen();
  }

  @override
  bool updateShouldNotify(SelectionGlueNotifier<T> oldWidget) =>
      oldWidget.glue != glue;
}
