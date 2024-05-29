// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../anime.dart";

class _WatchingTab extends StatefulWidget {
  const _WatchingTab({
    required super.key,
    required this.procPop,
    required this.onDispose,
    required this.db,
  });

  final void Function() onDispose;
  final void Function(bool) procPop;

  final DbConn db;

  @override
  State<_WatchingTab> createState() => __WatchingTabState();
}

class __WatchingTabState extends State<_WatchingTab> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  late final originalSourceBacklog = GenericListSource<SavedAnimeEntryData>(
    () => Future.value(savedAnimeEntries.backlogAll),
  );
  late final ChainedFilterResourceSource<int, SavedAnimeEntryData>
      filterBacklog;

  late final originalSourceCurrent = GenericListSource<SavedAnimeEntryData>(
    () => Future.value(savedAnimeEntries.currentlyWatchingAll),
  );
  late final ChainedFilterResourceSource<int, SavedAnimeEntryData>
      filterCurrent;

  late final StreamSubscription<void> watcher;

  late final state = GridSkeletonState<SavedAnimeEntryData>();

  final gridSeed = math.Random().nextInt(948512342);
  final GlobalKey<__CurrentlyWatchingState> watchingKey = GlobalKey();

  bool upward = MiscSettingsService.db().current.animeWatchingOrderReversed;
  bool right = false;
  String _filteringValue = "";

  final gridSettings = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  final scrollController = ScrollController();

  void doFilter(String value) {
    _filteringValue = value.toLowerCase().trim();

    filterBacklog.clearRefresh();
    filterCurrent.clearRefresh();
  }

  @override
  void initState() {
    super.initState();

    filterBacklog = ChainedFilterResourceSource.basic(
      originalSourceBacklog,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    filterCurrent = ChainedFilterResourceSource.basic(
      originalSourceCurrent,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    watcher = savedAnimeEntries.watchAll((_) {
      originalSourceBacklog.clearRefresh();
      originalSourceCurrent.clearRefresh();
    });
  }

  @override
  void dispose() {
    gridSettings.cancel();
    originalSourceBacklog.destroy();
    originalSourceCurrent.destroy();
    filterBacklog.destroy();
    filterCurrent.destroy();

    watcher.cancel();

    state.dispose();

    scrollController.dispose();

    widget.onDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        searchFocus: null,
        rootNavigatorPop: widget.procPop,
        child: GridFrame<SavedAnimeEntryData>(
          key: state.gridKey,
          overrideController: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(left: 14, right: 14),
              sliver: SliverToBoxAdapter(
                child: MediumSegmentLabel(
                  AppLocalizations.of(context)!.watchingLabel,
                  trailingWidget: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      right = !right;
                    }),
                    icon: (right
                            ? const Icon(Icons.arrow_back)
                            : const Icon(Icons.arrow_forward))
                        .animate(key: ValueKey(right))
                        .fadeIn(),
                  ),
                ),
              ),
            ),
            if (filterCurrent.backingStorage.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(left: 14, right: 14),
                sliver: _CurrentlyWatching(
                  key: watchingKey,
                  filter: filterCurrent,
                  watchingRight: right,
                  controller: scrollController,
                  glue: GlueProvider.generateOf(context)(),
                  db: widget.db,
                ),
              )
            else
              SliverToBoxAdapter(
                child: EmptyWidget(
                  gridSeed: gridSeed,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 14, right: 14),
              sliver: SliverToBoxAdapter(
                child: MediumSegmentLabel(
                  AppLocalizations.of(context)!.backlogLabel,
                  trailingWidget: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      upward = !upward;

                      MiscSettingsService.db()
                          .current
                          .copy(animeWatchingOrderReversed: upward);

                      setState(() {});
                    },
                    icon: (upward
                            ? const Icon(Icons.arrow_upward)
                            : const Icon(Icons.arrow_downward))
                        .animate(key: ValueKey(upward))
                        .fadeIn(),
                  ),
                ),
              ),
            ),
            if (filterBacklog.count > 0)
              SliverPadding(
                padding: const EdgeInsets.only(left: 14, right: 14),
                sliver: GridLayout<SavedAnimeEntryData>(
                  source: filterBacklog.backingStorage,
                  progress: filterBacklog.progress,
                ),
              )
            else
              SliverToBoxAdapter(
                child: EmptyWidget(
                  gridSeed: gridSeed + 1,
                ),
              ),
          ],
          functionality: GridFunctionality(
            selectionGlue: GlueProvider.generateOf(context)(),
            source: filterBacklog,
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            actions: [
              GridAction(
                Icons.play_arrow_rounded,
                (selected) {
                  final entry = selected.first;

                  if (!entry.inBacklog) {
                    entry.copy(inBacklog: true).save();
                    return;
                  }

                  // TODO: this
                  // if (!entry.setCurrentlyWatching()) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content:
                  //           Text(AppLocalizations.of(context)!.cantWatchThree),
                  //     ),
                  //   );
                  // }
                },
                true,
                showOnlyWhenSingle: true,
              ),
              GridAction(
                Icons.delete_rounded,
                (selected) {
                  savedAnimeEntries.deleteAll(selected.toIds);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.deletedFromBacklog),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undoLabel,
                        onPressed: () {
                          savedAnimeEntries.reAdd(selected);
                        },
                      ),
                    ),
                  );
                },
                true,
              ),
              GridAction(
                Icons.check_rounded,
                (s) => watchedAnimeEntries.moveAll(s, savedAnimeEntries),
                true,
              ),
            ],
            keybindsDescription: AppLocalizations.of(context)!.watchingTab,
            showAppBar: false,
            // ignoreEmptyWidgetOnNoContent: true,
            gridSeed: state.gridSeed,
          ),
        ),
      ),
    );
  }
}

// GridSkeleton<AnimeEntryData>(
//       state,
//       (context) => ,
//       canPop: false,
//       secondarySelectionHide: () {
//         watchingKey.currentState?.selection.reset();
//       },
//       onPop: widget.procPop,
//     )

class _CurrentlyWatching extends StatefulWidget {
  const _CurrentlyWatching({
    super.key,
    required this.filter,
    required this.controller,
    required this.watchingRight,
    required this.glue,
    required this.db,
  });

  final bool watchingRight;
  final ChainedFilterResourceSource<int, SavedAnimeEntryData> filter;
  final ScrollController controller;
  final SelectionGlue glue;

  final DbConn db;

  @override
  State<_CurrentlyWatching> createState() => __CurrentlyWatchingState();
}

class __CurrentlyWatchingState extends State<_CurrentlyWatching> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  ChainedFilterResourceSource<int, SavedAnimeEntryData> get filter =>
      widget.filter;

  late final selection = GridSelection<SavedAnimeEntryData>(
    [
      GridAction(
        Icons.play_arrow_rounded,
        (selected) {
          savedAnimeEntries.unsetIsWatchingAll(selected);
        },
        true,
      ),
      GridAction(
        Icons.delete_rounded,
        (selected) {
          savedAnimeEntries.deleteAll(selected.toIds);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deletedFromBacklog),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.undoLabel,
                onPressed: () {
                  savedAnimeEntries.reAdd(selected);
                },
              ),
            ),
          );
        },
        true,
      ),
      GridAction(
        Icons.check_rounded,
        (selected) {
          watchedAnimeEntries.moveAll(selected, widget.db.savedAnimeEntries);
        },
        true,
      ),
    ],
    widget.glue,
    () => widget.controller,
    source: filter.backingStorage,
    noAppBar: true,
    // ignoreSwipe: true,
  );

  void onPressed(SavedAnimeEntryData e, int _) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return AnimeInfoPage(
            entry: e,
            id: e.id,
            apiFactory: e.site.api,
            db: widget.db,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CellProvider(
      getCell: filter.forIdxUnsafe,
      child: Builder(
        builder: (context) {
          return SliverGrid.count(
            crossAxisCount: 3,
            children: widget.watchingRight
                ? filter.backingStorage.reversed.indexed
                    .map(
                      (e) => ImportantCard(
                        cell: e.$2,
                        idx: e.$1,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn(),
                    )
                    .toList()
                : filter.backingStorage.indexed
                    .map(
                      (e) => ImportantCard(
                        cell: e.$2,
                        idx: e.$1,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn(),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}

class MangaReadingCard<T extends CompactMangaData> extends StatelessWidget {
  const MangaReadingCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
    required this.db,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  final ReadMangaChaptersService db;

  void _onLongPressed() => onLongPressed!(cell, idx);

  void _onPressed() => onPressed!(cell, idx);

  @override
  Widget build(BuildContext context) {
    final lastRead = db.firstForId(cell.mangaId);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    return BaseCard(
      onLongPressed: onLongPressed == null ? null : _onLongPressed,
      subtitle: Text(
        cell.alias(false),
        maxLines: 2,
      ),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onPressed: onPressed == null ? null : _onPressed,
      width: null,
      height: null,
      footer: lastRead != null
          ? RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  if (lastRead.chapterName.isNotEmpty)
                    TextSpan(
                      text: "${lastRead.chapterName} ",
                      style: textTheme,
                    ),
                  TextSpan(
                    text:
                        "${lastRead.chapterNumber} - ${lastRead.chapterProgress}\n",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!
                        .date(lastRead.lastUpdated),
                    style: textTheme?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class ImportantCard<T extends CellBase> extends StatelessWidget {
  const ImportantCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return UnsizedCard(
      leanToLeft: false,
      subtitle: Text(cell.alias(false)),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onLongPressed: onLongPressed == null
          ? null
          : () {
              onLongPressed!(cell, idx);
            },
      onPressed: onPressed == null
          ? null
          : () {
              onPressed!(cell, idx);
            },
    );
  }
}
