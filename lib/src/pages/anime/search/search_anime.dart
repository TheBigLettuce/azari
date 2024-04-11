// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/manga/pinned_manga.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/anime/anime_info_page.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/manga/manga_info_page.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchAnimePage<T extends CellBase, I, G> extends StatefulWidget {
  final I? initalGenreId;
  final String? initalText;
  final AnimeSafeMode explicit;
  final Future<List<T>> Function(String, int, I?, AnimeSafeMode) search;
  final Future<Map<I, G>> Function(AnimeSafeMode) genres;
  final (I, String) Function(G) idFromGenre;
  final Future<void> Function(T) onPressed;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final String info;
  final Uri siteUri;
  final List<GridAction<T>> actions;

  static void launchMangaApi(
    BuildContext context,
    MangaAPI api, {
    SelectionGlue Function([Set<GluePreferences>])? generateGlue,
    String? search,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    MangaId? initalGenreId,
  }) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SearchAnimePage<MangaEntry, MangaId, MangaGenre>(
          generateGlue: generateGlue,
          initalText: search,
          explicit: safeMode,
          actions: [
            GridAction(Icons.push_pin_rounded, (selected) {
              final toDelete = <MangaEntry>[];
              final toAdd = <MangaEntry>[];

              for (final e in selected) {
                if (PinnedManga.exist(e.id.toString(), e.site)) {
                  toDelete.add(e);
                } else {
                  toAdd.add(e);
                }
              }

              PinnedManga.addAll(toAdd
                  .map((e) => PinnedManga(
                        mangaId: e.id.toString(),
                        site: e.site,
                        thumbUrl: e.thumbUrl,
                        title: e.title,
                      ))
                  .toList());

              PinnedManga.deleteAllIds(
                toDelete.map((e) => (e.id, e.site)).toList(),
              );
            }, true),
          ],
          initalGenreId: initalGenreId,
          info: api.site.name,
          siteUri: Uri.https(api.site.browserUrl()),
          idFromGenre: (genre) {
            return (genre.id, genre.name);
          },
          onPressed: (cell) {
            return Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(
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
    AnimeAPI Function(Dio) apiFactory, {
    String? search,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    int? initalGenreId,
  }) {
    final client = Dio();
    final api = apiFactory(client);

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SearchAnimePage<AnimeEntry, int, AnimeGenre>(
          initalText: search,
          explicit: safeMode,
          actions: DiscoverTab.actions(),
          initalGenreId: initalGenreId,
          siteUri: Uri.https(api.site.browserUrl()),
          info: api.site.name,
          idFromGenre: (genre) {
            return (genre.id, genre.title);
          },
          onPressed: (cell) {
            return Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return AnimeInfoPage(
                  id: cell.id,
                  entry: cell,
                  apiFactory: apiFactory,
                );
              },
            ));
          },
          search: api.search,
          genres: api.genres,
        );
      },
    )).then((_) {
      client.close();
    });
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
    this.explicit = AnimeSafeMode.safe,
    required this.info,
    required this.actions,
    required this.siteUri,
  });

  @override
  State<SearchAnimePage<T, I, G>> createState() =>
      _SearchAnimePageState<T, I, G>();
}

class _SearchAnimePageState<T extends CellBase, I, G>
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
      _genreFuture = widget.genres(AnimeSafeMode.safe).then((value) {
        genres = value;

        setState(() {});

        return value;
      }).onError((error, stackTrace) {
        _genreFuture = null;

        setState(() {});

        throw error.toString();
      });
    }

    currentGenre = widget.initalGenreId;
    currentSearch = widget.initalText ?? "";
  }

  @override
  void dispose() {
    watcher.cancel();

    state.dispose();
    searchFocus.dispose();

    super.dispose();
  }

  Future<int> _load() async {
    final mutation = state.gridKey.currentState?.mutation;

    mutation?.isRefreshing = true;
    mutation?.cellCount = 0;

    _results.clear();
    _page = 0;
    _reachedEnd = false;

    final result = await widget.search(currentSearch, 0, currentGenre, mode);

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

    Widget body(BuildContext context) => WrapGridPage(
          addScaffold: widget.generateGlue == null,
          provided: widget.generateGlue,
          child: GridSkeleton<T>(
            state,
            (context) => GridFrame<T>(
              key: state.gridKey,
              layout: GridSettingsLayoutBehaviour(_settings),
              getCell: (i) => _results[i],
              functionality: GridFunctionality(
                  onError: (error) {
                    return FilledButton.icon(
                      onPressed: () {
                        launchUrl(
                          widget.siteUri,
                          mode: LaunchMode.inAppBrowserView,
                        );
                      },
                      label: Text(AppLocalizations.of(context)!.openInBrowser),
                      icon: const Icon(Icons.public),
                    );
                  },
                  loadNext: _loadNext,
                  selectionGlue: GlueProvider.generateOf(context)(),
                  refreshingStatus: state.refreshingStatus,
                  refresh: AsyncGridRefresh(_load),
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

                          currentSearch = value;

                          _load();
                        },
                      ),
                      searchFocus,
                    ),
                  )),
              mainFocus: state.mainFocus,
              description: GridDescription(
                actions: widget.actions,
                inlineMenuButtonItems: true,
                menuButtonItems: [
                  SafetyButton(
                      mode: mode,
                      set: (m) {
                        mode = m;

                        if (_results.isNotEmpty) {
                          _load();
                        }

                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          changeSystemUiOverlay(context);
                        });

                        setState(() {});
                      }),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        showDragHandle: true,
                        builder: (context) {
                          return SafeArea(
                            child: SearchOptions<I, G>(
                              info: widget.info,
                              setCurrentGenre: (g) {
                                currentGenre = g;

                                _load();

                                setState(() {});
                              },
                              initalGenreId: currentGenre,
                              genreFuture: () {
                                if (_genreFuture != null) {
                                  return _genreFuture!;
                                }

                                return widget
                                    .genres(AnimeSafeMode.safe)
                                    .then((value) {
                                  genres = value;

                                  _genreFuture = Future.value(value);

                                  setState(() {});

                                  return value;
                                });
                              },
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

class SafetyButton extends StatelessWidget {
  final AnimeSafeMode mode;
  final void Function(AnimeSafeMode) set;

  const SafetyButton({
    super.key,
    required this.mode,
    required this.set,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final newMode = switch (mode) {
          AnimeSafeMode.safe => AnimeSafeMode.ecchi,
          AnimeSafeMode.h => AnimeSafeMode.safe,
          AnimeSafeMode.ecchi => AnimeSafeMode.h,
        };

        set(newMode);
      },
      child: Text(
        mode == AnimeSafeMode.ecchi
            ? "E"
            : mode == AnimeSafeMode.h
                ? "H"
                : "S",
        style: TextStyle(
          color: mode == AnimeSafeMode.h
              ? Colors.red.harmonizeWith(Theme.of(context).primaryColor)
              : mode == AnimeSafeMode.ecchi
                  ? Colors.red
                      .harmonizeWith(Theme.of(context).primaryColor)
                      .withOpacity(0.5)
                  : null,
        ),
      ),
    );
  }
}

class SearchOptions<I, G> extends StatefulWidget {
  final I? initalGenreId;
  final Future<Map<I, G>> Function() genreFuture;
  final (I, String) Function(G) idFromGenre;
  final String info;
  final Widget? header;

  final void Function(I?) setCurrentGenre;

  const SearchOptions({
    super.key,
    required this.initalGenreId,
    required this.setCurrentGenre,
    required this.genreFuture,
    required this.idFromGenre,
    required this.info,
    this.header,
  });

  @override
  State<SearchOptions<I, G>> createState() => _SearchOptionsState();
}

class _SearchOptionsState<I, G> extends State<SearchOptions<I, G>> {
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
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
              if (widget.header != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: widget.header!,
                ),
              WrapFutureRestartable<Map<I, G>>(
                builder: (context, value) {
                  return SegmentedButtonGroup<(I, G)>(
                    allowUnselect: true,
                    select: (genre) {
                      currentGenre = genre?.$1;

                      widget.setCurrentGenre(genre?.$1);

                      setState(() {});
                    },
                    enableFilter: true,
                    selected: currentGenre == null
                        ? null
                        : (currentGenre!, value[currentGenre!]!),
                    values: value.entries.map((e) => SegmentedButtonValue(
                        (e.key, e.value), widget.idFromGenre(e.value).$2)),
                    title: AppLocalizations.of(context)!.animeSearchGenres,
                  );
                },
                newStatus: widget.genreFuture,
                bottomSheetVariant: true,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                    const Padding(padding: EdgeInsets.only(right: 4)),
                    Text(
                      AppLocalizations.of(context)!.usingApi(widget.info),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
