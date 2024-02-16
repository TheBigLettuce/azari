// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/manga/read_manga_chapter.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';

class NextChapterButton extends StatefulWidget {
  final String mangaId;
  final MangaAPI api;
  final String startingChapterId;
  final Color overlayColor;
  final void Function(int page, MangaImage cell) onNextPage;
  final void Function() reloadChapters;

  const NextChapterButton({
    super.key,
    required this.mangaId,
    required this.startingChapterId,
    required this.api,
    required this.overlayColor,
    required this.onNextPage,
    required this.reloadChapters,
  });

  @override
  State<NextChapterButton> createState() => NextChapterButtonState();
}

class NextChapterButtonState extends State<NextChapterButton> {
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
      null,
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

  Future _tryLoadNew(MangaChapter original) async {
    return await widget.api
        .chapters(
      MangaStringId(widget.mangaId),
      page: page,
      order: MangaChapterOrder.asc,
    )
        .then((value) {
      if (value.isEmpty) {
        reachedEnd = true;

        setState(() {});
      } else {
        chapters.addAll(value);
        page += 1;

        SavedMangaChapters.add(
          widget.mangaId,
          widget.api.site,
          value,
          page,
        );

        ReadMangaChapter.setProgress(
          original.pages,
          siteMangaId: widget.mangaId,
          chapterId: original.id,
        );

        _launch(value.first.id);
      }

      return value;
    }).whenComplete(() {
      progress = null;

      setState(() {});
    });
  }

  void _launch(String id) {
    currentChapter = id;

    final f = widget.api.imagesForChapter(MangaStringId(id));

    ReadMangaChapter.setProgress(
      1,
      siteMangaId: widget.mangaId,
      chapterId: id,
    );

    widget.reloadChapters();

    ReadMangaChapter.launchReader(
      context,
      f,
      widget.overlayColor,
      mangaId: MangaStringId(widget.mangaId),
      chapterId: id,
      api: widget.api,
      onNextPage: widget.onNextPage,
      reloadChapters: widget.reloadChapters,
      addNextChapterButton: true,
      replace: true,
    );
  }

  void findAndLaunchNext() {
    final idx = chapters.indexWhere((element) => element.id == currentChapter);
    if (idx == -1) {
      return;
    }
    final e = chapters.elementAtOrNull(idx + 1);
    if (e == null) {
      progress = _tryLoadNew(chapters[idx]);

      setState(() {});

      return;
    }

    final c = chapters[idx];

    ReadMangaChapter.setProgress(
      c.pages,
      siteMangaId: widget.mangaId,
      chapterId: c.id,
    );

    _launch(e.id);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: progress != null || reachedEnd ? null : findAndLaunchNext,
      icon: const Icon(Icons.navigate_next_rounded),
    );
  }
}
