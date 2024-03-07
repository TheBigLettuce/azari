// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/manga/manga_info_page.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import '../info_pages/discover_anime_info_page.dart';

class SearchAnimePage<T extends Cell, I, G> extends StatefulWidget {
  final I? initalGenreId;
  final String? initalText;
  final AnimeSafeMode explicit;
  final Future<List<T>> Function(String, int, I?, AnimeSafeMode) search;
  final Future<Map<I, G>> Function(AnimeSafeMode)? genres;
  final (I, String) Function(G) idFromGenre;
  final void Function(T) onPressed;
  final SelectionGlue<J> Function<J extends Cell>()? generateGlue;
  final EdgeInsets? viewInsets;

  static void launchMangaApi(
    BuildContext context,
    MangaAPI api, {
    EdgeInsets? viewInsets,
    SelectionGlue<J> Function<J extends Cell>()? generateGlue,
    String? search,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    MangaId? initalGenreId,
  }) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SearchAnimePage<MangaEntry, MangaId, MangaGenre>(
          generateGlue: generateGlue,
          viewInsets: viewInsets,
          initalText: search,
          explicit: safeMode,
          initalGenreId: initalGenreId,
          idFromGenre: (genre) {
            return (genre.id, genre.name);
          },
          onPressed: (cell) {
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (context) {
                return MangaInfoPage(
                  id: cell.id,
                  entry: cell,
                  api: api,
                );
              },
            ));
          },
          search: (text, page, id, safeMode) {
            return api.search(
              text,
              page: page,
              includesTag: id != null ? [id] : null,
              safeMode: safeMode,
              count: 30,
            );
          },
          genres: (safeMode) {
            return api.tags().then((value) {
              final m = <MangaId, MangaGenre>{};

              for (final e in value) {
                m[e.id] = e;
              }

              return m;
            });
          },
        );
      },
    ));
  }

  static void launchAnimeApi(
    BuildContext context,
    AnimeAPI api, {
    String? search,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    int? initalGenreId,
  }) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SearchAnimePage<AnimeEntry, int, AnimeGenre>(
          initalText: search,
          explicit: safeMode,
          initalGenreId: initalGenreId,
          idFromGenre: (genre) {
            return (genre.id, genre.title);
          },
          onPressed: (cell) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DiscoverAnimeInfoPage(entry: cell);
              },
            ));
          },
          search: api.search,
          genres: api.genres,
        );
      },
    ));
  }

  const SearchAnimePage({
    super.key,
    required this.idFromGenre,
    required this.onPressed,
    required this.search,
    required this.genres,
    this.initalGenreId,
    this.initalText,
    this.generateGlue,
    this.viewInsets,
    this.explicit = AnimeSafeMode.safe,
  });

  @override
  State<SearchAnimePage<T, I, G>> createState() =>
      _SearchAnimePageState<T, I, G>();
}

class _SearchAnimePageState<T extends Cell, I, G>
    extends State<SearchAnimePage<T, I, G>> {
  final List<T> _results = [];
  late final StreamSubscription<void> watcher;
  final searchFocus = FocusNode();
  late final state = GridSkeletonState<T>(reachedEnd: () => _reachedEnd);
  late AnimeSafeMode mode = widget.explicit;

  final gridSettings = GridSettingsAnimeDiscovery.current;
  Future<Map<I, G>>? _genreFuture;
  Map<I, G>? genres;

  int _page = 0;

  String currentSearch = "";
  I? currentGenre;

  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      setState(() {});
    });

    if (widget.initalGenreId != null) {
      _genreFuture = widget.genres?.call(AnimeSafeMode.safe).then((value) {
        genres = value;

        setState(() {});

        return value;
      });
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

    state.dispose();
    searchFocus.dispose();

    super.dispose();
  }

  Future<int> _load(String value) async {
    final mutation = state.gridKey.currentState?.mutation;

    mutation?.isRefreshing = true;
    mutation?.cellCount = 0;

    _results.clear();
    _page = 0;
    _reachedEnd = false;
    currentSearch = value;

    final result = await widget.search(value, 0, currentGenre, mode);

    _results.addAll(result);

    mutation?.isRefreshing = false;
    mutation?.cellCount = _results.length;

    return _results.length;
  }

  Future<int> _loadNext() async {
    final result =
        await widget.search(currentSearch, _page + 1, currentGenre, mode);
    _page += 1;
    if (result.isEmpty) {
      _reachedEnd = true;
    }

    _results.addAll(result);

    return _results.length;
  }

  GridSettingsBase _settings() => GridSettingsBase(
        aspectRatio: GridAspectRatio.zeroSeven,
        columns: gridSettings.columns,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  Widget build(BuildContext context) {
    String title(G? genre) {
      if (genre == null) {
        return "";
      }

      return widget.idFromGenre(genre).$2;
    }

    Widget body(BuildContext context) => WrapGridPage<T>(
          provided: widget.generateGlue,
          scaffoldKey: state.scaffoldKey,
          child: GridSkeleton<T>(
            state,
            (context) => GridFrame<T>(
              key: state.gridKey,
              layout: GridSettingsLayoutBehaviour(_settings),
              refreshingStatus: state.refreshingStatus,
              getCell: (i) => _results[i],
              imageViewDescription:
                  ImageViewDescription(imageViewKey: state.imageViewKey),
              functionality: GridFunctionality(
                  loadNext: _loadNext,
                  selectionGlue: GlueProvider.of(context),
                  refresh: AsyncGridRefresh(() {
                    if (_results.isEmpty) {
                      return Future.value(0);
                    }

                    return _load(currentSearch);
                  }),
                  onPressed: OverrideGridOnCellPressBehaviour(
                    onPressed: (context, idx, _) {
                      widget.onPressed(_results[idx]);
                    },
                  ),
                  search: OverrideGridSearchWidget(
                    SearchAndFocus(
                        TextFormField(
                          initialValue: currentSearch,
                          decoration: InputDecoration(
                              hintText:
                                  "${AppLocalizations.of(context)!.searchHint} ${currentGenre == null ? '' : genres == null ? '...' : title(genres?[currentGenre!])}",
                              border: InputBorder.none),
                          focusNode: searchFocus,
                          onFieldSubmitted: (value) {
                            final grid = state.gridKey.currentState;
                            if (grid == null || grid.mutation.isRefreshing) {
                              return;
                            }

                            _load(value);
                          },
                        ),
                        searchFocus),
                  )),
              systemNavigationInsets: widget.viewInsets ??
                  (MediaQuery.viewPaddingOf(context) +
                      const EdgeInsets.only(bottom: 4)),
              mainFocus: state.mainFocus,
              description: GridDescription(
                actions: const [],
                inlineMenuButtonItems: true,
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

                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        changeSystemUiOverlay(context);
                      });

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
                                    .harmonizeWith(
                                        Theme.of(context).primaryColor)
                                    .withOpacity(0.5)
                                : null,
                      ),
                    ),
                  ),
                  if (widget.genres != null)
                    IconButton(
                      onPressed: () {
                        _genreFuture ??= widget.genres
                            ?.call(AnimeSafeMode.safe)
                            .then((value) {
                          genres = value;

                          setState(() {});

                          return value;
                        });

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          showDragHandle: true,
                          builder: (context) {
                            return SafeArea(
                              child: _SearchOptions<I, G>(
                                setCurrentGenre: (g) {
                                  currentGenre = g;

                                  _load(currentSearch);

                                  setState(() {});
                                },
                                initalGenreId: currentGenre,
                                genreFuture: _genreFuture!,
                                idFromGenre: widget.idFromGenre,
                              ),
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.filter_list_outlined,
                          color: currentGenre != null
                              ? Theme.of(context).colorScheme.primary
                              : null),
                    ),
                ],
                titleLines: 2,
                keybindsDescription:
                    AppLocalizations.of(context)!.searchAnimePage,
                gridSeed: state.gridSeed,
              ),
            ),
            canPop: true,
          ),
        );

    return AnimeInfoTheme(
      mode: mode,
      overlayColor: Theme.of(context).colorScheme.background,
      child: Builder(
        builder: (context) {
          return body(context);
        },
      ),
    );
  }
}

class _SearchOptions<I, G> extends StatefulWidget {
  final I? initalGenreId;
  final Future<Map<I, G>> genreFuture;
  final (I, String) Function(G) idFromGenre;

  final void Function(I?) setCurrentGenre;

  const _SearchOptions({
    super.key,
    required this.initalGenreId,
    required this.setCurrentGenre,
    required this.genreFuture,
    required this.idFromGenre,
  });

  @override
  State<_SearchOptions<I, G>> createState() => __SearchOptionsState();
}

class __SearchOptionsState<I, G> extends State<_SearchOptions<I, G>> {
  late I? currentGenre = widget.initalGenreId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.genreFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.animeSearchSearching,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SegmentedButtonGroup<(I, G)>(
                  allowUnselect: true,
                  select: (genre) {
                    currentGenre = genre?.$1;

                    widget.setCurrentGenre(genre?.$1);

                    setState(() {});
                  },
                  selected: currentGenre == null
                      ? null
                      : (currentGenre!, snapshot.data![currentGenre!]!),
                  values: snapshot.data!.entries.map((e) =>
                      SegmentedButtonValue(
                          (e.key, e.value), widget.idFromGenre(e.value).$2)),
                  title: AppLocalizations.of(context)!.animeSearchGenres,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
