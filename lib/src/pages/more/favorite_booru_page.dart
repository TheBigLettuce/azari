// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/booru_post_functionality_mixin.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cached_db_values.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class FavoriteBooruPage extends StatelessWidget {
  const FavoriteBooruPage({
    super.key,
    required this.state,
    required this.conroller,
    this.asSliver = true,
    this.wrapGridPage = false,
    required this.db,
  });

  final FavoriteBooruPageState state;
  final ScrollController conroller;
  final bool asSliver;
  final bool wrapGridPage;

  final DbConn db;

  void _onPressed(
    BuildContext context,
    Booru booru,
    String t,
    SafeMode? safeMode,
  ) {
    Navigator.pop(context);

    state.searchTextController.text = t;
    // state.search.performSearch(t);
  }

  GridFrame<FavoritePostData> child(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return GridFrame<FavoritePostData>(
      key: state.state.gridKey,
      slivers: [
        if (state.segments != null)
          SegmentLayout<FavoritePostData>(
            getCell: state.filter.forIdxUnsafe,
            progress: state.filter.progress,
            localizations: l8n,
            segments: Segments(
              l8n.segmentsUncategorized,
              injectedLabel: "",
              caps: SegmentCapability.empty(),
              hidePinnedIcon: true,
              prebuiltSegments: state.segments,
            ),
            suggestionPrefix: const [],
            gridSeed: state.state.gridSeed,
            storage: state.filter.backingStorage,
          )
        else
          CurrentGridSettingsLayout<FavoritePostData>(
            source: state.filter.backingStorage,
            progress: state.filter.progress,
            gridSeed: state.state.gridSeed,
          ),
      ],
      overrideController: conroller,
      functionality: GridFunctionality(
        search: asSliver
            ? const EmptyGridSearchWidget()
            : OverrideGridSearchWidget(
                SearchAndFocus(
                  FilteringSearchWidget(
                    hint: null,
                    filter: state.filter,
                    textController: state.searchTextController,
                    localTagDictionary: db.localTagDictionary,
                    focusNode: state.searchFocus,
                  ),
                  // state.search.searchWidget(
                  //   context,
                  //   count: state.state.refreshingStatus.mutation.cellCount,
                  // ),
                  state.searchFocus,
                ),
              ),
        registerNotifiers: (child) => OnBooruTagPressed(
          onPressed: _onPressed,
          child: child,
        ),
        selectionGlue: GlueProvider.generateOf(context)(),
        download: state.download,
        source: state.filter,
      ),
      mainFocus: state.state.mainFocus,
      description: GridDescription(
        actions: state.gridActions(),
        // settingsButton: !asSliver ? state.gridSettingsButton() : null,
        showAppBar: !asSliver,
        asSliver: asSliver,
        keybindsDescription: l8n.favoritesLabel,
        pageName: l8n.favoritesLabel,
        gridSeed: state.state.gridSeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      sliver: true,
      watch: state.gridSettings.watch,
      child: wrapGridPage
          ? WrapGridPage(
              child: GridSkeleton<FavoritePostData>(
                state.state,
                child,
                canPop: true,
              ),
            )
          : child(context),
    );
  }
}

class FavoriteBooruStateHolder extends StatefulWidget
    with DbConnHandle<DbConn> {
  const FavoriteBooruStateHolder({
    super.key,
    required this.build,
    required this.db,
  });

  final Widget Function(BuildContext context, FavoriteBooruPageState state)
      build;

  @override
  final DbConn db;

  @override
  State<FavoriteBooruStateHolder> createState() =>
      _FavoriteBooruStateHolderState();
}

class _FavoriteBooruStateHolderState extends State<FavoriteBooruStateHolder>
    with FavoriteBooruPageState<FavoriteBooruStateHolder> {
  @override
  void initState() {
    super.initState();

    initFavoriteBooruState();
  }

  @override
  void dispose() {
    disposeFavoriteBooruState();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, this);
  }
}

class _FilterEnumSegmentKey implements SegmentKey {
  const _FilterEnumSegmentKey(this.mode);

  final FilteringMode mode;

  @override
  String translatedString(AppLocalizations localizations) =>
      mode.translatedString(localizations);

  @override
  int get hashCode => mode.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _FilterEnumSegmentKey) {
      return false;
    }

    return other.mode == mode;
  }
}

class _StringSegmentKey implements SegmentKey {
  const _StringSegmentKey(this.string);

  final String string;

  @override
  String translatedString(AppLocalizations l8n) => string;

  @override
  int get hashCode => string.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _StringSegmentKey) {
      return false;
    }

    return other.string == string;
  }
}

mixin FavoriteBooruPageState<T extends DbConnHandle<DbConn>> on State<T> {
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.favoritePosts;

  // late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<MiscSettingsData?> miscSettingsWatcher;

  MiscSettingsData miscSettings = MiscSettingsService.db().current;

  Map<SegmentKey, int>? segments;

  bool segmented = false;

  // final valuesCache = PostValuesCache();

  final searchFocus = FocusNode();
  final searchTextController = TextEditingController();

  // late final loader = LinearIsarLoader<FavoritePostData>(
  //     FavoriteBooruSchema, Dbs.g.main, (offset, limit, s, sort, mode) {
  //   if (mode == FilteringMode.group) {
  //     if (s.isEmpty) {
  //       return Dbs.g.main.favoriteBoorus
  //           .where()
  //           .sortByGroupDesc()
  //           .thenByCreatedAtDesc()
  //           .offset(offset)
  //           .limit(limit)
  //           .findAllSync();
  //     }

  //     return Dbs.g.main.favoriteBoorus
  //         .filter()
  //         .groupContains(s)
  //         .sortByGroupDesc()
  //         .thenByCreatedAtDesc()
  //         .offset(offset)
  //         .limit(limit)
  //         .findAllSync();
  //   } else if (mode == FilteringMode.same) {
  //     return Dbs.g.main.favoriteBoorus
  //         .filter()
  //         // ignore: inference_failure_on_function_invocation
  //         .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
  //         .sortByMd5()
  //         .thenByCreatedAtDesc()
  //         .offset(offset)
  //         .limit(limit)
  //         .findAllSync();
  //   }

  //   return Dbs.g.main.favoriteBoorus
  //       .filter()
  //       // ignore: inference_failure_on_function_invocation
  //       .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
  //       .sortByCreatedAtDesc()
  //       .offset(offset)
  //       .limit(limit)
  //       .findAllSync();
  // })

  Iterable<FavoritePostData> _collector(
    Map<String, Set<(int, Booru)>>? data,
  ) sync* {
    for (final ids in data!.values) {
      for (final i in ids) {
        yield favoritePosts.forIdxUnsafe((i.$1, i.$2));
      }
    }
  }

  static (Iterable<T>, dynamic) sameFavorites<T extends PostBase>(
    Iterable<T> cells,
    dynamic data_,
    bool end,
    Iterable<T> Function(Map<String, Set<(int, Booru)>>? data) collect,
  ) {
    final data = (data_ as Map<String, Set<(int, Booru)>>?) ?? {};

    T? prevCell;
    for (final e in cells) {
      if (prevCell != null) {
        if (prevCell.md5 == e.md5) {
          final prev = data[e.md5] ?? {};

          data[e.md5] = {...prev, (e.id, e.booru)};
        }
      }

      prevCell = e;
    }

    if (end) {
      return (collect(data), null);
    }

    return (const [], data);
  }

  late final state = GridSkeletonState<FavoritePostData>();

  late final ChainedFilterResourceSource<(int, Booru), FavoritePostData> filter;

  void disposeFavoriteBooruState() {
    // valuesCache.clear();
    miscSettingsWatcher.cancel();
    // favoritesWatcher.cancel();
    filter.destroy();

    searchFocus.dispose();
    searchTextController.dispose();

    state.dispose();
    // search.dispose();
  }

  void initFavoriteBooruState() {
    filter = ChainedFilterResourceSource(
      favoritePosts,
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        if (filteringMode == FilteringMode.group) {
          segments = segments ?? {};

          for (final e in cells) {
            if (e.group != null) {
              segments![_StringSegmentKey(e.group!)] =
                  (segments![_StringSegmentKey(e.group!)] ?? 0) + 1;

              continue;
            }

            segments![const _FilterEnumSegmentKey(FilteringMode.ungrouped)] =
                (segments![const _FilterEnumSegmentKey(
                          FilteringMode.ungrouped,
                        )] ??
                        0) +
                    1;
          }
        } else {
          segments = null;
        }

        return switch (filteringMode) {
          FilteringMode.same => sameFavorites(cells, data, end, _collector),
          FilteringMode.tag => (
              searchTextController.text.isEmpty
                  ? cells
                  : cells
                      .where((e) => e.tags.contains(searchTextController.text)),
              data
            ),
          FilteringMode.ungrouped => (
              cells.where(
                (element) => element.group == null || element.group!.isEmpty,
              ),
              data
            ),
          FilteringMode.gif => (
              cells.where((element) => element.type == PostContentType.gif),
              data
            ),
          FilteringMode.video => (
              cells.where((element) => element.type == PostContentType.video),
              data
            ),
          FilteringMode() => (cells, data)
        };
      },
      ListStorage(),
      prefilter: () {
        segments = null;
        if (filter.filteringMode == FilteringMode.group) {
          segmented = true;
        } else {
          segmented = false;
        }

        MiscSettingsService.db()
            .current
            .copy(favoritesPageMode: filter.filteringMode)
            .save();
      },
      allowedFilteringModes: const {
        FilteringMode.tag,
        FilteringMode.group,
        FilteringMode.ungrouped,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.same,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.size,
      },
      initialFilteringMode: miscSettings.favoritesPageMode,
      initialSortingMode: SortingMode.none,
    );

    filter.clearRefresh();

    // search.setFilteringMode(miscSettings.favoritesPageMode);
    // search.setLocalTagCompleteF((string) {
    //   final result = Dbs.g.main.localTagDictionarys
    //       .filter()
    //       .tagContains(string)
    //       .sortByFrequencyDesc()
    //       .limit(10)
    //       .findAllSync();

    //   return Future.value(
    //     result.map((e) => BooruTag(e.tag, e.frequency)).toList(),
    //   );
    // });

    // setState(() {});

    miscSettingsWatcher = miscSettings.s.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    // favoritesWatcher = favoritePosts.watch((event) {
    // filter.clearRefresh();
    // search.performSearch(search.searchTextController.text, true);

    // state.gridKey.currentState?.selection.reset();
    // });

    filter.clearRefresh();
  }

  void download(int i) => filter.forIdxUnsafe(i).download(context);

  GridAction<FavoritePostData> _groupButton(BuildContext context) {
    return FavoritesActions.addToGroup(
      context,
      (selected) {
        final g = selected.first.group;

        for (final e in selected.skip(1)) {
          if (g != e.group) {
            return null;
          }
        }

        return g;
      },
      (selected, value, toPin) {
        for (final e in selected) {
          e.group = value.isEmpty ? null : value;
        }

        favoritePosts.addRemove(selected);

        Navigator.of(context, rootNavigator: true).pop();
      },
      false,
    );
  }

  List<GridAction<FavoritePostData>> gridActions() {
    return [
      BooruGridActions.download(context, state.settings.selectedBooru),
      _groupButton(context),
      BooruGridActions.favorites(
        context,
        favoritePosts,
        showDeleteSnackbar: true,
      ),
    ];
  }
}
