// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class ReadingTab extends StatefulWidget {
  final void Function() onDispose;
  final EdgeInsets viewInsets;
  final MangaAPI api;

  const ReadingTab(
    this.viewInsets, {
    super.key,
    required this.api,
    required this.onDispose,
  });

  @override
  State<ReadingTab> createState() => _ReadingTabState();
}

class _ReadingTabState extends State<ReadingTab> {
  late final StreamSubscription<void> watcher;

  final data = <CompactMangaData>[];
  final state = GridSkeletonState<CompactMangaData>();

  bool dirty = false;

  bool inInner = false;

  void refresh() {
    data.clear();

    final l = ReadMangaChapter.lastRead(10);
    for (final e in l) {
      final d = CompactMangaData.get(e.siteMangaId, widget.api.site);
      if (d != null) {
        data.add(d);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    watcher = ReadMangaChapter.watch((_) {
      refresh();

      setState(() {});
    });

    refresh();
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  void _startReadingLast() {
    final c = ReadMangaChapter.lastRead(1).first;
    final f = widget.api.imagesForChapter(MangaStringId(c.chapterId));
    final e = data.first;

    ReadMangaChapter.launchReader(
      context,
      f,
      Theme.of(context).colorScheme.background,
      mangaId: MangaStringId(e.mangaId),
      chapterId: c.chapterId,
      onNextPage: (p) {},
      api: widget.api,
      addNextChapterButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<CompactMangaData>(
      state,
      (context) => GridFrame<CompactMangaData>(
        key: state.gridKey,
        getCell: (i) => data[i],
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets: widget.viewInsets,
        hasReachedEnd: () => true,
        overrideOnPress: (context, cell) {
          final f = widget.api.single(MangaStringId(cell.mangaId));

          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return MangaInnerPage(
                entry: f,
                api: widget.api,
              );
            },
          ));
        },
        selectionGlue:
            GlueProvider.generateOf<AnimeEntry, CompactMangaData>(context),
        mainFocus: state.mainFocus,
        refresh: () {
          return Future.value(data.length);
        },
        description: GridDescription(
          [],
          ignoreSwipeSelectGesture: true,
          showAppBar: false,
          keybindsDescription: "Read tab",
          layout: _ReadingLayout(
            startReadingLast: _startReadingLast,
            // GridColumn.three,
            // GridAspectRatio.one,
            // hideAlias: false,
          ),
        ),
      ),
      canPop: false,
    );
  }
}

class _ReadingLayout implements GridLayouter<CompactMangaData> {
  final void Function() startReadingLast;

  const _ReadingLayout({
    required this.startReadingLast,
  });

  @override
  List<Widget> call(
      BuildContext context, GridFrameState<CompactMangaData> state) {
    return [
      SliverToBoxAdapter(
        child: SegmentLabel(
          "Last 10",
          hidePinnedIcon: true,
          onPress: null,
          sticky: false,
          overridePinnedIcon: IconButton(
            onPressed: state.mutationInterface.cellCount == 0
                ? null
                : startReadingLast,
            icon: const Icon(
              Icons.forward,
            ),
          ),
        ),
      ),
      GridLayouts.grid<CompactMangaData>(
        context,
        state.mutationInterface,
        state.selection,
        columns.number,
        false,
        state.makeGridCell,
        hideAlias: false,
        tightMode: true,
        systemNavigationInsets: 0,
        aspectRatio: GridAspectRatio.zeroSeven.value,
      ),
    ];
  }

  @override
  GridColumn get columns => GridColumn.three;

  @override
  bool get isList => false;
}
