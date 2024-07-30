// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math" as math;

import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:flutter/material.dart";

class SkeletonState {
  SkeletonState();
  final gridSeed = math.Random().nextInt(948512342);

  void dispose() {}
}

class GridSkeletonState<T extends CellBase> extends SkeletonState {
  GridSkeletonState();

  final GlobalKey<GridFrameState<T>> gridKey = GlobalKey();
  SettingsData settings = SettingsService.db().current;
}
