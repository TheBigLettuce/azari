// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

part 'favorite_media.g.dart';

@collection
class FavoriteMedia {
  const FavoriteMedia(this.id, this.time);

  final Id id;
  @Index()
  final DateTime time;

  static int get thumbnail => Dbs.g.blacklisted.favoriteMedias
      .where()
      .sortByTimeDesc()
      .findFirstSync()!
      .id;

  static void addAll(List<int> ids) {
    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.favoriteMedias
        .putAllSync(ids.map((e) => FavoriteMedia(e, DateTime.now())).toList()));
  }

  static void deleteAll(List<int> ids) {
    Dbs.g.blacklisted.writeTxnSync(
        () => Dbs.g.blacklisted.favoriteMedias.deleteAllSync(ids));
  }

  static int get count => Dbs.g.blacklisted.favoriteMedias.countSync();
  static bool isEmpty() => count == 0;
  static bool isNotEmpty() => !isEmpty();
}
