// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime.dart';

class _DiscoverTab extends StatefulWidget {
  final void Function(bool) procPop;

  const _DiscoverTab({super.key, required this.procPop});

  @override
  State<_DiscoverTab> createState() => __DiscoverTabState();
}

class __DiscoverTabState extends State<_DiscoverTab> {
  final List<AnimeEntry> _list = [];
  late final StreamSubscription<GridSettingsAnimeDiscovery?>
      gridSettingsWatcher;
  final state = GridSkeletonState<AnimeEntry>();

  GridSettingsAnimeDiscovery gridSettings = GridSettingsAnimeDiscovery.current;

  int _page = 0;
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return GridSkeleton<AnimeEntry>(
      state,
      (context) => CallbackGrid<AnimeEntry>(
        key: state.gridKey,
        getCell: (i) => _list[i],
        initalScrollPosition: 0,
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return AnimeInner(entry: cell);
            },
          ));
        },
        initalCellCount: _list.length,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets:
            viewInsets.copyWith(bottom: viewInsets.bottom + 6),
        hasReachedEnd: () => _reachedEnd,
        selectionGlue: GlueProvider.of<AnimeEntry>(context),
        mainFocus: state.mainFocus,
        refresh: () async {
          _list.clear();
          _page = 0;
          _reachedEnd = false;

          final p = await const Jikan().top(_page);

          _list.addAll(p);

          return _list.length;
        },
        addFabPadding: true,
        loadNext: () async {
          final p = await const Jikan().top(_page + 1);
          _page += 1;

          if (p.isEmpty) {
            _reachedEnd = true;
          }
          _list.addAll(p);

          return _list.length;
        },
        description: GridDescription(
          [
            GridAction(Icons.add, (selected) {}, true),
          ],
          showAppBar: false,
          keybindsDescription: "Anime",
          ignoreSwipeSelectGesture: true,
          layout: GridLayout(
            gridSettings.columns,
            GridAspectRatio.zeroSeven,
            hideAlias: gridSettings.hideName,
          ),
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
