// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

import '../inner/anime_inner.dart';

class SearchAnimePage extends StatefulWidget {
  const SearchAnimePage({super.key});

  @override
  State<SearchAnimePage> createState() => _SearchAnimePageState();
}

class _SearchAnimePageState extends State<SearchAnimePage> {
  final List<AnimeEntry> _results = [];
  final searchFocus = FocusNode();
  final state = GridSkeletonState<AnimeEntry>();

  final gridSettings = GridSettingsAnimeDiscovery.current;

  int _page = 0;
  String currentSearch = "";

  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    searchFocus.dispose();

    super.dispose();
  }

  void _load(String value) async {
    state.gridKey.currentState?.mutationInterface.tick(0);

    _results.clear();
    _page = 0;
    _reachedEnd = false;
    currentSearch = value;

    final result = await const Jikan().search(value, 0);

    _results.addAll(result);

    state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);
    state.gridKey.currentState?.mutationInterface.tick(_results.length);
  }

  Future<int> _loadNext() async {
    final result = await const Jikan().search(currentSearch, _page + 1);
    _page += 1;
    if (result.isEmpty) {
      _reachedEnd = true;
    }

    _results.addAll(result);

    return _results.length;
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<AnimeEntry>(
      scaffoldKey: state.scaffoldKey,
      child: GridSkeleton<AnimeEntry>(
        state,
        (context) => CallbackGrid<AnimeEntry>(
          key: state.gridKey,
          getCell: (i) => _results[i],
          searchWidget: SearchAndFocus(
              TextField(
                decoration: const InputDecoration(
                    hintText: "Search", border: InputBorder.none),
                focusNode: searchFocus,
                onSubmitted: (value) {
                  final grid = state.gridKey.currentState;
                  if (grid == null || grid.mutationInterface.isRefreshing) {
                    return;
                  }

                  state.gridKey.currentState?.mutationInterface
                      .setIsRefreshing(true);

                  _load(value);
                },
              ),
              searchFocus),
          initalScrollPosition: 0,
          overrideOnPress: (context, cell) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return AnimeInner(entry: cell);
              },
            ));
          },
          onBack: () {
            Navigator.pop(context);
          },
          scaffoldKey: state.scaffoldKey,
          systemNavigationInsets: MediaQuery.viewPaddingOf(context),
          hasReachedEnd: () => _reachedEnd,
          selectionGlue: GlueProvider.of(context),
          mainFocus: state.mainFocus,
          refresh: () {
            return Future.value(_results.length);
          },
          loadNext: _loadNext,
          description: GridDescription(
            [],
            keybindsDescription: "Anime search",
            layout: GridLayout(
              gridSettings.columns,
              GridAspectRatio.zeroSeven,
              hideAlias: false,
            ),
          ),
        ),
        canPop: true,
      ),
    );
  }
}
