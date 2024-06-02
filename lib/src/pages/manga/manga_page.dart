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
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/manga/manga_dex.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/anime/search/search_anime.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
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

  late final state = GridSkeletonState<CompactMangaData>();

  final dio = Dio();
  late final api = MangaDex(dio);
  late final source = GenericListSource<CompactMangaData>(() {
    final l = readChapters
        .lastRead(50)
        .map((e) => compactManga.get(e.siteMangaId, api.site))
        .where((e) => e != null)
        .cast<CompactMangaData>()
        .toList();

    return Future.value(l);
  });

  bool dirty = false;

  bool inInner = false;

  final gridSettings = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.zeroSeven,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    watcher = readChapters.watch((_) {
      if (inInner) {
        dirty = true;
      } else {
        source.clearRefresh();
      }
    });
  }

  @override
  void dispose() {
    source.destroy();
    watcher.cancel();

    dio.close();

    super.dispose();
  }

  void _startReading(int i) {
    final c = readChapters.firstForId(source.backingStorage[i].mangaId);
    assert(c != null);
    if (c == null) {
      return;
    }

    final e = source.forIdxUnsafe(i);

    inInner = true;

    ReadMangaChaptersService.launchReader(
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
    ).then((value) {
      _procReload();
    });
  }

  void _procReload() {
    inInner = false;

    if (dirty) {
      source.clearRefresh();
    }
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

  List<PageLabel> pages(BuildContext context, AppLocalizations l8n) => [
        PageLabel(l8n.mangaReadingLabel),
        PageLabel(
          l8n.mangaPinnedLabel,
          count: pinnedManga.count,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    final child = GridPopScope(
      searchTextController: null,
      filter: null,
      searchFocus: null,
      rootNavigatorPop: widget.procPop,
      child: GridFrame<CompactMangaData>(
        key: state.gridKey,
        slivers: [
          _ReadingLayout(
            source: source.backingStorage,
            startReading: _startReading,
            gridSeed: state.gridSeed,
          ),
        ],
        functionality: GridFunctionality(
          registerNotifiers: (child) {
            return MangaPageDataNotifier(
              client: dio,
              setInner: _setInner,
              child: child,
            );
          },
          selectionGlue: GlueProvider.generateOf(context)(),
          source: source,
          fab: OverrideGridFab(
            (scrollController) {
              return ReadingFab(
                api: api,
                controller: scrollController,
              );
            },
          ),
        ),
        description: GridDescription(
          actions: const [],
          pages: PageSwitcherLabel(
            pages(context, l8n),
            _buildPage,
          ),
          showAppBar: false,
          keybindsDescription: l8n.mangaPage,
          gridSeed: state.gridSeed,
        ),
      ),
    );

    return GridConfiguration(
      watch: gridSettings.watch,
      child: SafeArea(
        bottom: false,
        child: widget.wrapGridPage
            ? WrapGridPage(
                child: child,
              )
            : child,
      ),
    );
  }
}

class _ReadingLayout extends StatefulWidget {
  const _ReadingLayout({
    // super.key,
    required this.source,
    required this.startReading,
    required this.gridSeed,
  });

  final SourceStorage<int, CompactMangaData> source;
  final void Function(int i) startReading;

  final int gridSeed;

  @override
  State<_ReadingLayout> createState() => __ReadingLayoutState();
}

class __ReadingLayoutState extends State<_ReadingLayout> {
  SourceStorage<int, CompactMangaData> get source => widget.source;

  late final StreamSubscription<void> _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = source.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (source.count == 0) {
      return SliverToBoxAdapter(
        child: EmptyWidget(
          gridSeed: widget.gridSeed,
        ),
      );
    }

    final config = GridConfiguration.of(context);
    final getCell = CellProvider.of<CompactMangaData>(context);
    final extras = GridExtrasNotifier.of<CompactMangaData>(context);

    return SliverPadding(
      padding: const EdgeInsets.only(left: 14, right: 14),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.columns.number,
          childAspectRatio: config.aspectRatio.value,
        ),
        itemCount: source.count,
        itemBuilder: (context, idx) {
          final cell = getCell(idx);

          return MangaReadingCard<CompactMangaData>(
            cell: cell,
            idx: idx,
            onLongPressed: (_, i) => widget.startReading(i),
            onPressed: (cell, idx) {
              cell.onPress(
                context,
                extras.functionality,
                cell,
                idx,
              );
            },
            db: DatabaseConnectionNotifier.of(context).readMangaChapters,
          );
        },
      ),
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
        borderRadius: BorderRadius.all(Radius.circular(16)),
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
  late final source =
      GenericListSource<PinnedManga>(() => Future.value(getAll(-1)));

  late final state = GridSkeletonState<PinnedManga>();

  final gridSettings = GridSettingsData.noPersist(
    columns: GridColumn.three,
    aspectRatio: GridAspectRatio.one,
    layoutType: GridLayoutType.grid,
    hideName: false,
  );

  @override
  void initState() {
    super.initState();

    watcher = watch((_) {
      source.clearRefresh();
    });
  }

  @override
  void dispose() {
    source.destroy();
    gridSettings.cancel();
    watcher.cancel();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return GridConfiguration(
      sliver: true,
      watch: gridSettings.watch,
      child: SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: GridFrame<PinnedManga>(
          key: state.gridKey,
          slivers: [
            GridLayout<PinnedManga>(
              source: source.backingStorage,
              progress: source.progress,
            ),
          ],
          overrideController: widget.controller,
          functionality: GridFunctionality(
            selectionGlue: widget.glue,
            source: source,
          ),
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
                      content: Text(l8n.mangaUnpinned),
                      action: SnackBarAction(
                        label: l8n.undoLabel,
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
