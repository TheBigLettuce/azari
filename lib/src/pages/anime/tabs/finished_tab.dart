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
  });

  final void Function() onDispose;
  final void Function(bool) procPop;

  @override
  State<_FinishedTab> createState() => __FinishedTabState();
}

class __FinishedTabState extends State<_FinishedTab> {
  late final StreamSubscription<void> watcher;

  final List<WatchedAnimeEntryData> _list = [];
  final List<WatchedAnimeEntryData> _filter = [];

  late final state = GridSkeletonRefreshingState<WatchedAnimeEntryData>(
    clearRefresh: SynchronousGridRefresh(() => _list.length),
  );

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

    _filteringValue = value.trim();

    final l = _filteringValue.toLowerCase();

    _filter.clear();

    if (_filteringValue.isEmpty) {
      setState(() {});

      m.cellCount = _list.length;

      return;
    }

    _filter.addAll(
      _list.where((element) => element.title.toLowerCase().contains(l)),
    );

    m.cellCount = _filter.length;
  }

  WatchedAnimeEntryData _getCell(int i) {
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
    return GridSkeleton<AnimeEntryData>(
      state,
      (context) => GridFrame<WatchedAnimeEntryData>(
        key: state.gridKey,
        layout: const GridSettingsLayoutBehaviour(_settings),
        getCell: _getCell,
        functionality: GridFunctionality(
          selectionGlue: GlueProvider.generateOf(context)(),
          refreshingStatus: state.refreshingStatus,

          // imageViewDescription: ImageViewDescription(
          //   imageViewKey: state.imageViewKey,
          // ),
          // onPressed: OverrideGridOnCellPressBehaviour(
          //   onPressed: (context, idx, _) {
          //     final cell =
          //         CellProvider.getOf<WatchedAnimeEntry>(context, idx);

          //     return Navigator.push(context, MaterialPageRoute(
          //       builder: (context) {
          //         return FinishedAnimeInfoPage(entry: cell);
          //       },
          //     ));
          //   },
          // ),
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: [
            GridAction(
              Icons.delete_rounded,
              (selected) {
                WatchedAnimeEntry.deleteAll(selected);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.deletedFromWatched),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.undoLabel,
                      onPressed: () {
                        WatchedAnimeEntry.reAdd(selected);
                      },
                    ),
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
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
      onPop: widget.procPop,
    );
  }
}
