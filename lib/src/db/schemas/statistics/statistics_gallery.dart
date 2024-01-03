// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

part 'statistics_gallery.g.dart';

@collection
class StatisticsGallery {
  final Id id = 0;

  final int viewedDirectories;
  final int viewedFiles;
  final int filesSwiped;
  final int joined;
  final int sameFiltered;
  final int deleted;
  final int copied;
  final int moved;

  const StatisticsGallery(
      {required this.copied,
      required this.deleted,
      required this.joined,
      required this.moved,
      required this.filesSwiped,
      required this.sameFiltered,
      required this.viewedDirectories,
      required this.viewedFiles});

  StatisticsGallery copy({
    int? viewedDirectories,
    int? viewedFiles,
    int? joined,
    int? filesSwiped,
    int? sameFiltered,
    int? deleted,
    int? copied,
    int? moved,
  }) =>
      StatisticsGallery(
          copied: copied ?? this.copied,
          deleted: deleted ?? this.deleted,
          joined: joined ?? this.joined,
          moved: moved ?? this.moved,
          filesSwiped: filesSwiped ?? this.filesSwiped,
          sameFiltered: sameFiltered ?? this.sameFiltered,
          viewedDirectories: viewedDirectories ?? this.viewedDirectories,
          viewedFiles: viewedFiles ?? this.viewedFiles);

  const StatisticsGallery.empty()
      : viewedDirectories = 0,
        viewedFiles = 0,
        joined = 0,
        filesSwiped = 0,
        sameFiltered = 0,
        deleted = 0,
        copied = 0,
        moved = 0;

  static StatisticsGallery get current =>
      Dbs.g.main.statisticsGallerys.getSync(0) ??
      const StatisticsGallery.empty();

  static void addViewedDirectories() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(viewedDirectories: c.viewedDirectories + 1)));
  }

  static void addViewedFiles() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(viewedFiles: c.viewedFiles + 1)));
  }

  static void addFilesSwiped() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(filesSwiped: c.filesSwiped + 1)));
  }

  static void addJoined() {
    final c = current;

    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.statisticsGallerys.putSync(c.copy(joined: c.joined + 1)));
  }

  static void addSameFiltered() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(sameFiltered: c.sameFiltered + 1)));
  }

  static void addDeleted(int count) {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(deleted: c.deleted + count)));
  }

  static void addCopied(int count) {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGallerys
        .putSync(c.copy(copied: c.copied + count)));
  }

  static void addMoved(int count) {
    final c = current;

    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.statisticsGallerys.putSync(c.copy(moved: c.moved + count)));
  }
}
