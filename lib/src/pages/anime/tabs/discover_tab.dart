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
    required this.pagingContainer,
    required this.api,
  });
  final void Function(bool) procPop;
  final PagingContainer<AnimeSearchEntry, DiscoverExtra> pagingContainer;
  final AnimeAPI api;

  static List<GridAction<AnimeSearchEntry>> actions() => [
        GridAction(
          Icons.add,
          (selected) {
            final toDelete = <AnimeSearchEntry>[];
            final toAdd = <AnimeSearchEntry>[];

            for (final e in selected) {
              final entry = SavedAnimeEntry.maybeGet(e.id, e.site);
              if (entry == null) {
                toAdd.add(e);
              } else if (entry.inBacklog) {
                toDelete.add(e);
              }
            }

            SavedAnimeEntry.addAll(toAdd);
            SavedAnimeEntry.deleteAllIds(
              toDelete.map((e) => (e.id, e.site)).toList(),
            );
          },
          true,
        ),
      ];

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  late final StreamSubscription<GridSettingsData?> gridSettingsWatcher;
  late final GridSkeletonState<AnimeSearchEntry> state;

  GridSettingsData gridSettings = GridSettingsAnimeDiscovery.current;

  PagingContainer<AnimeSearchEntry, DiscoverExtra> get container =>
      widget.pagingContainer;
  List<AnimeSearchEntry> get entries => container.extra.entries;

  @override
  void initState() {
    super.initState();

    state = GridSkeletonRefreshingState<AnimeSearchEntry>(
      initalCellCount: entries.length,
      clearRefresh: AsyncGridRefresh(_refresh),
      next: _loadNext,
    );

    gridSettingsWatcher = GridSettingsAnimeDiscovery.watch((e) {
      gridSettings = e!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    state.dispose();
    gridSettingsWatcher.cancel();

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
              container.extra.genreId = g;

              state.gridKey.currentState?.refreshSequence();
            },
            initalGenreId: container.extra.genreId,
            header: _SearchBar(
              pagingContainer: container,
              gridKey: state.gridKey,
            ),
            genreFuture: () {
              if (container.extra.future != null) {
                return container.extra.future!;
              }

              container.extra.future = widget.api.genres(AnimeSafeMode.safe);

              return container.extra.future!;
            },
            idFromGenre: (genre) => (genre.id, genre.title),
          ),
        );
      },
    );
  }

  Future<int> _loadNext() async {
    final p = await widget.api.search(
      container.extra.searchText,
      container.page + 1,
      container.extra.genreId,
      container.extra.mode,
    );

    container.page += 1;

    if (p.isEmpty) {
      container.reachedEnd = true;
    }
    entries.addAll(p);

    return entries.length;
  }

  Future<int> _refresh() async {
    entries.clear();
    container.page = 0;
    container.reachedEnd = false;

    final p = await widget.api.search(
      container.extra.searchText,
      container.page,
      container.extra.genreId,
      container.extra.mode,
    );

    entries.addAll(p);

    return entries.length;
  }

  GridSettingsBase _settings() => GridSettingsBase(
        aspectRatio: GridAspectRatio.zeroSeven,
        columns: gridSettings.columns,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<AnimeSearchEntry>(
      state,
      (context) => GridFrame<AnimeSearchEntry>(
        key: state.gridKey,
        layout: GridSettingsLayoutBehaviour(_settings),
        getCell: (i) => entries[i],
        initalScrollPosition: widget.pagingContainer.scrollPos,
        functionality: GridFunctionality(
          updateScrollPosition: widget.pagingContainer.updateScrollPos,
          selectionGlue: GlueProvider.generateOf(context)(),
          refreshingStatus: widget.pagingContainer.refreshingStatus,
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: DiscoverTab.actions(),
          showAppBar: false,
          keybindsDescription: AppLocalizations.of(context)!.discoverTab,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
      onPop: widget.procPop,
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.pagingContainer,
    required this.gridKey,
  });
  final PagingContainer<AnimeSearchEntry, DiscoverExtra> pagingContainer;
  final GlobalKey<GridFrameState> gridKey;

  @override
  State<_SearchBar> createState() => __SearchBarState();
}

class __SearchBarState extends State<_SearchBar> {
  late final TextEditingController controller;

  PagingContainer<AnimeEntryData, DiscoverExtra> get container =>
      widget.pagingContainer;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: container.extra.searchText);
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

    if (value == container.extra.searchText) {
      return;
    }

    container.extra.searchText = value;
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
              mode: container.extra.mode,
              set: (m) {
                container.extra.mode = m;

                widget.gridKey.currentState?.refreshSequence();

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
