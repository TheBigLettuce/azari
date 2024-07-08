// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class ReadMangaChaptersService implements ServiceMarker {
  int get countDistinct;

  ReadMangaChapterData? firstForId(String siteMangaId);

  List<ReadMangaChapterData> lastRead(int limit);

  void touch({
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  });

  void setProgress(
    int progress, {
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  });

  void delete({
    required String siteMangaId,
    required String chapterId,
  });

  void deleteAllById(String siteMangaId, bool silent);

  int? progress({
    required String siteMangaId,
    required String chapterId,
  });

  StreamSubscription<void> watch(void Function(void) f);

  StreamSubscription<int> watchReading(void Function(int) f);

  StreamSubscription<int?> watchChapter(
    void Function(int?) f, {
    required String siteMangaId,
    required String chapterId,
  });
}

@immutable
abstract class ReadMangaChapterData {
  const ReadMangaChapterData();

  String get siteMangaId;
  String get chapterId;
  String get chapterName;
  String get chapterNumber;
  int get chapterProgress;
  DateTime get lastUpdated;
}
