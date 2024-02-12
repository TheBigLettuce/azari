// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

part 'read_manga_chapter.g.dart';

@collection
class ReadMangaChapter {
  ReadMangaChapter({
    required this.siteMangaId,
    required this.chapterId,
    required this.chapterProgress,
    required this.lastUpdated,
  });

  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("chapterId")])
  final String siteMangaId;
  final String chapterId;

  final int chapterProgress;

  @Index()
  final DateTime lastUpdated;

  static ReadMangaChapter? firstForId(String siteMangaId) {
    return Dbs.g.anime.readMangaChapters
        .filter()
        .siteMangaIdEqualTo(siteMangaId)
        .sortByLastUpdatedDesc()
        .findFirstSync();
  }

  static List<ReadMangaChapter> lastRead(String siteMangaId, int limit) {
    return Dbs.g.anime.readMangaChapters
        .filter()
        .siteMangaIdEqualTo(siteMangaId)
        .sortByLastUpdatedDesc()
        .distinctBySiteMangaId()
        .limit(limit)
        .findAllSync();
  }

  static void setProgress(
    int progress, {
    required String siteMangaId,
    required String chapterId,
  }) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.readMangaChapters
          .putBySiteMangaIdChapterIdSync(ReadMangaChapter(
        siteMangaId: siteMangaId,
        chapterId: chapterId,
        chapterProgress: progress,
        lastUpdated: DateTime.now(),
      )),
    );
  }

  static void delete({
    required String siteMangaId,
    required String chapterId,
  }) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.readMangaChapters
          .deleteBySiteMangaIdChapterIdSync(siteMangaId, chapterId),
    );
  }

  static int? progress({
    required String siteMangaId,
    required String chapterId,
  }) {
    final p = Dbs.g.anime.readMangaChapters
        .getBySiteMangaIdChapterIdSync(siteMangaId, chapterId)
        ?.chapterProgress;

    if (p?.isNegative == true) {
      delete(siteMangaId: siteMangaId, chapterId: chapterId);

      return null;
    }

    return p;
  }
}
