// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _WatchingTab extends StatefulWidget {
  const _WatchingTab({super.key});

  @override
  State<_WatchingTab> createState() => __WatchingTabState();
}

class __WatchingTabState extends State<_WatchingTab> {
  final state = GridSkeletonState<SavedAnimeEntry>();
  final List<SavedAnimeEntry> currentlyWatching =
      SavedAnimeEntry.currentlyWatching();
  final List<SavedAnimeEntry> backlog = SavedAnimeEntry.backlog();

  late final StreamSubscription<void> watcher;

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      final newB = SavedAnimeEntry.backlog();
      backlog.clear();
      backlog.addAll(newB);

      state.gridKey.currentState?.mutationInterface.tick(newB.length);

      currentlyWatching.clear();
      currentlyWatching.addAll(SavedAnimeEntry.currentlyWatching());
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
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return GridSkeleton<SavedAnimeEntry>(
      state,
      (context) => CallbackGrid<SavedAnimeEntry>(
        key: state.gridKey,
        getCell: (i) => backlog[i],
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets:
            viewInsets.copyWith(bottom: viewInsets.bottom + 6),
        hasReachedEnd: () => true,
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return WatchingPage(entry: cell);
            },
          ));
        },
        selectionGlue: SelectionGlue.empty(context),
        mainFocus: state.mainFocus,
        refresh: () => Future.value(backlog.length),
        description: GridDescription([],
            keybindsDescription: "Watching",
            showAppBar: false,
            ignoreSwipeSelectGesture: true,
            ignoreEmptyWidgetOnNoContent: true,
            layout: _WatchingLayout(GridColumn.three, currentlyWatching)
            // GridLayout(GridColumn.two, GridAspectRatio.one, hideAlias: false),
            ),
      ),
      canPop: false,
    );
  }
}

class _WatchingLayout implements GridLayouter<SavedAnimeEntry> {
  const _WatchingLayout(this.columns, this.currentlyWatching);

  final List<SavedAnimeEntry> currentlyWatching;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(
      BuildContext context, CallbackGridState<SavedAnimeEntry> state) {
    return [
      const SliverToBoxAdapter(
        child: SegmentLabel("Currently watching",
            hidePinnedIcon: true, onPress: null, sticky: false),
      ),
      if (currentlyWatching.isNotEmpty)
        SliverGrid.count(
          crossAxisCount: 3,
          children: currentlyWatching
              .map(
                (e) => _CurrentlyWatchingEntry(entry: e),
              )
              .toList(),
        )
      else
        const SliverToBoxAdapter(child: EmptyWidget()),
      const SliverToBoxAdapter(
        child: SegmentLabel("Backlog",
            hidePinnedIcon: true, onPress: null, sticky: false),
      ),
      if (state.mutationInterface.cellCount > 0)
        GridLayouts.grid<SavedAnimeEntry>(
          context,
          state.mutationInterface,
          state.selection,
          columns.number,
          isList,
          state.makeGridCell,
          hideAlias: false,
          tightMode: false,
          systemNavigationInsets: 0,
          aspectRatio: GridAspectRatio.zeroSeven.value,
        )
      else
        const SliverToBoxAdapter(child: EmptyWidget()),
    ];
  }

  @override
  bool get isList => false;
}

class _CurrentlyWatchingEntry extends StatelessWidget {
  final SavedAnimeEntry entry;

  const _CurrentlyWatchingEntry({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final thumb = entry.getCellData(false, context: context).thumb;

    return UnsizedCard(
      subtitle: Text(entry.title),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: entry,
          indx: 0,
          onPressed: null,
          tight: true,
          hidealias: true,
          download: null,
          isList: false,
          circle: true,
        ),
      ),
      backgroundImage: thumb,
      tooltip: entry.title,
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return WatchingPage(entry: entry);
          },
        ));
      },
    );
  }
}
