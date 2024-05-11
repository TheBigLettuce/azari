// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/manga/manga_dex.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/anime/search/search_anime.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class MangaPage extends StatefulWidget {
  const MangaPage({
    super.key,
    required this.procPop,
    this.wrapGridPage = false,
    required this.db,
  });

  final void Function(bool) procPop;
  final bool wrapGridPage;

  final DbConn db;

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  SavedMangaChaptersService get savedChapters => widget.db.savedMangaChapters;
  ReadMangaChaptersService get readChapters => widget.db.readMangaChapters;
  CompactMangaDataService get compactManga => widget.db.compactManga;
  PinnedMangaService get pinnedManga => widget.db.pinnedManga;

  late final StreamSubscription<void> watcher;

  final data = <CompactMangaData>[];
  late final state = GridSkeletonRefreshingState<CompactMangaData>(
    clearRefresh: AsyncGridRefresh(
      refresh,
      pullToRefresh: false,
    ),
  );

  final dio = Dio();
  late final api = MangaDex(dio);

  final GlobalKey<_PinnedMangaWidgetState> _pinnedKey = GlobalKey();

  bool dirty = false;

  bool inInner = false;

  @override
  void initState() {
    super.initState();

    watcher = readChapters.watch((_) {
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

    dio.close();

    super.dispose();
  }

  Future<int> refresh() async {
    data.clear();

    final l = readChapters.lastRead(50);
    for (final e in l) {
      final d = compactManga.get(e.siteMangaId, api.site);
      if (d != null) {
        data.add(d);
      }
    }

    return data.length;
  }

  void _startReading(int i) {
    final c = readChapters.firstForId(data[i].mangaId);
    assert(c != null);
    if (c == null) {
      return;
    }

    final e = data[i];

    inInner = true;

    readChapters
        .launchReader(
      context,
      ReaderData(
        api: api,
        chapterNumber: c.chapterNumber,
        chapterName: c.chapterName,
        mangaId: MangaStringId(e.mangaId),
        mangaTitle: e.title,
        chapterId: c.chapterId,
        nextChapterKey: GlobalKey(),
        prevChaterKey: GlobalKey(),
        reloadChapters: () {},
        onNextPage: (p, cell) {},
      ),
      addNextChapterButton: true,
    )
        .then((value) {
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
    final mutation = state.gridKey.currentState?.mutation;

    mutation?.cellCount = 0;
    mutation?.isRefreshing = true;
    refresh().whenComplete(() {
      mutation?.cellCount = data.length;
      mutation?.isRefreshing = false;
    });
  }

  void _setInner(bool s) {
    if (s) {
      inInner = true;
    } else {
      _procReload();
    }
  }

  PageDescription _buildPage(
    BuildContext context,
    GridFrameState<CompactMangaData> state,
    int i,
  ) {
    return PageDescription(
      slivers: [
        _PinnedMangaWidget(
          glue: GlueProvider.generateOf(context)(),
          controller: state.controller,
          db: pinnedManga,
        ),
      ],
    );
  }

  List<PageLabel> pages(BuildContext context) => [
        PageLabel(AppLocalizations.of(context)!.mangaReadingLabel),
        PageLabel(
          AppLocalizations.of(context)!.mangaPinnedLabel,
          count: pinnedManga.count,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final child = GridSkeleton<CompactMangaData>(
      state,
      (context) => GridFrame<CompactMangaData>(
        key: state.gridKey,
        layout: _ReadingLayout(
          startReading: _startReading,
          pinnedMangaKey: _pinnedKey,
        ),
        functionality: GridFunctionality(
          registerNotifiers: (child) {
            return MangaPageDataNotifier(
              client: dio,
              setInner: _setInner,
              child: child,
            );
          },
          selectionGlue: GlueProvider.generateOf(context)(),
          refreshingStatus: state.refreshingStatus,
          fab: OverrideGridFab(
            (scrollController) {
              return ReadingFab(
                api: api,
                controller: scrollController,
              );
            },
          ),
        ),
        getCell: (i) => data[i],
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: const [],
          pages: PageSwitcherLabel(
            pages(context),
            _buildPage,
          ),
          ignoreEmptyWidgetOnNoContent: true,
          showAppBar: false,
          keybindsDescription: AppLocalizations.of(context)!.mangaPage,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
      secondarySelectionHide: () {
        _pinnedKey.currentState?.state.gridKey.currentState?.selection.reset();
      },
      onPop: widget.procPop,
    );

    return SafeArea(
      bottom: false,
      child: widget.wrapGridPage
          ? WrapGridPage(
              child: child,
            )
          : child,
    );
  }
}

class ReadingFab extends StatefulWidget {
  const ReadingFab({
    super.key,
    required this.api,
    required this.controller,
  });
  final MangaAPI api;
  final ScrollController controller;

  @override
  State<ReadingFab> createState() => _ReadingFabState();
}

class _ReadingFabState extends State<ReadingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;

  bool extended = true;

  void _listener() {
    if (widget.controller.offset == 0 && !extended) {
      animation.reverse().then(
            (value) => setState(() {
              extended = true;
            }),
          );
    } else if (widget.controller.offset > 0 && extended) {
      animation.forward().then(
            (value) => setState(() {
              extended = false;
            }),
          );
    }
  }

  @override
  void initState() {
    super.initState();

    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final pos = widget.controller.positions.toList();
      if (pos.isEmpty) {
        return;
      }

      pos.first.addListener(_listener);
    });
  }

  @override
  void dispose() {
    animation.dispose();

    final pos = widget.controller.positions.toList();
    if (pos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        pos.first.removeListener(_listener);
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      isExtended: extended,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ).lerpTo(
        const CircleBorder(),
        Easing.standard.transform(animation.value),
      ),
      onPressed: () {
        SearchAnimePage.launchMangaApi(
          context,
          widget.api,
          search: "",
          generateGlue: GlueProvider.generateOf(context),
        );
      },
      label: Text(AppLocalizations.of(context)!.searchHint),
      icon: const Icon(Icons.search),
    );
  }
}

class _ReadingLayout
    implements GridLayouter<CompactMangaData>, GridLayoutBehaviour {
  const _ReadingLayout({
    required this.startReading,
    required this.pinnedMangaKey,
  });

  final void Function(int idx) startReading;
  final GlobalKey<_PinnedMangaWidgetState> pinnedMangaKey;

  static GridSettingsBase _defaultSettings() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.zeroSeven,
        columns: GridColumn.three,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  GridSettingsBase Function() get defaultSettings => _defaultSettings;

  @override
  GridLayouter<T> makeFor<T extends CellBase>(GridSettingsBase settings) {
    return this as GridLayouter<T>;
  }

  void onLongPressed(CompactMangaData e, int idx) {
    startReading(idx);
  }

  @override
  List<Widget> call(
    BuildContext context,
    GridSettingsBase settings,
    GridFrameState<CompactMangaData> state,
  ) {
    return [
      if (state.mutation.cellCount == 0)
        SliverToBoxAdapter(
          child: EmptyWidget(
            gridSeed: state.widget.description.gridSeed,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: settings.columns.number,
              childAspectRatio: settings.aspectRatio.value,
            ),
            itemCount: state.mutation.cellCount,
            itemBuilder: (context, index) {
              final cell = state.widget.getCell(index);

              return MangaReadingCard<CompactMangaData>(
                cell: cell,
                idx: index,
                onLongPressed: onLongPressed,
                onPressed: (cell, idx) {
                  cell.onPress(
                    context,
                    state.widget.functionality,
                    cell,
                    idx,
                  );
                },
              );
            },
          ),
        ),
    ];
  }

  @override
  bool get isList => false;
}

class _PinnedMangaWidget extends StatefulWidget
    with DbConnHandle<PinnedMangaService> {
  const _PinnedMangaWidget({
    required this.glue,
    required this.controller,
    required this.db,
  });

  final SelectionGlue glue;
  final ScrollController controller;

  @override
  final PinnedMangaService db;

  @override
  State<_PinnedMangaWidget> createState() => _PinnedMangaWidgetState();
}

class _PinnedMangaWidgetState extends State<_PinnedMangaWidget>
    with PinnedMangaDbScope<_PinnedMangaWidget> {
  late final StreamSubscription<void> watcher;
  final List<PinnedManga> data = [];

  late final state = GridSkeletonRefreshingState<PinnedManga>(
    clearRefresh: SynchronousGridRefresh(() => data.length),
  );

  @override
  void initState() {
    super.initState();

    data.addAll(getAll(-1));

    watcher = watch((_) {
      data.clear();
      data.addAll(getAll(-1));

      state.refreshingStatus.mutation.cellCount = data.length;
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 14, right: 14),
      sliver: GridFrame<PinnedManga>(
        key: state.gridKey,
        overrideController: widget.controller,
        getCell: (i) => data[data.length - 1 - i],
        functionality: GridFunctionality(
          selectionGlue: widget.glue,
          refreshingStatus: state.refreshingStatus,
        ),
        layout: GridSettingsLayoutBehaviour(
          () => const GridSettingsBase(
            columns: GridColumn.three,
            aspectRatio: GridAspectRatio.one,
            layoutType: GridLayoutType.grid,
            hideName: false,
          ),
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: [
            GridAction(
              Icons.push_pin_rounded,
              (selected) {
                final deleted = deleteAll(
                  selected
                      .map((e) => (MangaStringId(e.mangaId), e.site))
                      .toList(),
                );

                if (deleted.isEmpty) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.mangaUnpinned),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.undoLabel,
                      onPressed: () => reAdd(deleted),
                    ),
                  ),
                );
              },
              true,
            ),
          ],
          gridSeed: state.gridSeed,
          asSliver: true,
          showAppBar: false,
          keybindsDescription: "Pinned manga",
        ),
      ),
    );
  }
}

class MangaPageDataNotifier extends InheritedWidget {
  const MangaPageDataNotifier({
    super.key,
    required this.client,
    required this.setInner,
    required super.child,
  });

  final Dio client;
  final void Function(bool) setInner;

  static (Dio, void Function(bool)) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<MangaPageDataNotifier>();

    return (widget!.client, widget.setInner);
  }

  @override
  bool updateShouldNotify(MangaPageDataNotifier oldWidget) =>
      client != oldWidget.client || setInner != oldWidget.setInner;
}
