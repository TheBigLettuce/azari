// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:isar/isar.dart";

part "grid_state.g.dart";

@collection
class IsarGridState extends GridStateBase with GridState {
  IsarGridState({
    required super.tags,
    required super.name,
    required super.safeMode,
    required super.time,
    required super.scrollOffset,
  });

  Id? isarId;

  // GridState.empty(String name, String tags, SafeMode safeMode)
  //     : super(
  //         tags: tags,
  //         name: name,
  //         safeMode: safeMode,
  //         scrollOffset: 0,
  //         time: DateTime.now(),
  //       );

  @override
  GridState copy({
    String? name,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  }) =>
      IsarGridState(
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        time: time ?? this.time,
        name: name ?? this.name,
        scrollOffset: scrollOffset ?? this.scrollOffset,
      );
}
