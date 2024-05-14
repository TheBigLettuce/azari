// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../anime.dart";

class _FinishedTab extends StatefulWidget {
  const _FinishedTab({
    required this.procPop,
    required super.key,
    required this.onDispose,
    required this.db,
  });

  final void Function() onDispose;
  final void Function(bool) procPop;

  final DbConn db;

  @override
  State<_FinishedTab> createState() => __FinishedTabState();
}

class __FinishedTabState extends State<_FinishedTab> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  late final StreamSubscription<void> watcher;
  final gridSettings = GridSettingsData.noPersist(
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.gridQuilted,
    hideName: false,
  );

  late final originalSource = GenericListSource<WatchedAnimeEntryData>(
    () => Future.value(watchedAnimeEntries.all),
  );
  late final ChainedFilterResourceSource<WatchedAnimeEntryData> filter;

  late final state = GridSkeletonState<WatchedAnimeEntryData>();

  String _filteringValue = "";

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource.basic(
      originalSource,
      ListStorage(),
      fn: (e, filteringMode, sortingMode) => e.title.contains(_filteringValue),
    );

    watcher = watchedAnimeEntries.watchAll((_) {
      originalSource.clearRefresh();
    });
  }

  @override
  void dispose() {
    originalSource.destroy();
    filter.destroy();
    widget.onDispose();
    gridSettings.cancel();

    watcher.cancel();

    state.dispose();

    super.dispose();
  }

  void doFilter(String value) {
    _filteringValue = value.toLowerCase().trim();

    filter.clearRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridSkeleton<AnimeEntryData>(
        state,
        (context) => GridFrame<WatchedAnimeEntryData>(
          key: state.gridKey,
          slivers: [
            CurrentGridSettingsLayout(
              source: filter.backingStorage,
              progress: filter.progress,
              gridSeed: state.gridSeed,
            ),
          ],
          functionality: GridFunctionality(
            selectionGlue: GlueProvider.generateOf(context)(),
            source: filter,
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            actions: [
              GridAction(
                Icons.delete_rounded,
                (selected) {
                  watchedAnimeEntries.deleteAll(selected.toIds);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l8n.deletedFromWatched,
                      ),
                      action: SnackBarAction(
                        label: l8n.undoLabel,
                        onPressed: () {
                          watchedAnimeEntries.reAdd(selected);
                        },
                      ),
                    ),
                  );
                },
                true,
              ),
              GridAction(
                Icons.redo_rounded,
                (s) =>
                    watchedAnimeEntries.moveAllReversed(s, savedAnimeEntries),
                true,
              ),
            ],
            keybindsDescription: l8n.finishedTab,
            showAppBar: false,
            gridSeed: state.gridSeed,
          ),
        ),
        canPop: false,
        onPop: widget.procPop,
      ),
    );
  }
}
