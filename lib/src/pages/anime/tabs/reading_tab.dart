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

  Future<int> refresh() async {
    data.clear();

    final l = ReadMangaChapter.lastRead(-1);
    for (final e in l) {
      final d = CompactMangaData.get(e.siteMangaId, widget.api.site);
      if (d != null) {
        data.add(d);
      }
    }

    return data.length;
  }

  @override
  void initState() {
    super.initState();

    watcher = ReadMangaChapter.watch((_) {
      if (inInner) {
        dirty = true;
      } else {
        refresh();
      }
    });
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

    inInner = true;

    ReadMangaChapter.launchReader(
      context,
      f,
      Theme.of(context).colorScheme.background,
      mangaId: MangaStringId(e.mangaId),
      chapterId: c.chapterId,
      onNextPage: (p, cell) {},
      reloadChapters: () {},
      api: widget.api,
      addNextChapterButton: true,
    ).then((value) {
      _procReload();
    });
  }

  void _procReload() {
    inInner = false;

    if (dirty) {
      state.gridKey.currentState?.mutationInterface.tick(0);
      state.gridKey.currentState?.mutationInterface.setIsRefreshing(true);
      refresh().whenComplete(() {
        state.gridKey.currentState?.mutationInterface.tick(data.length);
        state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);
      });
    }
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
          inInner = true;

          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return MangaInfoPage(
                entry: f,
                api: widget.api,
              );
            },
          )).then((value) {
            _procReload();
          });
        },
        selectionGlue:
            GlueProvider.generateOf<AnimeEntry, CompactMangaData>(context),
        mainFocus: state.mainFocus,
        refresh: refresh,
        description: GridDescription(
          [
            GridAction(
              Icons.remove_circle_outline_rounded,
              (selected) {
                for (final e in selected.indexed) {
                  ReadMangaChapter.deleteAllId(
                      e.$2.mangaId, e.$1 != selected.length - 1);
                }
              },
              true,
            ),
          ],
          ignoreEmptyWidgetOnNoContent: true,
          ignoreSwipeSelectGesture: true,
          showAppBar: false,
          keybindsDescription: "Read tab",
          layout: _ReadingLayout(
              startReadingLast: _startReadingLast, gridSeed: state.gridSeed),
        ),
      ),
      canPop: false,
    );
  }
}

class _ReadingLayout implements GridLayouter<CompactMangaData> {
  final void Function() startReadingLast;
  final int gridSeed;

  const _ReadingLayout({
    required this.startReadingLast,
    required this.gridSeed,
  });

  @override
  List<Widget> call(
      BuildContext context, GridFrameState<CompactMangaData> state) {
    return [
      SliverToBoxAdapter(
        child: SegmentLabel(
          "Reading",
          hidePinnedIcon: true,
          onPress: null,
          sticky: false,
          overridePinnedIcon: TextButton(
            onPressed: state.mutationInterface.cellCount == 0
                ? null
                : startReadingLast,
            child: Text("Read last"),
          ),
        ),
      ),
      if (state.mutationInterface.cellCount == 0)
        SliverToBoxAdapter(
          child: EmptyWidget(
            gridSeed: gridSeed,
          ),
        )
      else
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
