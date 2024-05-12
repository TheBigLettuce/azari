// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../anime.dart";

class DiscoverExtra {
  String searchText = "";
  List<AnimeSearchEntry> entries = [];
  int? genreId;
  AnimeSafeMode mode = AnimeSafeMode.safe;
  Future<Map<int, AnimeGenre>>? future;
}

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({
    super.key,
    required this.procPop,
    required this.api,
    required this.db,
    required this.registry,
  });

  final void Function(bool) procPop;
  final AnimeAPI api;
  final PagingStateRegistry registry;

  final DbConn db;

  static List<GridAction<AnimeSearchEntry>> actions(
    SavedAnimeEntriesService savedAnimeEntries,
    WatchedAnimeEntryService watchedAnimeEntries,
  ) =>
      [
        GridAction(
          Icons.add,
          (selected) {
            final toDelete = <AnimeSearchEntry>[];
            final toAdd = <AnimeSearchEntry>[];

            for (final e in selected) {
              final entry = savedAnimeEntries.maybeGet(e.id, e.site);
              if (entry == null) {
                toAdd.add(e);
              } else if (entry.inBacklog) {
                toDelete.add(e);
              }
            }

            savedAnimeEntries.addAll(toAdd, watchedAnimeEntries);
            savedAnimeEntries.deleteAll(toDelete.toIds);
          },
          true,
        ),
      ];

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverPagingEntry implements PagingEntry {
  _DiscoverPagingEntry(this.api);

  factory _DiscoverPagingEntry.prototype(AnimeAPI api) =>
      _DiscoverPagingEntry(api);

  final entries = <AnimeSearchEntry>[];
  final AnimeAPI api;

  late final GridRefreshingStatus<AnimeSearchEntry> refreshingStatus =
      GridRefreshingStatus(
    0,
    () => false,
    clearRefresh: AsyncGridRefresh(() async {
      entries.clear();
      page = 0;
      reachedEnd = false;

      final p = await api.search(
        searchText,
        page,
        genreId,
        mode,
      );

      entries.addAll(p);

      return entries.length;
    }),
    next: () async {
      final p = await api.search(
        searchText,
        page + 1,
        genreId,
        mode,
      );

      page += 1;

      if (p.isEmpty) {
        reachedEnd = true;
      }
      entries.addAll(p);

      return entries.length;
    },
  );

  Future<Map<int, AnimeGenre>>? future;

  int? genreId;

  String searchText = "";

  AnimeSafeMode mode = AnimeSafeMode.safe;

  @override
  int page = 0;

  @override
  bool reachedEnd = false;

  @override
  void dispose() {
    refreshingStatus.dispose();
  }

  @override
  double offset = 0;

  @override
  void setOffset(double o) => offset = o;

  @override
  void updateTime() {}
}

class _DiscoverTabState extends State<DiscoverTab> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.animeDiscovery;

  final GridSkeletonState<AnimeSearchEntry> state =
      GridSkeletonState<AnimeSearchEntry>();

  List<AnimeSearchEntry> get entries => pagingState.entries;

  late final _DiscoverPagingEntry pagingState;

  @override
  void initState() {
    super.initState();

    pagingState = widget.registry.getOrRegister(
      "discover",
      () => _DiscoverPagingEntry.prototype(widget.api),
    );
  }

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  void openSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SearchOptions<int, AnimeGenre>(
            info: widget.api.site.name,
            setCurrentGenre: (g) {
              pagingState.genreId = g;

              pagingState.refreshingStatus.refresh();
            },
            initalGenreId: pagingState.genreId,
            header: _SearchBar(
              pagingState: pagingState,
              gridKey: state.gridKey,
            ),
            genreFuture: () {
              if (pagingState.future != null) {
                return pagingState.future!;
              }

              pagingState.future = widget.api.genres(AnimeSafeMode.safe);

              return pagingState.future!;
            },
            idFromGenre: (genre) => (genre.id, genre.title),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridSkeleton<AnimeSearchEntry>(
        state,
        (context) => GridFrame<AnimeSearchEntry>(
          key: state.gridKey,
          slivers: [
            CurrentGridSettingsLayout(
              mutation: pagingState.refreshingStatus.mutation,
              gridSeed: state.gridSeed,
            )
          ],
          getCell: (i) => entries[i],
          initalScrollPosition: pagingState.offset,
          functionality: GridFunctionality(
            updateScrollPosition: pagingState.setOffset,
            selectionGlue: GlueProvider.generateOf(context)(),
            refreshingStatus: pagingState.refreshingStatus,
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            actions:
                DiscoverTab.actions(savedAnimeEntries, watchedAnimeEntries),
            showAppBar: false,
            keybindsDescription: AppLocalizations.of(context)!.discoverTab,
            gridSeed: state.gridSeed,
          ),
        ),
        canPop: false,
        onPop: widget.procPop,
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.pagingState,
    required this.gridKey,
  });

  final _DiscoverPagingEntry pagingState;
  final GlobalKey<GridFrameState> gridKey;

  @override
  State<_SearchBar> createState() => __SearchBarState();
}

class __SearchBarState extends State<_SearchBar> {
  late final TextEditingController controller;

  _DiscoverPagingEntry get pagingState => widget.pagingState;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: pagingState.searchText);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _search(BuildContext context, String value) {
    final gridState = widget.gridKey.currentState;
    if (gridState == null) {
      return;
    }

    if (value == pagingState.searchText) {
      return;
    }

    pagingState.searchText = value;
    gridState.refreshingStatus.updateProgress?.ignore();
    gridState.refreshingStatus.updateProgress = null;
    gridState.refreshingStatus.refresh();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      onSubmitted: (value) => _search(context, value),
      controller: controller,
      elevation: const MaterialStatePropertyAll(0),
      hintText: AppLocalizations.of(context)!.searchHint,
      leading: const Icon(Icons.search_rounded),
      trailing: [
        StatefulBuilder(
          builder: (context, setState) {
            return SafetyButton(
              mode: pagingState.mode,
              set: (m) {
                pagingState.mode = m;

                pagingState.refreshingStatus.refresh();

                setState(() {});
              },
            );
          },
        ),
        IconButton(
          onPressed: () => _search(context, ""),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
