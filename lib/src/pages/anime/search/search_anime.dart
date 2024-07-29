// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/anime/info_base/anime_info_theme.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:url_launcher/url_launcher.dart";

class SearchAnimePage<T extends CellBase, I, G> extends StatefulWidget {
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

  // static void launchMangaApi(
  //   BuildContext context,
  //   MangaAPI api, {
  //   SelectionGlue Function([Set<GluePreferences>])? generateGlue,
  //   String? search,
  //   AnimeSafeMode safeMode = AnimeSafeMode.safe,
  //   MangaId? initalGenreId,
  // }) {
  //   final db = DatabaseConnectionNotifier.of(context);

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute<void>(
  //       builder: (context) {
  //         return SearchAnimePage<MangaEntry, MangaId, MangaGenre>(
  //           generateGlue: generateGlue,
  //           initalText: search,
  //           explicit: safeMode,
  //           actions: [
  //             GridAction(
  //               Icons.push_pin_rounded,
  //               (selected) {
  //                 final toDelete = <MangaEntry>[];
  //                 final toAdd = <MangaEntry>[];

  //                 for (final e in selected) {
  //                   if (db.pinnedManga.exist(e.id.toString(), e.site)) {
  //                     toDelete.add(e);
  //                   } else {
  //                     toAdd.add(e);
  //                   }
  //                 }

  //                 db.pinnedManga.addAll(toAdd);

  //                 db.pinnedManga.deleteAll(
  //                   toDelete.map((e) => (e.id, e.site)).toList(),
  //                 );
  //               },
  //               true,
  //             ),
  //           ],
  //           initalGenreId: initalGenreId,
  //           info: api.site.name,
  //           siteUri: Uri.https(api.site.browserUrl()),
  //           idFromGenre: (genre) {
  //             return (genre.id, genre.name);
  //           },
  //           onPressed: (cell) {
  //             return Navigator.of(context, rootNavigator: true).push(
  //               MaterialPageRoute(
  //                 builder: (context) {
  //                   return MangaInfoPage(
  //                     id: cell.id,
  //                     entry: cell,
  //                     api: api,
  //                     db: db,
  //                   );
  //                 },
  //               ),
  //             );
  //           },
  //           search: (text, page, id, safeMode) {
  //             return api.search(
  //               text,
  //               page: page,
  //               includesTag: id != null ? [id] : null,
  //               safeMode: safeMode,
  //               count: 30,
  //             );
  //           },
  //           genres: (safeMode) {
  //             return api.tags().then((value) {
  //               final m = <MangaId, MangaGenre>{};

  //               for (final e in value) {
  //                 m[e.id] = e;
  //               }

  //               return m;
  //             });
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

  static void launchAnimeApi(
    BuildContext context,
    AnimeAPI Function(Dio) apiFactory, {
    String? search,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    int? initalGenreId,
  }) {
    final client = Dio();
    final api = apiFactory(client);
    final db = DatabaseConnectionNotifier.of(context);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return SearchAnimePage<AnimeEntryData, int, AnimeGenre>(
            initalText: search,
            explicit: safeMode,
            actions: DiscoverTab.actions(db.savedAnimeEntries, db.watchedAnime),
            initalGenreId: initalGenreId,
            siteUri: Uri.https(api.site.browserUrl()),
            info: api.site.name,
            idFromGenre: (genre) {
              return (genre.id, genre.title);
            },
            onPressed: (cell) {
              return Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return AnimeInfoPage(
                      id: cell.id,
                      entry: cell,
                      apiFactory: apiFactory,
                      db: db,
                    );
                  },
                ),
              );
            },
            search: api.search,
            genres: api.genres,
          );
        },
      ),
    ).then((_) {
      client.close();
    });
  }

  @override
  State<SearchAnimePage<T, I, G>> createState() =>
      _SearchAnimePageState<T, I, G>();
}

class _SearchAnimePageState<T extends CellBase, I, G>
    extends State<SearchAnimePage<T, I, G>> {
  late final source = GenericListSource<T>(
    () {
      _page = 0;

      return widget.search(currentSearch, 0, currentGenre, mode);
    },
    next: () =>
        widget.search(currentSearch, _page + 1, currentGenre, mode).then((l) {
      _page += 1;

      return l;
    }),
  );

  late final state = GridSkeletonState<T>();
  late AnimeSafeMode mode = widget.explicit;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    aspectRatio: GridAspectRatio.zeroSeven,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
    hideName: false,
  );

  Future<Map<I, G>>? _genreFuture;
  Map<I, G>? genres;

  int _page = 0;

  String currentSearch = "";
  I? currentGenre;

  @override
  void initState() {
    super.initState();

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
    source.destroy();
    gridSettings.cancel();

    state.dispose();

    super.dispose();
  }

  String title(G? genre) {
    if (genre == null) {
      return "";
    }

    return widget.idFromGenre(genre).$2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: AnimeInfoTheme(
        mode: mode,
        child: Builder(
          builder: (context) {
            return WrapGridPage(
              addScaffold: widget.generateGlue == null,
              provided: widget.generateGlue,
              child: GridPopScope(
                searchTextController: null,
                filter: null,
                child: Builder(
                  builder: (context) => GridFrame<T>(
                    key: state.gridKey,
                    slivers: [
                      CurrentGridSettingsLayout<T>(
                        source: source.backingStorage,
                        progress: source.progress,
                        gridSeed: state.gridSeed,
                        buildEmpty: (e) => EmptyWidgetWithButton(
                          error: e,
                          buttonText: l10n.openInBrowser,
                          onPressed: () {
                            launchUrl(
                              widget.siteUri,
                              mode: LaunchMode.inAppBrowserView,
                            );
                          },
                        ),
                      ),
                    ],
                    functionality: GridFunctionality(
                      selectionGlue: GlueProvider.generateOf(context)(),
                      source: source,
                      search: BarSearchWidget(
                        onChange: null,
                        onSubmitted: (str) {
                          currentSearch = str ?? "";
                          source.clearRefresh();
                        },
                        trailingItems: [
                          SafetyButton(
                            mode: mode,
                            set: (m) {
                              mode = m;

                              if (source.backingStorage.isNotEmpty) {
                                source.clearRefresh();
                              }

                              setState(() {});
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet<void>(
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

                                        source.clearRefresh();

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
                            icon: _FilteringIcon(
                              progress: source.progress,
                              color: currentGenre != null
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    description: GridDescription(
                      animationsOnSourceWatch: false,
                      actions: widget.actions,
                      keybindsDescription: l10n.searchAnimePage,
                      gridSeed: state.gridSeed,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilteringIcon extends StatefulWidget {
  const _FilteringIcon({
    // super.key,
    required this.color,
    required this.progress,
  });

  final Color? color;
  final RefreshingProgress progress;

  @override
  State<_FilteringIcon> createState() => __FilteringIconState();
}

class __FilteringIconState extends State<_FilteringIcon> {
  late final StreamSubscription<bool> subscription;

  @override
  void initState() {
    super.initState();

    subscription = widget.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.progress.inRefreshing
        ? const Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
        : Icon(
            Icons.filter_list_outlined,
            color: widget.color,
          );
  }
}

class SafetyButton extends StatelessWidget {
  const SafetyButton({
    super.key,
    required this.mode,
    required this.set,
  });
  final AnimeSafeMode mode;
  final void Function(AnimeSafeMode) set;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              ? Colors.red.harmonizeWith(colorScheme.primary)
              : mode == AnimeSafeMode.ecchi
                  ? Colors.red
                      .harmonizeWith(colorScheme.primary)
                      .withOpacity(0.5)
                  : null,
        ),
      ),
    );
  }
}

class SearchOptions<I, G> extends StatefulWidget {
  const SearchOptions({
    super.key,
    required this.initalGenreId,
    required this.setCurrentGenre,
    required this.genreFuture,
    required this.idFromGenre,
    required this.info,
    this.header,
  });
  final I? initalGenreId;
  final Future<Map<I, G>> Function() genreFuture;
  final (I, String) Function(G) idFromGenre;
  final String info;
  final Widget? header;

  final void Function(I?) setCurrentGenre;

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                l10n.animeSearchSearching,
                style: theme.textTheme.titleLarge,
              ),
              if (widget.header != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: widget.header,
                ),
              WrapFutureRestartable<Map<I, G>>(
                builder: (context, value) {
                  return SegmentedButtonGroup<(I, G)>(
                    variant: SegmentedButtonVariant.chip,
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
                    values: value.entries.map(
                      (e) => SegmentedButtonValue(
                        (e.key, e.value),
                        widget.idFromGenre(e.value).$2,
                      ),
                    ),
                    title: l10n.animeSearchGenres,
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
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const Padding(padding: EdgeInsets.only(right: 4)),
                    Text(
                      l10n.usingApi(widget.info),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
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
