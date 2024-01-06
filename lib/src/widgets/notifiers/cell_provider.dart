// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';
import 'package:gallery/src/interfaces/background_data_loader/loader_state_controller.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';

class CellProvider<T extends Cell> extends InheritedWidget {
  final BackgroundDataLoader<T> loader;

  const CellProvider({super.key, required this.loader, required super.child});

  static LoaderStateController stateOf<T extends Cell>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

    return widget!.loader.state;
  }

  // static void refreshOf<T extends Cell>(BuildContext context) {
  //     final widget =
  //       context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

  //       widget.loader.
  // }

  static T getOf<T extends Cell>(BuildContext context, int token) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

    return widget!.loader.getSingle(token)!;
  }

  static T? Function(int) of<T extends Cell>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

    return widget!.loader.getSingle;
  }

  @override
  bool updateShouldNotify(CellProvider oldWidget) => oldWidget.loader != loader;
}
