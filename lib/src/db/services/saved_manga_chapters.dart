// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

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
      final p = _currentDb.readMangaChapters.progress(
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
    ChaptersSettingsData s,
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

abstract interface class SavedMangaChaptersService implements ServiceMarker {
  int count(String mangaId, MangaMeta site);

  void clear(String mangaId, MangaMeta site);

  void add(
    String mangaId,
    MangaMeta site,
    List<MangaChapter> chapters,
    int page,
  );

  (List<MangaChapter>, int)? get(
    String mangaId,
    MangaMeta site,
    ChaptersSettingsData? settings,
    ReadMangaChaptersService readManga,
  );
}

@immutable
abstract class SavedMangaChaptersData {
  const SavedMangaChaptersData();

  String get mangaId;
  MangaMeta get site;
  List<MangaChapter> get chapters;
  int get page;
}

@immutable
class MangaChapter {
  const MangaChapter({
    required this.chapter,
    required this.pages,
    required this.title,
    required this.volume,
    required this.id,
    required this.translator,
  });

  final String id;

  final String title;
  final String chapter;
  final String volume;
  final String translator;

  final int pages;
}
