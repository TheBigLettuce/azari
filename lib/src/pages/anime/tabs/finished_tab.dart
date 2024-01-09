// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _FinishedTab extends StatefulWidget {
  const _FinishedTab({super.key});

  @override
  State<_FinishedTab> createState() => __FinishedTabState();
}

class __FinishedTabState extends State<_FinishedTab> {
  late final StreamSubscription<void> watcher;

  final List<WatchedAnimeEntry> _list = [];

  final state = GridSkeletonState<WatchedAnimeEntry>();

  @override
  void initState() {
    super.initState();

    _list.addAll(WatchedAnimeEntry.all);

    watcher = WatchedAnimeEntry.watchAll((_) {
      state.gridKey.currentState?.mutationInterface.tick(0);
      _list.clear();
      _list.addAll(WatchedAnimeEntry.all);

      setState(() {});

      state.gridKey.currentState?.mutationInterface.tick(_list.length);
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

    return GridSkeleton<WatchedAnimeEntry>(
      state,
      (context) => CallbackGrid<WatchedAnimeEntry>(
        key: state.gridKey,
        getCell: (i) => _list[_list.length - 1 - i],
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets:
            viewInsets.copyWith(bottom: viewInsets.bottom + 6),
        hasReachedEnd: () => true,
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return FinishedPage(entry: cell);
            },
          ));
        },
        selectionGlue: SelectionGlue.empty(context),
        mainFocus: state.mainFocus,
        refresh: () => Future.value(_list.length),
        description: GridDescription([],
            keybindsDescription: "Finished tab",
            showAppBar: false,
            ignoreSwipeSelectGesture: true,
            layout: GridLayout(GridColumn.three, GridAspectRatio.one,
                hideAlias: false)),
      ),
      canPop: false,
    );
  }
}
