// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "tags.g.dart";

@collection
class IsarTag extends TagDataImpl implements $TagData {
  const IsarTag({
    required this.time,
    required this.tag,
    required this.type,
    required this.isarId,
    required this.count,
  });

  const IsarTag.noId({
    required this.time,
    required this.tag,
    required this.type,
    required this.count,
  }) : isarId = null;

  final Id? isarId;

  @override
  @Index()
  final DateTime? time;

  @override
  @Index(unique: true, replace: true, composite: [CompositeIndex("type")])
  final String tag;

  @override
  @enumerated
  final TagType type;

  @override
  final int count;

  @override
  IsarTag copy({String? tag, TagType? type, int? count}) => IsarTag(
    type: type ?? this.type,
    tag: tag ?? this.tag,
    time: DateTime.now(),
    count: count ?? this.count,
    isarId: isarId,
  );
}
