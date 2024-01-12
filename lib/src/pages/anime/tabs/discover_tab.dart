// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _DiscoverTab extends StatefulWidget {
  final EdgeInsets viewInsets;
  final RefreshingStatusInterface refreshingInterface;
  final void Function(bool) procPop;
  final List<AnimeEntry> entries;
  final void Function(double, {double? infoPos, int? selectedCell})?
      updateScrollPosition;
  final double Function() initalScrollOffset;
  final int Function() initalPage;
  final void Function(int) savePage;

  const _DiscoverTab({
    required this.procPop,
    required this.entries,
    required this.initalPage,
    required this.savePage,
    required this.initalScrollOffset,
    required this.updateScrollPosition,
    required this.refreshingInterface,
    required this.viewInsets,
  });

  @override
  State<_DiscoverTab> createState() => __DiscoverTabState();
}

class __DiscoverTabState extends State<_DiscoverTab> {
  late final StreamSubscription<GridSettingsAnimeDiscovery?>
      gridSettingsWatcher;
  final state = GridSkeletonState<AnimeEntry>();

  GridSettingsAnimeDiscovery gridSettings = GridSettingsAnimeDiscovery.current;

  late int _page = widget.initalPage();
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
    return GridSkeleton<AnimeEntry>(
      state,
      (context) => CallbackGrid<AnimeEntry>(
        key: state.gridKey,
        getCell: (i) => widget.entries[i],
        initalScrollPosition: widget.initalScrollOffset(),
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return AnimeInner(entry: cell);
            },
          ));
        },
        initalCellCount: widget.entries.length,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets: widget.viewInsets.copyWith(
            bottom: widget.viewInsets.bottom +
                (!GlueProvider.of<AnimeEntry>(context).keyboardVisible()
                    ? 80
                    : 0)),
        hasReachedEnd: () => _reachedEnd,
        selectionGlue: GlueProvider.of<AnimeEntry>(context),
        mainFocus: state.mainFocus,
        refresh: () async {
          widget.entries.clear();
          widget.savePage(0);
          _page = 0;
          _reachedEnd = false;

          final p = await const Jikan().top(_page);

          widget.entries.addAll(p);

          return widget.entries.length;
        },
        updateScrollPosition: widget.updateScrollPosition,
        refreshInterface: widget.refreshingInterface,
        loadNext: () async {
          final p = await const Jikan().top(_page + 1);

          _page += 1;
          widget.savePage(_page);

          if (p.isEmpty) {
            _reachedEnd = true;
          }
          widget.entries.addAll(p);

          return widget.entries.length;
        },
        description: GridDescription(
          [
            GridAction(Icons.add, (selected) {
              SavedAnimeEntry.addAll(selected, AnimeMetadata.jikan);
            }, true),
          ],
          showAppBar: false,
          keybindsDescription: AppLocalizations.of(context)!.discoverTab,
          ignoreSwipeSelectGesture: true,
          layout: GridLayout(
            gridSettings.columns,
            GridAspectRatio.zeroSeven,
            hideAlias: false,
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
