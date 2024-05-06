// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/read_manga_chapter.dart";
import "package:gallery/src/db/services/impl/isar/schemas/manga/saved_manga_chapters.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class ChapterTile extends StatefulWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.entry,
    required this.api,
    required this.finishRead,
  });
  final MangaChapter chapter;
  final MangaEntry entry;
  final MangaAPI api;
  final void Function() finishRead;

  @override
  State<ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<ChapterTile> {
  late final StreamSubscription<int?> watcher;

  int? progress;

  @override
  void initState() {
    super.initState();

    watcher = ReadMangaChapter.watchChapter(
      (i) {
        setState(() {
          progress = i;
        });
      },
      siteMangaId: widget.entry.id.toString(),
      chapterId: widget.chapter.id,
    );

    progress = ReadMangaChapter.progress(
      siteMangaId: widget.entry.id.toString(),
      chapterId: widget.chapter.id,
    );
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuWrapper(
      items: [
        PopupMenuItem(
          onTap: () {
            ReadMangaChapter.setProgress(
              widget.chapter.pages,
              chapterNumber: widget.chapter.chapter,
              chapterName: widget.chapter.title,
              siteMangaId: widget.entry.id.toString(),
              chapterId: widget.chapter.id,
            );

            widget.finishRead();
          },
          child: Text(AppLocalizations.of(context)!.mangaMarkAsRead),
        ),
        PopupMenuItem(
          onTap: () {
            ReadMangaChapter.delete(
              siteMangaId: widget.entry.id.toString(),
              chapterId: widget.chapter.id,
            );

            widget.finishRead();
          },
          child: Text(AppLocalizations.of(context)!.mangaRemoveProgress),
        ),
      ],
      includeCopy: false,
      title: AppLocalizations.of(context)!
          .mangaChapterName(widget.chapter.chapter),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            enabled: widget.chapter.pages != 0,
            onTap: widget.chapter.pages == 0
                ? null
                : () {
                    if (progress == null) {
                      ReadMangaChapter.setProgress(
                        1,
                        chapterNumber: widget.chapter.chapter,
                        chapterName: widget.chapter.title,
                        siteMangaId: widget.entry.id.toString(),
                        chapterId: widget.chapter.id,
                      );
                    }

                    ReadMangaChapter.launchReader(
                      context,
                      ReaderData(
                        chapterNumber: widget.chapter.chapter,
                        chapterName: widget.chapter.title,
                        api: widget.api,
                        mangaId: widget.entry.id,
                        mangaTitle: widget.entry.title,
                        chapterId: widget.chapter.id,
                        nextChapterKey: GlobalKey(),
                        prevChaterKey: GlobalKey(),
                        reloadChapters: widget.finishRead,
                        onNextPage: (currentPage, cell) {
                          if (currentPage + 1 == widget.chapter.pages) {
                            widget.finishRead();
                          }
                        },
                      ),
                    );
                  },
            contentPadding: const EdgeInsets.only(right: 16, left: 16),
            subtitle: Text(
              "${widget.chapter.title}${widget.chapter.translator.isNotEmpty ? ' (${widget.chapter.translator})' : ''}",
            ),
            title: Row(
              children: [
                Transform.rotate(
                  transformHitTests: false,
                  angle: 5 * (-pi / 180),
                  child: Text(
                    widget.chapter.chapter,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(left: 6)),
                Text(
                  progress == widget.chapter.pages
                      ? AppLocalizations.of(context)!.mangaProgressDone
                      : progress == null
                          ? widget.chapter.pages.toString()
                          : "$progress / ${widget.chapter.pages}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
