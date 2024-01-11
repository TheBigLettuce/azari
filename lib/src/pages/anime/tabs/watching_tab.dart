// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _WatchingTab extends StatefulWidget {
  final EdgeInsets viewInsets;
  final void Function() onDispose;

  const _WatchingTab(this.viewInsets,
      {required super.key, required this.onDispose});

  @override
  State<_WatchingTab> createState() => __WatchingTabState();
}

class __WatchingTabState extends State<_WatchingTab> {
  final state = GridSkeletonState<SavedAnimeEntry>();
  final List<SavedAnimeEntry> currentlyWatching =
      SavedAnimeEntry.currentlyWatching();
  final List<SavedAnimeEntry> backlog = SavedAnimeEntry.backlog();

  final List<SavedAnimeEntry> _backlogFilter = [];
  final List<SavedAnimeEntry> _watchingFilter = [];

  late final StreamSubscription<void> watcher;

  bool upward = false;
  bool right = false;
  String _filteringValue = "";

  void filter(String value) {
    final m = state.gridKey.currentState?.mutationInterface;
    if (m == null) {
      return;
    }

    _filteringValue = value;

    final l = value.toLowerCase();

    _backlogFilter.clear();
    _watchingFilter.clear();

    if (value.isEmpty) {
      m.restore();

      return;
    }

    _backlogFilter.addAll(
        backlog.where((element) => element.title.toLowerCase().contains(l)));
    _watchingFilter.addAll(currentlyWatching
        .where((element) => element.title.toLowerCase().contains(l)));

    m.setSource(_backlogFilter.length, (i) => _backlogFilter[i]);
  }

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      final newB = SavedAnimeEntry.backlog();
      backlog.clear();
      backlog.addAll(newB);

      if (_filteringValue.isEmpty) {
        state.gridKey.currentState?.mutationInterface.tick(newB.length);
      } else {
        filter(_filteringValue);
      }

      currentlyWatching.clear();
      currentlyWatching.addAll(SavedAnimeEntry.currentlyWatching());
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    state.dispose();

    widget.onDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<SavedAnimeEntry>(
      state,
      (context) => CallbackGrid<SavedAnimeEntry>(
        key: state.gridKey,
        getCell: (i) => backlog[upward ? backlog.length - 1 - i : i],
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets: widget.viewInsets.copyWith(
            bottom: widget.viewInsets.bottom +
                (!GlueProvider.of<AnimeEntry>(context).keyboardVisible()
                    ? 80
                    : 0)),
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
            layout: _WatchingLayout(
              GridColumn.three,
              currentlyWatching,
              flipBacklogUpward: () {
                upward = !upward;

                setState(() {});
              },
              backlogUpward: upward,
              watchingRight: right,
              flipWatchingRight: () {
                right = !right;

                setState(() {});
              },
            )),
      ),
      canPop: false,
    );
  }
}

class _WatchingLayout implements GridLayouter<SavedAnimeEntry> {
  const _WatchingLayout(
    this.columns,
    this.currentlyWatching, {
    required this.backlogUpward,
    required this.flipBacklogUpward,
    required this.flipWatchingRight,
    required this.watchingRight,
  });

  final bool backlogUpward;
  final void Function() flipBacklogUpward;

  final bool watchingRight;
  final void Function() flipWatchingRight;

  final List<SavedAnimeEntry> currentlyWatching;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(
      BuildContext context, CallbackGridState<SavedAnimeEntry> state) {
    return [
      SliverToBoxAdapter(
        child: SegmentLabel(
          "Currently watching",
          hidePinnedIcon: true,
          onPress: null,
          sticky: false,
          overridePinnedIcon: IconButton(
            onPressed: flipWatchingRight,
            icon: (watchingRight
                    ? const Icon(Icons.arrow_back)
                    : const Icon(Icons.arrow_forward))
                .animate(key: ValueKey(watchingRight))
                .fadeIn(),
          ),
        ),
      ),
      if (currentlyWatching.isNotEmpty)
        SliverGrid.count(
          crossAxisCount: 3,
          children: watchingRight
              ? currentlyWatching.reversed.indexed
                  .map((e) => _CurrentlyWatchingEntry(entry: e.$2)
                      .animate(key: ValueKey(e))
                      .fadeIn())
                  .toList()
              : currentlyWatching.indexed
                  .map(
                    (e) => _CurrentlyWatchingEntry(entry: e.$2)
                        .animate(key: ValueKey(e))
                        .fadeIn(),
                  )
                  .toList(),
        )
      else
        const SliverToBoxAdapter(child: EmptyWidget()),
      SliverToBoxAdapter(
        child: SegmentLabel(
          "Backlog",
          hidePinnedIcon: true,
          onPress: null,
          sticky: false,
          overridePinnedIcon: IconButton(
            onPressed: flipBacklogUpward,
            icon: (backlogUpward
                    ? const Icon(Icons.arrow_upward)
                    : const Icon(Icons.arrow_downward))
                .animate(key: ValueKey(backlogUpward))
                .fadeIn(),
          ),
        ),
      ),
      if (state.mutationInterface.cellCount > 0)
        GridLayouts.grid<SavedAnimeEntry>(
          context,
          state.mutationInterface,
          state.selection,
          columns.number,
          isList,
          state.makeGridCellAnimate,
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

  const _CurrentlyWatchingEntry({required this.entry});

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
