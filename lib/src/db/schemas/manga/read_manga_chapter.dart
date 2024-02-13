// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/manga/chapters_settings.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
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

  static List<ReadMangaChapter> lastRead(int limit) {
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

  static void touch({
    required String siteMangaId,
    required String chapterId,
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
        chapterProgress: e.chapterProgress,
        lastUpdated: DateTime.now(),
      )),
    );
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
      silent: Dbs.g.anime.readMangaChapters
              .getBySiteMangaIdChapterIdSync(siteMangaId, chapterId) !=
          null,
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

  static void launchReader(
    BuildContext context,
    Future<List<MangaImage>> f,
    Color overlayColor, {
    required MangaId mangaId,
    required String chapterId,
    required MangaAPI api,
    required void Function(int page) onNextPage,
    bool addNextChapterButton = false,
    bool replace = false,
  }) {
    ReadMangaChapter.touch(
      siteMangaId: mangaId.toString(),
      chapterId: chapterId.toString(),
    );

    final p = ReadMangaChapter.progress(
      siteMangaId: mangaId.toString(),
      chapterId: chapterId,
    );

    final route = MaterialPageRoute(
      builder: (context) {
        return FutureBuilder(
          future: f,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final chapters = snapshot.data!;

              return ImageView<MangaImage>(
                ignoreLoadingBuilder: true,
                appBarItems: [
                  if (addNextChapterButton)
                    _NextChapterButton(
                      overlayColor: overlayColor,
                      mangaId: mangaId.toString(),
                      startingChapterId: chapterId,
                      api: api,
                    )
                ],
                switchPageOnTapEdges: true,
                pageChange: (state) {
                  ReadMangaChapter.setProgress(
                    state.currentPage + 1,
                    siteMangaId: mangaId.toString(),
                    chapterId: chapterId,
                  );

                  onNextPage(state.currentPage);
                },
                ignoreEndDrawer: true,
                updateTagScrollPos: (_, __) {},
                cellCount: chapters.length,
                scrollUntill: (_) {},
                startingCell: p != null ? p - 1 : 0,
                onExit: () {},
                getCell: (i) => chapters[i],
                onNearEnd: null,
                focusMain: () {},
                systemOverlayRestoreColor: overlayColor,
              );
            } else {
              return Scaffold(
                appBar: snapshot.hasError
                    ? AppBar(
                        leading: const BackButton(),
                      )
                    : null,
                body: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        );
      },
    );

    if (replace) {
      Navigator.pushReplacement(
        context,
        route,
      );
    } else {
      Navigator.push(
        context,
        route,
      );
    }
  }
}

class _NextChapterButton extends StatefulWidget {
  final String mangaId;
  final MangaAPI api;
  final String startingChapterId;
  final Color overlayColor;

  const _NextChapterButton({
    super.key,
    required this.mangaId,
    required this.startingChapterId,
    required this.api,
    required this.overlayColor,
  });

  @override
  State<_NextChapterButton> createState() => __NextChapterButtonState();
}

class __NextChapterButtonState extends State<_NextChapterButton> {
  Future? progress;

  final List<MangaChapter> chapters = [];
  int page = 0;
  late String currentChapter = widget.startingChapterId;
  bool reachedEnd = false;

  @override
  void initState() {
    super.initState();

    final r = SavedMangaChapters.get(
      widget.mangaId,
      widget.api.site,
      ChapterSettings.current,
    );

    if (r != null) {
      chapters.addAll(r.$1);
      page = r.$2;
    }
  }

  @override
  void dispose() {
    progress?.ignore();

    super.dispose();
  }

  Future _tryLoadNew() async {
    return await widget.api
        .chapters(
      MangaStringId(widget.mangaId),
      page: page + 1,
      order: MangaChapterOrder.asc,
    )
        .then((value) {
      if (value.isEmpty) {
        reachedEnd = true;

        setState(() {});
      } else {
        page += 1;
        _launch(value.first.id);
      }

      return value;
    }).whenComplete(() {
      progress = null;

      setState(() {});
    });
  }

  void _launch(String id) {
    final f = widget.api.imagesForChapter(MangaStringId(id));

    ReadMangaChapter.launchReader(
      context,
      f,
      widget.overlayColor,
      mangaId: MangaStringId(widget.mangaId),
      chapterId: id,
      api: widget.api,
      onNextPage: (p) {},
      addNextChapterButton: true,
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: progress != null || reachedEnd
          ? null
          : () {
              final idx = chapters
                  .indexWhere((element) => element.id == currentChapter);
              final e = chapters.elementAtOrNull(idx + 1);
              if (e == null) {
                progress = _tryLoadNew();

                setState(() {});

                return;
              }

              _launch(e.id);
            },
      icon: const Icon(Icons.navigate_next_rounded),
    );
  }
}
