// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'manga_chapters.dart';

class _ChapterBody extends StatefulWidget {
  final MangaEntry entry;
  final Color? overlayColor;
  final void Function() onFinishRead;
  final void Function() onNextLoad;
  final MangaAPI api;
  final Widget? reachedEnd;
  final List<(List<MangaChapter>, String)> list;
  final ScrollController scrollController;

  const _ChapterBody({
    super.key,
    required this.api,
    required this.entry,
    required this.onFinishRead,
    required this.onNextLoad,
    required this.overlayColor,
    required this.reachedEnd,
    required this.list,
    required this.scrollController,
  });

  @override
  State<_ChapterBody> createState() => __ChapterBodyState();
}

class __ChapterBodyState extends State<_ChapterBody> {
  bool enabledScrolling = false;
  ReadMangaChapter? _chapterStale;

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

    _chapterStale = ReadMangaChapter.firstForId(widget.entry.id.toString());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_enableBlurOnScroll);

    super.dispose();
  }

  List<Widget> makeSlivers(
      BuildContext context, List<(List<MangaChapter>, String)> l) {
    final ret = <Widget>[];

    for (final e in l) {
      ret.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            AppLocalizations.of(context)!.mangaVolumeName(e.$2),
            style: SettingsLabel.defaultStyle(context),
          ),
        ),
      ));
      ret.add(
        SliverList.list(
            children: e.$1.map((e) {
          return ChapterTile(
            key: ValueKey(e.id),
            finishRead: widget.onFinishRead,
            chapter: e,
            entry: widget.entry,
            api: widget.api,
            overlayColor: widget.overlayColor,
          );
        }).toList()),
      );
    }

    if (widget.reachedEnd != null) {
      ret.add(widget.reachedEnd!);
    }

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    void readLatest() {
      if (widget.list.isEmpty) {
        return;
      }

      final firstForId =
          ReadMangaChapter.firstForId(widget.entry.id.toString());

      final r = firstForId?.chapterId ?? widget.list.first.$1.first.id;

      if (firstForId == null) {
        ReadMangaChapter.setProgress(
          1,
          siteMangaId: widget.entry.id.toString(),
          chapterId: widget.list.first.$1.first.id,
        );
      }

      if (_chapterStale == null) {
        _chapterStale = ReadMangaChapter.firstForId(widget.entry.id.toString());

        setState(() {});
      }

      ReadMangaChapter.launchReader(
        context,
        mangaTitle: widget.entry.title,
        reloadChapters: widget.onFinishRead,
        widget.overlayColor ?? Theme.of(context).colorScheme.background,
        mangaId: widget.entry.id,
        chapterId: r,
        api: widget.api,
        addNextChapterButton: true,
        onNextPage: (p, cell) {
          if (p + 1 == cell.maxPages) {
            widget.onFinishRead();
          }
        },
      );
    }

    return Stack(
      fit: StackFit.loose,
      children: [
        GestureDetector(
          onTap: () {
            enabledScrolling = !enabledScrolling;

            setState(() {});
          },
          child: AbsorbPointer(
            absorbing: !enabledScrolling,
            child: Animate(
              target: enabledScrolling ? 0 : 1,
              effects: [
                BlurEffect(
                  duration: 360.ms,
                  curve: Easing.linear,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                ),
              ],
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.elliptical(10, 10)),
                clipBehavior: Clip.antiAlias,
                child: CustomScrollView(
                  clipBehavior: Clip.none,
                  primary: false,
                  scrollDirection: Axis.vertical,
                  slivers: makeSlivers(
                    context,
                    widget.list,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 8),
            child: Align(
              alignment: Alignment.topRight,
              child: Animate(
                target: enabledScrolling ? 1 : 0,
                effects: [
                  FadeEffect(duration: 140.ms, begin: 1, end: 0),
                  SwapEffect(
                    builder: (_, __) {
                      return IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        onPressed: readLatest,
                        icon: const Icon(Icons.navigate_next_rounded),
                      ).animate().fadeIn(duration: 140.ms);
                    },
                  )
                ],
                child: FilledButton.tonalIcon(
                  onPressed: readLatest,
                  icon: const Icon(Icons.navigate_next_rounded),
                  label: Text(
                    _chapterStale == null
                        ? AppLocalizations.of(context)!.mangaStartReading
                        : AppLocalizations.of(context)!.mangaContinueReading,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
