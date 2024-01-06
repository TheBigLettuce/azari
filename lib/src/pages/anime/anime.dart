// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/anime_inner.dart';
import 'package:gallery/src/pages/booru/grid_settings_button.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/layouts/note_layout.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class AnimePage extends StatefulWidget {
  final SelectionGlue<AnimeEntry> glue;

  const AnimePage({super.key, required this.glue});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<GridSettingsAnimeDiscovery?>
      gridSettingsWatcher;
  final state = SkeletonState();
  late final tabController = TabController(length: 3, vsync: this);

  final List<AnimeEntry> _list = [];
  int _page = 0;
  bool _reachedEnd = false;

  final stateDiscover = GridSkeletonState<AnimeEntry>();
  GridSettingsAnimeDiscovery gridSettings = GridSettingsAnimeDiscovery.current;

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
    gridSettingsWatcher.cancel();

    state.dispose();
    stateDiscover.dispose();
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SkeletonSettings(
      "Anime",
      state,
      appBar: AppBar(
        actions: [
          GridSettingsButton(gridSettings,
              selectRatio: null,
              selectHideName: (value) =>
                  gridSettings.copy(hideName: value).save(),
              selectListView: null,
              selectGridColumn: (value) =>
                  gridSettings.copy(columns: value).save())
        ],
        title: Text("Anime"),
        bottom: TabBar(controller: tabController, tabs: [
          Tab(text: "Watching"),
          Tab(text: "Discover"),
          Tab(text: "All"),
        ]),
      ),
      child: TabBarView(
        controller: tabController,
        children: [
          EmptyWidget(),
          GridSkeleton<AnimeEntry>(
            stateDiscover,
            (context) => CallbackGrid<AnimeEntry>(
              key: stateDiscover.gridKey,
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
              scaffoldKey: stateDiscover.scaffoldKey,
              systemNavigationInsets:
                  viewInsets.copyWith(bottom: viewInsets.bottom + 6),
              hasReachedEnd: () => _reachedEnd,
              selectionGlue: widget.glue,
              mainFocus: stateDiscover.mainFocus,
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
                layout: GridLayout(
                  gridSettings.columns,
                  GridAspectRatio.zeroSeven,
                  hideAlias: gridSettings.hideName,
                ),
              ),
            ),
            canPop: false,
          ),
          EmptyWidget(),
        ],
      ),
    );
  }
}
