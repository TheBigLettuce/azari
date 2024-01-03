// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:isar/isar.dart';

import '../../initalize_db.dart';

part 'thumbnail.g.dart';

@collection
class Thumbnail {
  const Thumbnail(this.id, this.updatedAt, this.path, this.differenceHash);

  final Id id;
  @Index()
  final String path;
  @Index()
  final int differenceHash;
  final DateTime updatedAt;

  static void clear() {
    Dbs.g.thumbnail!
        .writeTxnSync(() => Dbs.g.thumbnail!.thumbnails.clearSync());
  }

  static void addAll(List<ThumbId> l) {
    if (Dbs.g.thumbnail!.thumbnails.countSync() >= 3000) {
      final List<int> toDelete = Dbs.g.thumbnail!.writeTxnSync(() {
        final toDelete = Dbs.g.thumbnail!.thumbnails
            .where()
            .sortByUpdatedAt()
            .limit(l.length)
            .findAllSync()
            .map((e) => e.id)
            .toList();

        if (toDelete.isEmpty) {
          return [];
        }

        Dbs.g.thumbnail!.thumbnails.deleteAllSync(toDelete);

        return toDelete;
      });

      PlatformFunctions.deleteCachedThumbs(toDelete);
    }

    Dbs.g.thumbnail!.writeTxnSync(() {
      Dbs.g.thumbnail!.thumbnails.putAllSync(l
          .map((e) => Thumbnail(e.id, DateTime.now(), e.path, e.differenceHash))
          .toList());
    });
  }
}
