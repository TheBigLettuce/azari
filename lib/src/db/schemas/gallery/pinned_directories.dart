// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:isar/isar.dart';

part 'pinned_directories.g.dart';

@collection
class PinnedDirectories {
  Id get isarId => fastHash(categoryName);

  @Index(unique: true, replace: true)
  final String categoryName;
  @Index()
  final DateTime time;

  const PinnedDirectories(this.categoryName, this.time);
}
