// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
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
  late final StreamSubscription<void> watcher;
  // final List<AnimeGenre> _genres = [];
  final searchFocus = FocusNode();
  final state = GridSkeletonState<AnimeEntry>();

  Future<List<AnimeGenre>>? _genreFuture;

  final gridSettings = GridSettingsAnimeDiscovery.current;

  int _page = 0;

  String currentSearch = "";
  int? currentGenre;

  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    _genreFuture?.ignore();

    state.dispose();
    searchFocus.dispose();

    super.dispose();
  }

  void _load(String value) async {
    state.gridKey.currentState?.mutationInterface.setIsRefreshing(true);
    state.gridKey.currentState?.mutationInterface.tick(0);

    _results.clear();
    _page = 0;
    _reachedEnd = false;
    currentSearch = value;

    final result = await const Jikan().search(value, 0, currentGenre);

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
          menuButtonItems: [
            PopupMenuButton(
              itemBuilder: (context) {
                _genreFuture ??= const Jikan().genres();

                return [
                  PopupMenuItem(
                    enabled: false,
                    child: _FilteringGenres(
                      future: _genreFuture!,
                      currentGenre: currentGenre,
                      setGenre: (genre) {
                        currentGenre = genre;

                        _load(currentSearch);
                      },
                    ),
                  )
                ];
              },
              icon: Icon(Icons.filter_list_outlined,
                  color: currentGenre != null
                      ? Theme.of(context).colorScheme.primary
                      : null),
            ),
          ],
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
          systemNavigationInsets: MediaQuery.viewPaddingOf(context) +
              const EdgeInsets.only(bottom: 4),
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

class _FilteringGenres extends StatefulWidget {
  final Future<List<AnimeGenre>> future;
  final int? currentGenre;
  final void Function(int?) setGenre;

  const _FilteringGenres({
    super.key,
    required this.future,
    required this.currentGenre,
    required this.setGenre,
  });

  @override
  State<_FilteringGenres> createState() => __FilteringGenresState();
}

class __FilteringGenresState extends State<_FilteringGenres> {
  List<AnimeGenre>? _result;

  Widget _tile(AnimeGenre e) => ListTile(
        titleTextStyle:
            TextStyle(color: Theme.of(context).colorScheme.onSurface),
        title: Text(e.name),
        selected: e.id == widget.currentGenre,
        onTap: () {
          widget.setGenre(e.id);

          Navigator.pop(context);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FutureBuilder(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: [
              TextButton(
                  onPressed: () {
                    widget.setGenre(null);

                    Navigator.pop(context);
                  },
                  child: Text("Reset")),
              TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: "Filter"),
                onChanged: (value) {
                  _result = snapshot.data!
                      .where((element) => element.name
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList();

                  setState(() {});
                },
              ),
              if (_result != null)
                if (_result == null)
                  const SizedBox.shrink()
                else
                  ..._result!.map((e) => _tile(e))
              else
                ...snapshot.data!.map((e) => _tile(e)),
            ]).animate().fadeIn();
          } else {
            return const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
