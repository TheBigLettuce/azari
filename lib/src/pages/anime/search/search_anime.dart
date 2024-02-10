// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../info_pages/discover_anime_info_page.dart';

part 'filtering_genres.dart';

class SearchAnimePage extends StatefulWidget {
  final int? initalGenreId;
  final String? initalText;
  final AnimeAPI api;
  final AnimeSafeMode explicit;

  const SearchAnimePage({
    super.key,
    required this.api,
    this.initalGenreId,
    this.initalText,
    this.explicit = AnimeSafeMode.safe,
  });

  @override
  State<SearchAnimePage> createState() => _SearchAnimePageState();
}

class _SearchAnimePageState extends State<SearchAnimePage> {
  final List<AnimeEntry> _results = [];
  late final StreamSubscription<void> watcher;
  final searchFocus = FocusNode();
  final state = GridSkeletonState<AnimeEntry>();
  late AnimeSafeMode mode = widget.explicit;

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
      _genreFuture = widget.api.genres(AnimeSafeMode.safe);
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

  Future<int> _load(String value) async {
    state.gridKey.currentState?.mutationInterface.setIsRefreshing(true);
    state.gridKey.currentState?.mutationInterface.tick(0);

    _results.clear();
    _page = 0;
    _reachedEnd = false;
    currentSearch = value;

    final result =
        await widget.api.search(value, 0, genreId: currentGenre, mode: mode);

    _results.addAll(result);

    state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);
    state.gridKey.currentState?.mutationInterface.tick(_results.length);

    return _results.length;
  }

  Future<int> _loadNext() async {
    final result = await widget.api
        .search(currentSearch, _page + 1, genreId: currentGenre, mode: mode);
    _page += 1;
    if (result.isEmpty) {
      _reachedEnd = true;
    }

    _results.addAll(result);

    return _results.length;
  }

  @override
  Widget build(BuildContext context) {
    Widget body() => WrapGridPage<AnimeEntry>(
          scaffoldKey: state.scaffoldKey,
          child: GridSkeleton<AnimeEntry>(
            state,
            (context) => GridFrame<AnimeEntry>(
              key: state.gridKey,
              menuButtonItems: [
                TextButton(
                  onPressed: () {
                    mode = switch (mode) {
                      AnimeSafeMode.safe => AnimeSafeMode.ecchi,
                      AnimeSafeMode.h => AnimeSafeMode.safe,
                      AnimeSafeMode.ecchi => AnimeSafeMode.h,
                    };

                    if (_results.isNotEmpty) {
                      _load(currentSearch);
                    }

                    setState(() {});
                  },
                  child: Text(
                    mode == AnimeSafeMode.ecchi
                        ? "E"
                        : mode == AnimeSafeMode.h
                            ? "H"
                            : "S",
                    style: TextStyle(
                      color: mode == AnimeSafeMode.h
                          ? Colors.red
                              .harmonizeWith(Theme.of(context).primaryColor)
                          : mode == AnimeSafeMode.ecchi
                              ? Colors.red
                                  .harmonizeWith(Theme.of(context).primaryColor)
                                  .withOpacity(0.5)
                              : null,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    _genreFuture ??= widget.api.genres(AnimeSafeMode.safe);

                    return [
                      PopupMenuItem(
                        enabled: false,
                        child: _FilteringGenres(
                          future: _genreFuture!,
                          currentGenre: currentGenre,
                          setGenre: (genre) {
                            currentGenre = genre;

                            _load(currentSearch);

                            setState(() {});
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
                          if (grid == null ||
                              grid.mutationInterface.isRefreshing) {
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
                    return DiscoverAnimeInfoPage(entry: cell);
                  },
                ));
              },
              onBack: () {
                Navigator.pop(context);
              },
              inlineMenuButtonItems: true,
              scaffoldKey: state.scaffoldKey,
              systemNavigationInsets: MediaQuery.viewPaddingOf(context) +
                  const EdgeInsets.only(bottom: 4),
              hasReachedEnd: () => _reachedEnd,
              selectionGlue: GlueProvider.of(context),
              mainFocus: state.mainFocus,
              refresh: () {
                if (_results.isEmpty) {
                  return Future.value(0);
                }

                return _load(currentSearch);
              },
              loadNext: _loadNext,
              description: GridDescription(
                const [],
                titleLines: 2,
                keybindsDescription:
                    AppLocalizations.of(context)!.searchAnimePage,
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

    return AnimeInfoTheme(
      mode: mode,
      overlayColor: Theme.of(context).colorScheme.background,
      child: body(),
    );
  }
}
