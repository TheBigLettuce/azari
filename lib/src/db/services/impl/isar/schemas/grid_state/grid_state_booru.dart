// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:isar/isar.dart";

part "grid_state_booru.g.dart";

@collection
class IsarGridStateBooru extends GridStateBase with GridStateBooru {
  IsarGridStateBooru(
    this.booru, {
    required super.tags,
    required super.safeMode,
    required super.scrollOffset,
    required super.name,
    required super.time,
  });

  Id? isarId;

  @override
  @enumerated
  final Booru booru;

  @override
  GridStateBooru copy({
    String? name,
    Booru? booru,
    String? tags,
    double? scrollOffset,
    SafeMode? safeMode,
    DateTime? time,
  }) =>
      IsarGridStateBooru(
        booru ?? this.booru,
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        scrollOffset: scrollOffset ?? this.scrollOffset,
        time: time ?? this.time,
        name: name ?? this.name,
      );
}
