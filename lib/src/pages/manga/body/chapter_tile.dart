// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class ChapterTile extends StatefulWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.entry,
    required this.api,
    required this.finishRead,
    required this.db,
  });

  final MangaChapter chapter;
  final MangaEntry entry;
  final MangaAPI api;
  final void Function() finishRead;

  final ReadMangaChaptersService db;

  @override
  State<ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<ChapterTile> {
  ReadMangaChaptersService get readChapters => widget.db;

  late final StreamSubscription<int?> watcher;

  int? progress;

  @override
  void initState() {
    super.initState();

    watcher = readChapters.watchChapter(
      (i) {
        setState(() {
          progress = i;
        });
      },
      siteMangaId: widget.entry.id.toString(),
      chapterId: widget.chapter.id,
    );

    progress = readChapters.progress(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return MenuWrapper(
      items: [
        PopupMenuItem(
          onTap: () {
            readChapters.setProgress(
              widget.chapter.pages,
              chapterNumber: widget.chapter.chapter,
              chapterName: widget.chapter.title,
              siteMangaId: widget.entry.id.toString(),
              chapterId: widget.chapter.id,
            );

            widget.finishRead();
          },
          child: Text(l10n.mangaMarkAsRead),
        ),
        PopupMenuItem(
          onTap: () {
            readChapters.delete(
              siteMangaId: widget.entry.id.toString(),
              chapterId: widget.chapter.id,
            );

            widget.finishRead();
          },
          child: Text(l10n.mangaRemoveProgress),
        ),
      ],
      includeCopy: false,
      title: l10n.mangaChapterName(widget.chapter.chapter),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
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
                      readChapters.setProgress(
                        1,
                        chapterNumber: widget.chapter.chapter,
                        chapterName: widget.chapter.title,
                        siteMangaId: widget.entry.id.toString(),
                        chapterId: widget.chapter.id,
                      );
                    }

                    ReadMangaChaptersService.launchReader(
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
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(left: 6)),
                Text(
                  progress == widget.chapter.pages
                      ? l10n.mangaProgressDone
                      : progress == null
                          ? widget.chapter.pages.toString()
                          : "$progress / ${widget.chapter.pages}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
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
