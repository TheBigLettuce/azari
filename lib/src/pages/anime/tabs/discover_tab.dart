// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class DiscoverExtra {
  String searchText = "";
  List<AnimeEntry> entries = [];
  int? genreId;
  AnimeSafeMode mode = AnimeSafeMode.safe;
  Future<Map<int, AnimeGenre>>? future;
}

class DiscoverTab extends StatefulWidget {
  final EdgeInsets viewInsets;
  final void Function(bool) procPop;
  final PagingContainer<AnimeEntry, DiscoverExtra> pagingContainer;
  final AnimeAPI api;

  static List<GridAction<AnimeEntry>> actions() => [
        GridAction(Icons.add, (selected) {
          final toDelete = <AnimeEntry>[];
          final toAdd = <AnimeEntry>[];

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
              toDelete.map((e) => (e.id, e.site)).toList());
        }, true),
      ];

  const DiscoverTab({
    super.key,
    required this.procPop,
    required this.pagingContainer,
    required this.api,
    required this.viewInsets,
  });

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  late final StreamSubscription<GridSettingsAnimeDiscovery?>
      gridSettingsWatcher;
  late final GridSkeletonState<AnimeEntry> state;

  GridSettingsAnimeDiscovery gridSettings = GridSettingsAnimeDiscovery.current;

  PagingContainer<AnimeEntry, DiscoverExtra> get container =>
      widget.pagingContainer;
  List<AnimeEntry> get entries => container.extra.entries;

  @override
  void initState() {
    super.initState();

    state = GridSkeletonState<AnimeEntry>(
      initalCellCount: entries.length,
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
    showModalBottomSheet(
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

              return widget.api.genres(AnimeSafeMode.safe).then((value) {
                container.extra.future = Future.value(value);

                return value;
              });
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
    return GridSkeleton<AnimeEntry>(
      state,
      (context) => GridFrame<AnimeEntry>(
        key: state.gridKey,
        layout: GridSettingsLayoutBehaviour(_settings),
        refreshingStatus: widget.pagingContainer.refreshingStatus,
        getCell: (i) => entries[i],
        initalScrollPosition: widget.pagingContainer.scrollPos,
        functionality: GridFunctionality(
          loadNext: _loadNext,
          updateScrollPosition: widget.pagingContainer.updateScrollPos,
          selectionGlue:
              GlueProvider.generateOf<AnimeEntry, AnimeEntry>(context),
          refresh: AsyncGridRefresh(_refresh),
          onPressed:
              OverrideGridOnCellPressBehaviour(onPressed: (context, idx, _) {
            final cell = CellProvider.getOf<AnimeEntry>(context, idx);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DiscoverAnimeInfoPage(
                  entry: cell,
                );
              },
            ));
          }),
        ),
        systemNavigationInsets: widget.viewInsets,
        mainFocus: state.mainFocus,
        description: GridDescription(
          risingAnimation: true,
          actions: DiscoverTab.actions(),
          showAppBar: false,
          keybindsDescription: AppLocalizations.of(context)!.discoverTab,
          ignoreSwipeSelectGesture: true,
          gridSeed: state.gridSeed,
        ),
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
      ),
      canPop: false,
      overrideOnPop: widget.procPop,
    );
  }
}

class _SearchBar extends StatefulWidget {
  final PagingContainer<AnimeEntry, DiscoverExtra> pagingContainer;
  final GlobalKey<GridFrameState> gridKey;

  const _SearchBar({
    super.key,
    required this.pagingContainer,
    required this.gridKey,
  });

  @override
  State<_SearchBar> createState() => __SearchBarState();
}

class __SearchBarState extends State<_SearchBar> {
  late final TextEditingController controller;

  PagingContainer<AnimeEntry, DiscoverExtra> get container =>
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

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      onSubmitted: (value) {
        if (value == container.extra.searchText) {
          return;
        }

        container.extra.searchText = value;

        widget.gridKey.currentState?.refreshSequence();

        Navigator.pop(context);
      },
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
                });
          },
        ),
        IconButton(
          onPressed: () {
            controller.text = "";
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
