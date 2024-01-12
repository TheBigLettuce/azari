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
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../inner/anime_inner.dart';

part 'filtering_genres.dart';

class SearchAnimePage extends StatefulWidget {
  final int? initalGenreId;
  final String? initalText;
  final AnimeAPI api;

  const SearchAnimePage(
      {super.key, required this.api, this.initalGenreId, this.initalText});

  @override
  State<SearchAnimePage> createState() => _SearchAnimePageState();
}

class _SearchAnimePageState extends State<SearchAnimePage> {
  final List<AnimeEntry> _results = [];
  late final StreamSubscription<void> watcher;
  final searchFocus = FocusNode();
  final state = GridSkeletonState<AnimeEntry>();

  Future<Map<int, AnimeGenre>>? _genreFuture;

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

    if (widget.initalGenreId != null) {
      _genreFuture = widget.api.genres();
    }

    currentGenre = widget.initalGenreId;
    currentSearch = widget.initalText ?? "";

    if (widget.initalGenreId != null || widget.initalText != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        _load(currentSearch);
      });
    }
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

    final result = await widget.api.search(value, 0, currentGenre);

    _results.addAll(result);

    state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);
    state.gridKey.currentState?.mutationInterface.tick(_results.length);
  }

  Future<int> _loadNext() async {
    final result = await widget.api.search(currentSearch, _page + 1);
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
                _genreFuture ??= widget.api.genres();

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
              FutureBuilder(
                future: _genreFuture,
                builder: (context, snapshot) {
                  return TextFormField(
                    initialValue: currentSearch,
                    decoration: InputDecoration(
                        hintText:
                            "${AppLocalizations.of(context)!.searchHint} ${currentGenre == null ? '' : !snapshot.hasData ? '...' : snapshot.data?[currentGenre!]?.title ?? ''}",
                        border: InputBorder.none),
                    focusNode: searchFocus,
                    onFieldSubmitted: (value) {
                      final grid = state.gridKey.currentState;
                      if (grid == null || grid.mutationInterface.isRefreshing) {
                        return;
                      }

                      _load(value);
                    },
                  );
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
            titleLines: 2,
            keybindsDescription: AppLocalizations.of(context)!.searchAnimePage,
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
