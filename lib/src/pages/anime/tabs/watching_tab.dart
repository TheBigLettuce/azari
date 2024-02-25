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

  const _WatchingTab(
    this.viewInsets, {
    required super.key,
    required this.onDispose,
  });

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
  final gridSeed = math.Random().nextInt(948512342);

  bool upward = false;
  bool right = false;
  String _filteringValue = "";

  void filter(String value) {
    final m = state.gridKey.currentState?.mutation;
    if (m == null) {
      return;
    }

    _filteringValue = value;

    final l = value.toLowerCase();

    _backlogFilter.clear();
    _watchingFilter.clear();

    if (value.isEmpty) {
      m.reset();

      return;
    }

    _backlogFilter.addAll(
        backlog.where((element) => element.title.toLowerCase().contains(l)));
    _watchingFilter.addAll(currentlyWatching
        .where((element) => element.title.toLowerCase().contains(l)));

    m.setSource(_backlogFilter.length,
        (i) => _backlogFilter[upward ? _backlogFilter.length - 1 - i : i]);
  }

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      final newB = SavedAnimeEntry.backlog();
      backlog.clear();
      backlog.addAll(newB);

      if (_filteringValue.isEmpty) {
        state.gridKey.currentState?.mutation.cellCount = newB.length;
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
      (context) => GridFrame<SavedAnimeEntry>(
        key: state.gridKey,
        getCell: (i) => backlog[upward ? backlog.length - 1 - i : i],
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
        functionality: GridFunctionality(
          selectionGlue:
              GlueProvider.generateOf<AnimeEntry, SavedAnimeEntry>(context),
          refresh: SynchronousGridRefresh(() => backlog.length),
          onPressed:
              OverrideGridOnCellPressBehaviour(onPressed: (context, idx) {
            final cell = MutationInterfaceProvider.of<SavedAnimeEntry>(context)
                .getCell(idx);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return WatchingAnimeInfoPage(entry: cell);
              },
            ));
          }),
        ),
        systemNavigationInsets: widget.viewInsets,
        hasReachedEnd: () => true,
        mainFocus: state.mainFocus,
        description: GridDescription([],
            keybindsDescription: AppLocalizations.of(context)!.watchingTab,
            showAppBar: false,
            ignoreSwipeSelectGesture: true,
            ignoreEmptyWidgetOnNoContent: true,
            layout: _WatchingLayout(
              GridColumn.three,
              currentlyWatching,
              randomNumber: gridSeed,
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
    required this.randomNumber,
  });

  final bool backlogUpward;
  final void Function() flipBacklogUpward;

  final bool watchingRight;
  final void Function() flipWatchingRight;

  final List<SavedAnimeEntry> currentlyWatching;

  final int randomNumber;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(
      BuildContext context, GridFrameState<SavedAnimeEntry> state) {
    void onPressed(SavedAnimeEntry e, int _) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return WatchingAnimeInfoPage(entry: e);
        },
      ));
    }

    return [
      SliverToBoxAdapter(
        child: SegmentLabel(
          AppLocalizations.of(context)!.watchingLabel,
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
                  .map((e) => ImportantCard(
                        cell: e.$2,
                        idx: e.$1,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn())
                  .toList()
              : currentlyWatching.indexed
                  .map(
                    (e) => ImportantCard(
                      idx: e.$1,
                      cell: e.$2,
                      onPressed: onPressed,
                    ).animate(key: ValueKey(e)).fadeIn(),
                  )
                  .toList(),
        )
      else
        SliverToBoxAdapter(
            child: EmptyWidget(
          gridSeed: randomNumber,
        )),
      SliverToBoxAdapter(
        child: SegmentLabel(
          AppLocalizations.of(context)!.backlogLabel,
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
      if (state.mutation.cellCount > 0)
        GridLayout.blueprint<SavedAnimeEntry>(
          context,
          state.mutation,
          state.selection,
          systemNavigationInsets: 0,
          aspectRatio: GridAspectRatio.zeroSeven.value,
          columns: columns.number,
          gridCell: (context, idx) {
            return GridCell.frameDefault(
              context,
              idx,
              state: state,
              animated: true,
            );
          },
        )
      else
        SliverToBoxAdapter(
            child: EmptyWidget(
          gridSeed: randomNumber,
        )),
    ];
  }

  @override
  bool get isList => false;
}

class ImportantCard<T extends Cell> extends StatelessWidget {
  final T cell;
  final int idx;
  final void Function(T cell, int idx) onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  const ImportantCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return UnsizedCard(
      subtitle: Text(cell.alias(false)),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          indx: 0,
          onPressed: null,
          tight: true,
          hideAlias: true,
          download: null,
          isList: false,
          circle: true,
        ),
      ),
      backgroundImage: cell.thumbnail(),
      tooltip: cell.alias(false),
      onLongPressed: onLongPressed == null
          ? null
          : () {
              onLongPressed!(cell, idx);
            },
      onPressed: () {
        onPressed(cell, idx);
      },
    );
  }
}
