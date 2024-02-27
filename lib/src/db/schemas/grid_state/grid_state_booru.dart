// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:isar/isar.dart';

import '../../../interfaces/booru/safe_mode.dart';
import 'grid_state.dart';

part 'grid_state_booru.g.dart';

@collection
class GridStateBooru extends GridStateBase {
  @enumerated
  final Booru booru;

  GridStateBooru(
    this.booru, {
    required super.tags,
    required super.safeMode,
    required super.scrollOffset,
    required super.name,
    required super.time,
  });

  GridStateBooru.empty(this.booru, String name, String tags, SafeMode safeMode)
      : super(
          tags: tags,
          name: name,
          safeMode: safeMode,
          scrollOffset: 0,
          time: DateTime.now(),
        );

  GridStateBooru copy({
    String? name,
    Booru? booru,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  }) =>
      GridStateBooru(
        booru ?? this.booru,
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        scrollOffset: scrollOffset ?? this.scrollOffset,
        time: time ?? this.time,
        name: name ?? this.name,
      );
}
