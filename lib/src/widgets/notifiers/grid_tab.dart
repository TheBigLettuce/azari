// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../db/isar.dart';

class GridTabNotifier extends InheritedWidget {
  final GridTab tab;

  @override
  bool updateShouldNotify(GridTabNotifier oldWidget) {
    return tab != oldWidget.tab;
  }

  static GridTab of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridTabNotifier>();

    return widget!.tab;
  }

  const GridTabNotifier({super.key, required this.tab, required super.child});
}
