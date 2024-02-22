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
  final state = GridSkeletonState<CompactMangaDataBase>();

  bool dirty = false;

  bool inInner = false;

  Future<int> refresh() async {
    data.clear();

    final l = ReadMangaChapter.lastRead(50);
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
        _refreshGrid();
      }
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  void _startReading(int i) {
    final c = ReadMangaChapter.firstForId(data[i].mangaId);
    assert(c != null);
    if (c == null) {
      return;
    }

    final e = data[i];

    inInner = true;

    ReadMangaChapter.launchReader(
      context,
      Theme.of(context).colorScheme.background,
      mangaTitle: e.title,
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
      _refreshGrid();
    }
  }

  void _refreshGrid() {
    state.gridKey.currentState?.mutationInterface.tick(0);
    state.gridKey.currentState?.mutationInterface.setIsRefreshing(true);
    refresh().whenComplete(() {
      state.gridKey.currentState?.mutationInterface.tick(data.length);
      state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);
    });
  }

  SelectionGlue<J> _generateGlue<J extends Cell>() {
    return GlueProvider.generateOf<CompactMangaDataBase, J>(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: GridSkeleton<CompactMangaDataBase>(
        state,
        (context) => GridFrame<CompactMangaDataBase>(
          key: state.gridKey,
          overrideFab: FloatingActionButton.extended(
            onPressed: () {
              SearchAnimePage.launchMangaApi(
                context,
                widget.api,
                search: "",
                viewInsets: widget.viewInsets,
                generateGlue: _generateGlue,
              );
            },
            label: Text("Search"),
            icon: const Icon(Icons.search),
          ),
          getCell: (i) => data[i],
          initalScrollPosition: 0,
          scaffoldKey: state.scaffoldKey,
          systemNavigationInsets: widget.viewInsets,
          hasReachedEnd: () => true,
          overrideOnPress: (context, cell) {
            inInner = true;

            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (context) {
                return MangaInfoPage(
                  id: MangaStringId(cell.mangaId),
                  api: widget.api,
                );
              },
            )).then((value) {
              _procReload();
            });
          },
          selectionGlue: GlueProvider.of(context),
          mainFocus: state.mainFocus,
          refresh: refresh,
          description: GridDescription(
            const [],
            ignoreEmptyWidgetOnNoContent: true,
            ignoreSwipeSelectGesture: true,
            showAppBar: false,
            keybindsDescription: "Read tab",
            layout: _ReadingLayout(
              startReading: _startReading,
              gridSeed: state.gridSeed,
            ),
          ),
        ),
        canPop: true,
      ),
    );
  }
}

class _ReadingLayout implements GridLayouter<CompactMangaDataBase> {
  final void Function(int idx) startReading;
  final int gridSeed;

  const _ReadingLayout({
    required this.startReading,
    required this.gridSeed,
  });

  @override
  List<Widget> call(
      BuildContext context, GridFrameState<CompactMangaDataBase> state) {
    void onPressed(CompactMangaDataBase e, int idx) {
      state.onPressed(context, e, idx);
    }

    void onLongPressed(CompactMangaDataBase e, int idx) {
      startReading(idx);
    }

    return [
      SliverToBoxAdapter(
        child: SegmentLabel(
          "Reading", // TODO: change
          hidePinnedIcon: true,
          onPress: null,
          sticky: false,
          overridePinnedIcon: TextButton(
            onPressed: state.mutationInterface.cellCount == 0
                ? null
                : () => startReading(0),
            child: const Text("Read last"), // TODO: change
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
        SliverToBoxAdapter(
          child: SizedBox(
            height: (MediaQuery.sizeOf(context).shortestSide / 3),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.mutationInterface.cellCount,
              itemBuilder: (context, index) {
                final cell = state.mutationInterface.getCell(index);

                return SizedBox(
                  width: (MediaQuery.sizeOf(context).shortestSide / 3) *
                      GridAspectRatio.oneTwo.value,
                  child: ImportantCard(
                    cell: cell,
                    idx: index,
                    onLongPressed: onLongPressed,
                    onPressed: onPressed,
                  ),
                );
              },
            ),
          ),
        ),
      const SliverToBoxAdapter(
        child: SegmentLabel(
          "Pinned", // TODO: change
          hidePinnedIcon: false,
          onPress: null,
          sticky: false,
        ),
      ),
      _PinnedMangaWidget(
        controller: state.controller,
        onPress: (context, cell) => state.onPressed(context, cell, 0),
        glue:
            GlueProvider.generateOf<CompactMangaDataBase, PinnedManga>(context),
      )
    ];
  }

  @override
  GridColumn get columns => GridColumn.three;

  @override
  bool get isList => false;
}

class _PinnedMangaWidget extends StatefulWidget {
  final SelectionGlue<PinnedManga> glue;
  final ScrollController controller;
  final void Function(BuildContext context, CompactMangaDataBase cell) onPress;

  const _PinnedMangaWidget({
    super.key,
    required this.glue,
    required this.controller,
    required this.onPress,
  });

  @override
  State<_PinnedMangaWidget> createState() => _PinnedMangaWidgetState();
}

class _PinnedMangaWidgetState extends State<_PinnedMangaWidget> {
  late final StreamSubscription<void> watcher;
  final data = PinnedManga.getAll(-1);

  late final GridMutationInterface<PinnedManga> mutationInterface =
      _DummyMutationInterface(data);
  late final GridSelection<PinnedManga> selection = GridSelection(
    setState,
    const [],
    widget.glue,
    () => widget.controller,
    noAppBar: true,
    ignoreSwipe: true,
  );

  @override
  void initState() {
    super.initState();

    watcher = PinnedManga.watch((_) {
      data.clear();
      data.addAll(PinnedManga.getAll(-1));

      mutationInterface.tick(data.length);
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? const SliverToBoxAdapter(
            child: EmptyWidget(gridSeed: 0),
          )
        : GridLayouts.grid<PinnedManga>(
            context,
            mutationInterface,
            selection,
            GridColumn.three.number,
            false,
            (context, cell, idx, {required hideAlias, required tightMode}) =>
                GridCell(
              cell: cell,
              indx: idx,
              onPressed: (context) {
                widget.onPress(context, cell);
              },
              tight: tightMode,
              download: null,
              isList: false,
              hidealias: hideAlias,
            ),
            hideAlias: false,
            tightMode: false,
            systemNavigationInsets: 0,
            aspectRatio: GridAspectRatio.one.value,
          );
  }
}

class _DummyMutationInterface implements GridMutationInterface<PinnedManga> {
  _DummyMutationInterface(this.data) : cellCount = data.length;

  final List<PinnedManga> data;

  @override
  int cellCount = 0;

  @override
  PinnedManga getCell(int i) {
    return data[i];
  }

  @override
  bool get isRefreshing => false;

  @override
  bool get mutated => false;

  @override
  Future onRefresh() {
    return Future.value();
  }

  @override
  void restore() {}

  @override
  void setIsRefreshing(bool isRefreshing) {}

  @override
  void setSource(int cellCount, PinnedManga Function(int i) getCell) {}

  @override
  void tick(int i) {
    cellCount = i;
  }

  @override
  void unselectAll() {}
}
