// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl_table/io.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:isar/isar.dart";

part "grid_state.g.dart";

@collection
class IsarGridState implements $GridState {
  const IsarGridState({
    required this.tags,
    required this.safeMode,
    required this.offset,
    required this.name,
    required this.isarId,
  });

  const IsarGridState.noId({
    required this.tags,
    required this.safeMode,
    required this.offset,
    required this.name,
  }) : isarId = null;

  final Id? isarId;

  @override
  @Index(unique: true, replace: true)
  final String name;

  @override
  final double offset;

  @override
  @enumerated
  final SafeMode safeMode;

  @override
  final String tags;

  @override
  GridState copy({
    String? tags,
    double? offset,
    SafeMode? safeMode,
    String? name,
  }) =>
      IsarGridState(
        tags: tags ?? this.tags,
        safeMode: safeMode ?? this.safeMode,
        offset: offset ?? this.offset,
        name: name ?? this.name,
        isarId: isarId,
      );
}
