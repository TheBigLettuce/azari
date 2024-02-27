// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../../../interfaces/booru/safe_mode.dart';

part 'grid_state.g.dart';

@collection
class GridState extends GridStateBase {
  GridState({
    required super.tags,
    required super.name,
    required super.safeMode,
    required super.time,
    required super.scrollOffset,
  });

  GridState.empty(String name, String tags, SafeMode safeMode)
      : super(
          tags: tags,
          name: name,
          safeMode: safeMode,
          scrollOffset: 0,
          time: DateTime.now(),
        );

  GridState copy({
    String? name,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  }) =>
      GridState(
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        time: time ?? this.time,
        name: name ?? this.name,
        scrollOffset: scrollOffset ?? this.scrollOffset,
      );
}

class GridStateBase {
  @override
  String toString() {
    return "GridStateBase: $name, $time, '$tags', $scrollOffset, $safeMode";
  }

  Id? id;

  @Index(unique: true, replace: true)
  final String name;
  @Index()
  final DateTime time;

  final String tags;

  final double scrollOffset;

  @enumerated
  final SafeMode safeMode;

  GridStateBase({
    required this.tags,
    required this.safeMode,
    required this.scrollOffset,
    required this.name,
    required this.time,
  });
}
