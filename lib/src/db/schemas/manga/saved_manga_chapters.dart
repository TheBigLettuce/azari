// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/db/schemas/manga/chapters_settings.dart";
import "package:gallery/src/db/schemas/manga/read_manga_chapter.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:isar/isar.dart";

part "saved_manga_chapters.g.dart";

@collection
class SavedMangaChapters {
  SavedMangaChapters({
    required this.chapters,
    required this.mangaId,
    required this.site,
    required this.page,
  });

  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("site")])
  final String mangaId;

  @enumerated
  final MangaMeta site;

  final List<MangaChapter> chapters;

  final int page;

  static void clear(String mangaId, MangaMeta site) {
    Dbs.g.anime.writeTxnSync(
      () =>
          Dbs.g.anime.savedMangaChapters.deleteByMangaIdSiteSync(mangaId, site),
    );
  }

  static void add(
    String mangaId,
    MangaMeta site,
    List<MangaChapter> chapters,
    int page,
  ) {
    final prev =
        Dbs.g.anime.savedMangaChapters.getByMangaIdSiteSync(mangaId, site);

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.savedMangaChapters.putByMangaIdSiteSync(
        SavedMangaChapters(
          page: page,
          chapters: (prev?.chapters ?? const []) + chapters,
          mangaId: mangaId,
          site: site,
        ),
      ),
    );
  }

  static int count(String mangaId, MangaMeta site) {
    return Dbs.g.anime.savedMangaChapters
        .where()
        .mangaIdSiteEqualTo(mangaId, site)
        .countSync();
  }

  static (List<MangaChapter>, int)? get(
    String mangaId,
    MangaMeta site,
    ChapterSettings? settings,
  ) {
    final prev =
        Dbs.g.anime.savedMangaChapters.getByMangaIdSiteSync(mangaId, site);

    if (prev == null) {
      return null;
    }

    if (settings != null && settings.hideRead) {
      return (
        prev.chapters.where((element) {
          final p = ReadMangaChapter.progress(
            siteMangaId: mangaId,
            chapterId: element.id,
          );

          if (p == null) {
            return true;
          }

          return p != element.pages;
        }).toList(),
        prev.page
      );
    }

    return (prev.chapters, prev.page);
  }
}

@embedded
class MangaChapter {
  const MangaChapter({
    this.chapter = "",
    this.pages = -1,
    this.title = "",
    this.volume = "",
    this.id = "",
    this.translator = "",
  })
  // : assert(pages != -1 && id != "")
  ;
  final String id;

  final String title;
  final String chapter;
  final String volume;
  final String translator;

  final int pages;
}

extension MangaChapterExt2 on List<(List<MangaChapter>, String)> {
  List<MangaChapter> joinOrdered() {
    final ret = <MangaChapter>[];

    for (final e in this) {
      ret.addAll(e.$1);
    }

    return ret;
  }
}

extension MangaChapterExt on List<MangaChapter> {
  Iterable<MangaChapter> notRead(String mangaId) {
    return where((element) {
      final p = ReadMangaChapter.progress(
        siteMangaId: mangaId,
        chapterId: element.id,
      );

      if (p == null) {
        return true;
      }

      return p != element.pages;
    });
  }

  List<(List<MangaChapter>, String)> splitVolumes(
    String mangaId,
    ChapterSettings s,
  ) {
    final ret = <String, List<MangaChapter>>{};

    for (final e in (s.hideRead ? notRead(mangaId) : this)) {
      final l = ret[e.volume];
      if (l == null) {
        ret[e.volume] = [];
      }

      ret[e.volume]!.add(e);
    }

    return ret.entries.map((e) => (e.value, e.key)).toList();
  }
}
