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

enum SkipDirection {
  right,
  left;
}

class SkipChapterButton extends StatefulWidget {
  final String mangaId;
  final String mangaTitle;
  final MangaAPI api;
  final String startingChapterId;
  final Color overlayColor;
  final void Function(int page, MangaImage cell) onNextPage;
  final void Function() reloadChapters;
  final SkipDirection direction;

  const SkipChapterButton({
    super.key,
    required this.mangaId,
    required this.startingChapterId,
    required this.api,
    required this.overlayColor,
    required this.onNextPage,
    required this.reloadChapters,
    required this.direction,
    required this.mangaTitle,
  });

  @override
  State<SkipChapterButton> createState() => SkipChapterButtonState();
}

class SkipChapterButtonState extends State<SkipChapterButton> {
  Future? progress;

  final List<MangaChapter> chapters = [];
  int page = 0;
  late String currentChapter = widget.startingChapterId;
  bool reachedEnd = false;
  bool cantSeekBack = false;

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

        if (widget.direction == SkipDirection.right) {
          ReadMangaChapter.setProgress(
            original.pages,
            chapterNumber: original.chapter,
            chapterName: original.title,
            siteMangaId: widget.mangaId,
            chapterId: original.id,
          );
        }

        _launch(value.first.id, original.title, original.chapter);
      }

      return value;
    }).whenComplete(() {
      progress = null;

      setState(() {});
    });
  }

  void _launch(String id, String name, String chapterNumber) {
    currentChapter = id;

    widget.reloadChapters();

    ReadMangaChapter.launchReader(
      context,
      ReaderData(
        chapterNumber: chapterNumber,
        chapterName: name,
        api: widget.api,
        mangaId: MangaStringId(widget.mangaId),
        mangaTitle: widget.mangaTitle,
        chapterId: id,
        nextChapterKey: GlobalKey(),
        prevChaterKey: GlobalKey(),
        reloadChapters: widget.reloadChapters,
        onNextPage: widget.onNextPage,
        overlayColor: widget.overlayColor,
      ),
      addNextChapterButton: true,
      replace: true,
    );
  }

  void findAndLaunchNext() {
    if (cantSeekBack) {
      return;
    }

    final idx = chapters.indexWhere((element) => element.id == currentChapter);
    if (idx == -1) {
      return;
    }

    if (widget.direction == SkipDirection.left && idx == 0) {
      cantSeekBack = true;

      setState(() {});
      return;
    }

    final e = chapters.elementAtOrNull(
        widget.direction == SkipDirection.right ? idx + 1 : idx - 1);
    if (e == null) {
      progress = _tryLoadNew(chapters[idx]);

      setState(() {});

      return;
    }

    final c = chapters[idx];

    if (widget.direction == SkipDirection.right) {
      ReadMangaChapter.setProgress(
        c.pages,
        chapterNumber: c.chapter,
        chapterName: c.title,
        siteMangaId: widget.mangaId,
        chapterId: c.id,
      );
    }

    _launch(e.id, c.title, c.volume);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: progress != null || reachedEnd || cantSeekBack
          ? null
          : findAndLaunchNext,
      icon: widget.direction == SkipDirection.right
          ? const Icon(Icons.navigate_next_rounded)
          : const Icon(Icons.navigate_before_rounded),
    );
  }
}
