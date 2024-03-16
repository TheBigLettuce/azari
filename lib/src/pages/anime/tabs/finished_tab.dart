// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _FinishedTab extends StatefulWidget {
  final void Function() onDispose;
  final EdgeInsets viewInsets;
  final void Function(bool) procPop;

  const _FinishedTab(
    this.viewInsets, {
    required this.procPop,
    required super.key,
    required this.onDispose,
  });

  @override
  State<_FinishedTab> createState() => __FinishedTabState();
}

class __FinishedTabState extends State<_FinishedTab> {
  late final StreamSubscription<void> watcher;

  final List<WatchedAnimeEntry> _list = [];
  final List<WatchedAnimeEntry> _filter = [];

  final state = GridSkeletonState<WatchedAnimeEntry>();

  String _filteringValue = "";

  @override
  void initState() {
    super.initState();

    _list.addAll(WatchedAnimeEntry.all);

    watcher = WatchedAnimeEntry.watchAll((_) {
      state.gridKey.currentState?.mutation.cellCount = 0;
      _list.clear();
      _list.addAll(WatchedAnimeEntry.all);

      setState(() {});

      if (_filteringValue.isNotEmpty) {
        filter(_filteringValue);
      } else {
        state.gridKey.currentState?.mutation.cellCount = _list.length;
      }
    });
  }

  @override
  void dispose() {
    widget.onDispose();

    watcher.cancel();

    state.dispose();

    super.dispose();
  }

  void filter(String value) {
    final m = state.gridKey.currentState?.mutation;
    if (m == null) {
      return;
    }

    value = value.trim();

    _filteringValue = value;

    final l = value.toLowerCase();

    _filter.clear();

    if (value.isEmpty) {
      setState(() {});

      m.cellCount = _list.length;

      return;
    }

    _filter.addAll(
        _list.where((element) => element.title.toLowerCase().contains(l)));

    m.cellCount = _filter.length;
  }

  WatchedAnimeEntry _getCell(int i) {
    if (_filter.isNotEmpty) {
      return _filter[_filter.length - 1 - i];
    }

    return _list[_list.length - 1 - i];
  }

  static GridSettingsBase _settings() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.one,
        columns: GridColumn.three,
        layoutType: GridLayoutType.gridQuilted,
        hideName: false,
      );

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<AnimeEntry>(
      state,
      (context) => GridFrame<WatchedAnimeEntry>(
        key: state.gridKey,
        layout: const GridSettingsLayoutBehaviour(_settings),
        refreshingStatus: state.refreshingStatus,
        getCell: _getCell,
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
        functionality: GridFunctionality(
            selectionGlue:
                GlueProvider.generateOf<AnimeEntry, WatchedAnimeEntry>(context),
            refresh: SynchronousGridRefresh(() => _list.length),
            onPressed: OverrideGridOnCellPressBehaviour(
              onPressed: (context, idx, _) {
                final cell =
                    CellProvider.getOf<WatchedAnimeEntry>(context, idx);

                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return FinishedAnimeInfoPage(entry: cell);
                  },
                ));
              },
            )),
        systemNavigationInsets: widget.viewInsets,
        mainFocus: state.mainFocus,
        description: GridDescription(
          risingAnimation: true,
          actions: [
            GridAction(
              Icons.delete_rounded,
              (selected) {
                WatchedAnimeEntry.deleteAll(
                    selected.map((e) => e.isarId!).toList());

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Deleted from finished"),
                    action: SnackBarAction(
                        label: "Undo",
                        onPressed: () {
                          WatchedAnimeEntry.reAdd(selected);
                        }),
                  ),
                );
              },
              true,
            ),
            const GridAction(
              Icons.redo_rounded,
              WatchedAnimeEntry.moveAllReversed,
              true,
            ),
          ],
          keybindsDescription: AppLocalizations.of(context)!.finishedTab,
          showAppBar: false,
          ignoreSwipeSelectGesture: true,
          gridSeed: state.gridSeed,
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
