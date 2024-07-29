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
    required this.api,
    required this.db,
    required this.entry,
  });

  final AnimeAPI api;
  final DiscoverPagingEntry entry;

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

class DiscoverPagingEntry implements PagingEntry {
  DiscoverPagingEntry(this.api);

  factory DiscoverPagingEntry.prototype(AnimeAPI api) =>
      DiscoverPagingEntry(api);

  final AnimeAPI api;
  late final source = GenericListSource<AnimeSearchEntry>(
    () {
      page = 0;

      return api.search(
        searchText,
        page,
        genreId,
        mode,
      );
    },
    next: () => api
        .search(
      searchText,
      page + 1,
      genreId,
      mode,
    )
        .then((l) {
      page += 1;

      return l;
    }),
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
    source.destroy();
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

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.zeroSeven,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  final GridSkeletonState<AnimeSearchEntry> state =
      GridSkeletonState<AnimeSearchEntry>();

  GenericListSource<AnimeSearchEntry> get source => pagingState.source;

  DiscoverPagingEntry get pagingState => widget.entry;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  // void openSearchSheet() {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     useRootNavigator: true,
  //     showDragHandle: true,
  //     builder: (context) {
  //       return SafeArea(
  //         child: SearchOptions<int, AnimeGenre>(
  //           info: widget.api.site.name,
  //           setCurrentGenre: (g) {
  //             pagingState.genreId = g;

  //             source.clearRefresh();
  //           },
  //           initalGenreId: pagingState.genreId,
  //           header: _SearchBar(
  //             pagingState: pagingState,
  //             gridKey: state.gridKey,
  //           ),
  //           genreFuture: () {
  //             if (pagingState.future != null) {
  //               return pagingState.future!;
  //             }

  //             pagingState.future = widget.api.genres(AnimeSafeMode.safe);

  //             return pagingState.future!;
  //           },
  //           idFromGenre: (genre) => (genre.id, genre.title),
  //         ),
  //       );
  //     },
  //   );
  // }

  void search(String string) {
    pagingState.searchText = string;
    source.clearRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        child: GridFrame<AnimeSearchEntry>(
          key: state.gridKey,
          slivers: [
            CurrentGridSettingsLayout<AnimeSearchEntry>(
              source: source.backingStorage,
              progress: source.progress,
              gridSeed: state.gridSeed,
            ),
          ],
          initalScrollPosition: pagingState.offset,
          functionality: GridFunctionality(
            updateScrollPosition: pagingState.setOffset,
            selectionGlue: GlueProvider.generateOf(context)(),
            source: source,
          ),
          description: GridDescription(
            animationsOnSourceWatch: false,
            showAppBar: false,
            actions:
                DiscoverTab.actions(savedAnimeEntries, watchedAnimeEntries),
            keybindsDescription: AppLocalizations.of(context)!.discoverTab,
            gridSeed: state.gridSeed,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.pagingState,
    required this.gridKey,
  });

  final DiscoverPagingEntry pagingState;
  final GlobalKey<GridFrameState> gridKey;

  @override
  State<_SearchBar> createState() => __SearchBarState();
}

class __SearchBarState extends State<_SearchBar> {
  late final TextEditingController controller;

  DiscoverPagingEntry get pagingState => widget.pagingState;
  GenericListSource<AnimeSearchEntry> get source => pagingState.source;

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
    if (gridState == null || source.progress.inRefreshing) {
      return;
    }

    if (value == pagingState.searchText) {
      return;
    }

    pagingState.searchText = value;

    source.clearRefresh();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      onSubmitted: (value) => _search(context, value),
      controller: controller,
      elevation: const WidgetStatePropertyAll(0),
      hintText: AppLocalizations.of(context)!.searchHint,
      leading: const Icon(Icons.search_rounded),
      trailing: [
        StatefulBuilder(
          builder: (context, setState) {
            return SafetyButton(
              mode: pagingState.mode,
              set: (m) {
                pagingState.mode = m;

                source.clearRefresh();

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
