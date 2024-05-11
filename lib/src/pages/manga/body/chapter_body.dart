// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_chapters.dart";

class _ChapterBody extends StatefulWidget {
  const _ChapterBody({
    required this.api,
    required this.entry,
    required this.onFinishRead,
    required this.onNextLoad,
    required this.reachedEnd,
    required this.list,
    required this.settingsButton,
    required this.scrollController,
    required this.db,
  });

  final MangaEntry entry;
  final void Function() onFinishRead;
  final void Function() onNextLoad;
  final MangaAPI api;
  final Widget? reachedEnd;
  final List<(List<MangaChapter>, String)> list;
  final ScrollController scrollController;
  final Widget settingsButton;

  final ReadMangaChaptersService db;

  @override
  State<_ChapterBody> createState() => __ChapterBodyState();
}

class __ChapterBodyState extends State<_ChapterBody> {
  ReadMangaChaptersService get readChapters => widget.db;

  bool enabledScrolling = false;
  ReadMangaChapterData? _chapterStale;

  void _enableBlurOnScroll() {
    if (enabledScrolling) {
      setState(() {
        enabledScrolling = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    widget.scrollController.addListener(_enableBlurOnScroll);

    _chapterStale = readChapters.firstForId(widget.entry.id.toString());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_enableBlurOnScroll);

    super.dispose();
  }

  void readLatest(BuildContext context) {
    if (widget.list.isEmpty) {
      return;
    }

    final firstForId = readChapters.firstForId(widget.entry.id.toString());

    final r = firstForId?.chapterId ?? widget.list.first.$1.first.id;
    final n = firstForId?.chapterName ?? widget.list.first.$1.first.title;
    final v = firstForId?.chapterNumber ?? widget.list.first.$1.first.chapter;

    if (firstForId == null) {
      final c = widget.list.first.$1.first;

      readChapters.setProgress(
        1,
        chapterName: c.title,
        chapterNumber: c.chapter,
        siteMangaId: widget.entry.id.toString(),
        chapterId: c.id,
      );
    }

    if (_chapterStale == null) {
      _chapterStale = readChapters.firstForId(widget.entry.id.toString());

      setState(() {});
    }

    readChapters.launchReader(
      context,
      ReaderData(
        api: widget.api,
        chapterNumber: v,
        mangaId: widget.entry.id,
        mangaTitle: widget.entry.title,
        chapterName: n,
        chapterId: r,
        nextChapterKey: GlobalKey(),
        prevChaterKey: GlobalKey(),
        reloadChapters: widget.onFinishRead,
        onNextPage: (p, cell) {
          if (p + 1 == cell.maxPages) {
            widget.onFinishRead();
          }
        },
      ),
      addNextChapterButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ret = <Widget>[
      SliverToBoxAdapter(
        child: Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onPressed: () => readLatest(context),
                icon: const Icon(Icons.navigate_next_rounded),
                label: Text(
                  _chapterStale == null
                      ? AppLocalizations.of(context)!.mangaStartReading
                      : AppLocalizations.of(context)!.mangaContinueReading,
                ),
              ),
            ),
            widget.settingsButton,
          ],
        ),
      ),
    ];

    for (final e in widget.list) {
      ret.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 16),
            child: Text(
              AppLocalizations.of(context)!.mangaVolumeName(e.$2),
              style: SettingsLabel.defaultStyle(context),
            ),
          ),
        ),
      );
      ret.add(
        SliverList.builder(
          itemCount: e.$1.length,
          itemBuilder: (context, index) {
            final chapter = e.$1[index];

            return ChapterTile(
              key: ValueKey(chapter.id),
              finishRead: widget.onFinishRead,
              chapter: chapter,
              db: widget.db,
              entry: widget.entry,
              api: widget.api,
            );
          },
        ),
      );
    }

    if (widget.reachedEnd != null) {
      ret.add(widget.reachedEnd!);
    }

    return SliverMainAxisGroup(
      slivers: ret,
    );
  }
}
