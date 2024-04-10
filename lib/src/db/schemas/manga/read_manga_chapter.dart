// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/manga/next_chapter_button.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';

part 'read_manga_chapter.g.dart';

@collection
class ReadMangaChapter {
  ReadMangaChapter({
    required this.siteMangaId,
    required this.chapterId,
    required this.chapterProgress,
    required this.lastUpdated,
    required this.chapterName,
    required this.chapterNumber,
  });

  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("chapterId")])
  final String siteMangaId;
  final String chapterId;
  final String chapterName;
  final String chapterNumber;

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

  static List<ReadMangaChapter> lastRead(int limit) {
    if (limit == 0) {
      return const [];
    }

    if (limit.isNegative) {
      return Dbs.g.anime.readMangaChapters
          .where()
          .sortByLastUpdatedDesc()
          .distinctBySiteMangaId()
          .findAllSync();
    }

    return Dbs.g.anime.readMangaChapters
        .where()
        .sortByLastUpdatedDesc()
        .distinctBySiteMangaId()
        .limit(limit)
        .findAllSync();
  }

  static int countDistinct() {
    return Dbs.g.anime.readMangaChapters
        .where(distinct: true)
        .distinctBySiteMangaId()
        .countSync();
  }

  static StreamSubscription<void> watch(void Function(void) f) {
    return Dbs.g.anime.readMangaChapters.watchLazy().listen(f);
  }

  static StreamSubscription<int> watchReading(void Function(int) f) {
    return Dbs.g.anime.readMangaChapters
        .watchLazy(fireImmediately: true)
        .map((event) => countDistinct())
        .listen(f);
  }

  static StreamSubscription<int?> watchChapter(
    void Function(int?) f, {
    required String siteMangaId,
    required String chapterId,
  }) {
    return Dbs.g.anime.readMangaChapters
        .where()
        .siteMangaIdChapterIdEqualTo(siteMangaId, chapterId)
        .watch()
        .map((event) {
      if (event.isEmpty) {
        return null;
      }

      return event.first.chapterProgress;
    }).listen(f);
  }

  static void touch({
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    final e = Dbs.g.anime.readMangaChapters
        .getBySiteMangaIdChapterIdSync(siteMangaId, chapterId);
    if (e == null) {
      return;
    }

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.readMangaChapters
          .putBySiteMangaIdChapterIdSync(ReadMangaChapter(
        siteMangaId: siteMangaId,
        chapterId: chapterId,
        chapterName: chapterName,
        chapterNumber: chapterNumber,
        chapterProgress: e.chapterProgress,
        lastUpdated: DateTime.now(),
      )),
    );
  }

  static void setProgress(
    int progress, {
    required String siteMangaId,
    required String chapterId,
    required String chapterName,
    required String chapterNumber,
  }) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.readMangaChapters
          .putBySiteMangaIdChapterIdSync(ReadMangaChapter(
        siteMangaId: siteMangaId,
        chapterId: chapterId,
        chapterNumber: chapterNumber,
        chapterName: chapterName,
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

  static void deleteAllId(String siteMangaId, bool silent) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.readMangaChapters
          .filter()
          .siteMangaIdEqualTo(siteMangaId)
          .deleteAllSync(),
      silent: silent,
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

  static Future launchReader(
    BuildContext context,
    ReaderData data, {
    bool addNextChapterButton = false,
    bool replace = false,
  }) {
    ReadMangaChapter.touch(
      siteMangaId: data.mangaId.toString(),
      chapterId: data.chapterId.toString(),
      chapterName: data.chapterName,
      chapterNumber: data.chapterNumber,
    );

    final p = ReadMangaChapter.progress(
      siteMangaId: data.mangaId.toString(),
      chapterId: data.chapterId,
    );

    final nextChapterKey = GlobalKey<SkipChapterButtonState>();
    final prevChaterKey = GlobalKey<SkipChapterButtonState>();

    final route = MaterialPageRoute(
      builder: (context) {
        return WrapFutureRestartable(
          newStatus: () {
            return data.api.imagesForChapter(MangaStringId(data.chapterId));
          },
          builder: (context, chapters) {
            return GlueProvider.empty(
              context,
              child: ImageView(
                registerNotifiers: !addNextChapterButton
                    ? null
                    : (child) => MangaReaderNotifier(
                          data: data,
                          child: child,
                        ),
                ignoreLoadingBuilder: true,
                download: (i) {
                  final image = chapters[i];

                  Downloader.g.add(
                    DownloadFile.d(
                      name:
                          "${i.toString()} / ${image.maxPages} - $data.chapterId.${image.url.split(".").last}",
                      url: image.url,
                      thumbUrl: image.url,
                      site: data.mangaTitle,
                    ),
                    Settings.fromDb(),
                  );
                },

                onRightSwitchPageEnd: addNextChapterButton
                    ? () {
                        nextChapterKey.currentState?.findAndLaunchNext();
                      }
                    : null,
                onLeftSwitchPageEnd: addNextChapterButton
                    ? () {
                        prevChaterKey.currentState?.findAndLaunchNext();
                      }
                    : null,
                pageChange: (state) {
                  // state.drawCell(state.currentPage, true)
                  ReadMangaChapter.setProgress(
                    state.currentPage + 1,
                    chapterName: data.chapterName,
                    chapterNumber: data.chapterNumber,
                    siteMangaId: data.mangaId.toString(),
                    chapterId: data.chapterId,
                  );

                  data.onNextPage(
                      state.currentPage, chapters[state.currentPage]);
                },
                // ignoreEndDrawer: true,
                cellCount: chapters.length,
                scrollUntill: (_) {},
                startingCell: p != null ? p - 1 : 0,
                onExit: () {},
                getCell: (context, i) => chapters[i].content(context),
                onNearEnd: null,
                systemOverlayRestoreColor: data.overlayColor,
              ),
            );
          },
        );
      },
    );

    if (replace) {
      return Navigator.of(context, rootNavigator: true).pushReplacement(
        route,
      );
    } else {
      return Navigator.of(context, rootNavigator: true).push(
        route,
      );
    }
  }
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
    required this.overlayColor,
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

  final Color overlayColor;
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
