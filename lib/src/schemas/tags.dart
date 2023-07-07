// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

part 'tags.g.dart';

@collection
class Tag {
  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("isExcluded")])
  final String tag;
  final bool isExcluded;
  final DateTime time;

  Tag trim() {
    return Tag(tag: tag.trim(), isExcluded: isExcluded);
  }

  Tag({required this.tag, required this.isExcluded}) : time = DateTime.now();
  Tag.string({required this.tag})
      : isExcluded = false,
        time = DateTime.now();
  Tag copyWith({String? tag, bool? isExcluded}) {
    return Tag(isExcluded: isExcluded ?? this.isExcluded, tag: tag ?? this.tag);
  }
}

int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
