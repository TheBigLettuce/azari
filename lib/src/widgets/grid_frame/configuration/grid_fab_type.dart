// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';

part '../parts/fab.dart';

sealed class GridFabType {
  const GridFabType();

  Widget widget(BuildContext context, ScrollController controller);
}

class DefaultGridFab implements GridFabType {
  const DefaultGridFab();

  @override
  Widget widget(BuildContext context, ScrollController controller) {
    return _Fab(
      controller: controller,
    );
  }
}

class OverrideGridFab implements GridFabType {
  const OverrideGridFab(this.child);

  final Widget Function(ScrollController) child;

  @override
  Widget widget(BuildContext context, ScrollController controller) {
    return child(controller);
  }
}
