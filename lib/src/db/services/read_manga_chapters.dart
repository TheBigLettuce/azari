// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract class ReadMangaChapterData {
  const ReadMangaChapterData({
    required this.siteMangaId,
    required this.chapterId,
    required this.chapterProgress,
    required this.lastUpdated,
    required this.chapterName,
    required this.chapterNumber,
  });

  @Index(unique: true, replace: true, composite: [CompositeIndex("chapterId")])
  final String siteMangaId;
  final String chapterId;
  final String chapterName;
  final String chapterNumber;

  final int chapterProgress;

  @Index()
  final DateTime lastUpdated;
}

@immutable
class ReaderData {
  const ReaderData({
    required this.api,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterId,
    required this.nextChapterKey,
    required this.prevChaterKey,
    required this.reloadChapters,
    required this.onNextPage,
    required this.chapterName,
    required this.chapterNumber,
  });

  final MangaAPI api;
  final MangaId mangaId;
  final String mangaTitle;
  final String chapterId;
  final String chapterName;
  final String chapterNumber;

  final GlobalKey<SkipChapterButtonState> nextChapterKey;
  final GlobalKey<SkipChapterButtonState> prevChaterKey;

  final void Function() reloadChapters;
  final void Function(int page, MangaImage cell) onNextPage;
}

class MangaReaderNotifier extends InheritedWidget {
  const MangaReaderNotifier({
    super.key,
    required this.data,
    required super.child,
  });

  final ReaderData data;

  static ReaderData? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<MangaReaderNotifier>();

    return widget?.data;
  }

  @override
  bool updateShouldNotify(MangaReaderNotifier oldWidget) {
    return data != oldWidget.data;
  }
}

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

  Future<void> launchReader(
    BuildContext context,
    ReaderData data, {
    bool addNextChapterButton = false,
    bool replace = false,
  });

  StreamSubscription<void> watch(void Function(void) f);

  StreamSubscription<int> watchReading(void Function(int) f);

  StreamSubscription<int?> watchChapter(
    void Function(int?) f, {
    required String siteMangaId,
    required String chapterId,
  });
}
