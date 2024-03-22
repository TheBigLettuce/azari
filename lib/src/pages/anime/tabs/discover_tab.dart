// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class DiscoverTab extends StatefulWidget {
  final EdgeInsets viewInsets;
  final void Function(bool) procPop;
  final List<AnimeEntry> entries;
  final PagingContainer<AnimeEntry> pagingContainer;
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
    required this.entries,
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

  @override
  void initState() {
    super.initState();

    state = GridSkeletonState<AnimeEntry>(
      initalCellCount: widget.entries.length,
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
        getCell: (i) => widget.entries[i],
        initalScrollPosition: widget.pagingContainer.scrollPos,
        functionality: GridFunctionality(
          loadNext: () async {
            final p = await widget.api.top(widget.pagingContainer.page + 1);

            widget.pagingContainer.page += 1;

            if (p.isEmpty) {
              widget.pagingContainer.reachedEnd = true;
            }
            widget.entries.addAll(p);

            return widget.entries.length;
          },
          updateScrollPosition: widget.pagingContainer.updateScrollPos,
          selectionGlue:
              GlueProvider.generateOf<AnimeEntry, AnimeEntry>(context),
          refresh: AsyncGridRefresh(() async {
            widget.entries.clear();
            widget.pagingContainer.page = 0;
            widget.pagingContainer.reachedEnd = false;

            final p = await widget.api.top(widget.pagingContainer.page);

            widget.entries.addAll(p);

            return widget.entries.length;
          }),
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
      overrideOnPop: (pop, hideAppBar) {
        if (hideAppBar()) {
          setState(() {});
          return;
        }

        widget.procPop(pop);
      },
    );
  }
}
