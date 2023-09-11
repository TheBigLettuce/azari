// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/schemas/post.dart';
import 'package:isar/isar.dart';

part 'favorite_booru.g.dart';

@collection
class FavoriteBooru extends PostBase {
  @Index()
  String? group;

  FavoriteBooru(
      {required super.height,
      required super.id,
      required super.md5,
      required super.tags,
      required super.width,
      required super.fileUrl,
      required super.prefix,
      required super.previewUrl,
      required super.sampleUrl,
      required super.ext,
      this.group,
      required super.sourceUrl,
      required super.rating,
      required super.score,
      required super.createdAt});
}
