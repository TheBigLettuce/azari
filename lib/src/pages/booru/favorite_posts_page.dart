// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as booru_actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:flutter/material.dart";

class FavoritePostsPage extends StatefulWidget {
  const FavoritePostsPage({
    super.key,
    required this.rootNavigatorPop,
    required this.gridSettings,
    required this.favoritePosts,
    required this.settingsService,
    required this.downloadManager,
    required this.localTags,
    required this.miscSettingsService,
  });

  final void Function(bool)? rootNavigatorPop;

  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;
  final MiscSettingsService? miscSettingsService;

  final GridSettingsService gridSettings;
  final FavoritePostSourceService favoritePosts;

  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) =>
      db.get<GridSettingsService>() != null &&
      db.get<FavoritePostSourceService>() != null;

  @override
  State<FavoritePostsPage> createState() => _FavoritePostsPageState();
}

class _FavoritePostsPageState extends State<FavoritePostsPage>
    with CommonGridData<Post, FavoritePostsPage> {
  MiscSettingsService? get miscSettingsService => widget.miscSettingsService;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  FavoritePostSourceService get favoritePosts => widget.favoritePosts;
  WatchableGridSettingsData get gridSettings =>
      widget.gridSettings.favoritePosts;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final StreamSubscription<void> _safeModeWatcher;

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  late final client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
  late final BooruAPI api;

  late final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  late final SafeModeState safeModeState;

  Iterable<FavoritePost> _filterTag(Iterable<FavoritePost> cells) {
    final searchText = searchTextController.text.trim();
    if (searchText.isEmpty) {
      return cells;
    }

    final tags = searchText.split(" ");

    return cells.where((e) {
      final flags = tags.map((_) => false).toList();

      for (final (index, tagsTo) in tags.indexed) {
        for (final tag in e.tags) {
          if (tag.startsWith(tagsTo)) {
            flags[index] = true;
            break;
          }
        }
      }

      return flags.fold(true, (v, e1) => v & e1);
    });
  }

  Iterable<FavoritePost> _filterStars(
    Iterable<FavoritePost> cells,
    FilteringMode mode,
  ) {
    return cells.where(
      (e) =>
          safeModeState.current.inLevel(e.rating.asSafeMode) &&
          (mode.toStars == e.stars),
    );
  }

  @override
  void initState() {
    super.initState();

    safeModeState = SafeModeState(settings.safeMode);

    api = BooruAPI.fromEnum(settings.selectedBooru, client);

    filter = ChainedFilterResourceSource(
      ResourceSource.external(
        favoritePosts.cache,
        trySorted: (sort) {
          if (sort == SortingMode.none) {
            return favoritePosts.cache;
          }

          final values = favoritePosts.cache.toList()
            ..sort((e1, e2) {
              return switch (sort) {
                SortingMode.none || SortingMode.size => e2.id.compareTo(e1.id),
                SortingMode.rating => e1.rating.asSafeMode.index
                    .compareTo(e2.rating.asSafeMode.index),
                SortingMode.score => e1.score.compareTo(e2.score),
                SortingMode.stars =>
                  e1.stars.asNumber.compareTo(e2.stars.asNumber),
              };
            });

          return values;
        },
      ),
      ListStorage(reverse: true),
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.fiveStars ||
          FilteringMode.fourHalfStars ||
          FilteringMode.fourStars ||
          FilteringMode.threeHalfStars ||
          FilteringMode.threeStars ||
          FilteringMode.twoHalfStars ||
          FilteringMode.twoStars ||
          FilteringMode.oneHalfStars ||
          FilteringMode.oneStars ||
          FilteringMode.zeroHalfStars ||
          FilteringMode.zeroStars =>
            (
              _filterTag(
                _filterStars(cells, filteringMode),
              ),
              data,
            ),
          FilteringMode.same => sameFavorites(
              cells,
              data,
              end,
              _collector,
              safeModeState.current,
            ),
          FilteringMode.tag => (
              _filterTag(
                cells.where(
                  (e) => safeModeState.current.inLevel(e.rating.asSafeMode),
                ),
              ),
              data
            ),
          FilteringMode.gif => (
              _filterTag(
                cells.where(
                  (element) =>
                      element.type == PostContentType.gif &&
                      safeModeState.current.inLevel(element.rating.asSafeMode),
                ),
              ),
              data
            ),
          FilteringMode.video => (
              _filterTag(
                cells.where(
                  (element) =>
                      element.type == PostContentType.video &&
                      safeModeState.current.inLevel(element.rating.asSafeMode),
                ),
              ),
              data
            ),
          FilteringMode() => (
              _filterTag(
                cells.where(
                  (e) => safeModeState.current.inLevel(e.rating.asSafeMode),
                ),
              ),
              data
            )
        };
      },
      prefilter: () {
        miscSettingsService?.current
            .copy(favoritesPageMode: filter.filteringMode)
            .maybeSave();
      },
      allowedFilteringModes: const {
        FilteringMode.tag,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.same,
        FilteringMode.fiveStars,
        FilteringMode.fourHalfStars,
        FilteringMode.fourStars,
        FilteringMode.threeHalfStars,
        FilteringMode.threeStars,
        FilteringMode.twoHalfStars,
        FilteringMode.twoStars,
        FilteringMode.oneHalfStars,
        FilteringMode.oneStars,
        FilteringMode.zeroHalfStars,
        FilteringMode.zeroStars,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.rating,
        SortingMode.score,
        SortingMode.stars,
      },
      initialFilteringMode:
          miscSettingsService?.current.favoritesPageMode ?? FilteringMode.tag,
      initialSortingMode: SortingMode.none,
    );

    filter.clearRefresh();

    _safeModeWatcher = safeModeState.events.listen((_) {
      filter.clearRefresh();
    });
  }

  @override
  void dispose() {
    safeModeState.dispose();
    client.close(force: true);
    _safeModeWatcher.cancel();
    filter.destroy();

    searchFocus.dispose();
    searchTextController.dispose();

    super.dispose();
  }

  Iterable<FavoritePost> _collector(
    Map<String, Set<(int, Booru)>>? data,
  ) sync* {
    for (final ids in data!.values) {
      for (final i in ids) {
        yield favoritePosts.cache.get((i.$1, i.$2))!;
      }
    }
  }

  // static (Iterable<T>, dynamic) stars<T extends PostBase>(
  //   Iterable<T> cells,
  //   dynamic data_,
  //   bool end,
  //   Iterable<T> Function(Map<String, Set<(int, Booru)>>? data) collect,
  //   SafeMode currentSafeMode,
  // ) {

  // }

  static (Iterable<T>, dynamic) sameFavorites<T extends PostBase>(
    Iterable<T> cells,
    dynamic data_,
    bool end,
    Iterable<T> Function(Map<String, Set<(int, Booru)>>? data) collect,
    SafeMode currentSafeMode,
  ) {
    final data = (data_ as Map<String, Set<(int, Booru)>>?) ?? {};

    T? prevCell;
    for (final e in cells) {
      if (!currentSafeMode.inLevel(e.rating.asSafeMode)) {
        continue;
      }

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

  void _onPressed(
    BuildContext context,
    Booru booru,
    String t,
    SafeMode? safeMode,
  ) {
    ExitOnPressRoute.maybeExitOf(context);

    searchTextController.text = t;
    filter.filteringMode = FilteringMode.tag;

    if (safeMode != null) {
      safeModeState.setCurrent(safeMode);
    }

    gridKey.currentState?.tryScrollUp();
  }

  void _download(int i) => filter.forIdxUnsafe(i).download(
        downloadManager: downloadManager!,
        localTags: localTags!,
        settingsService: settingsService,
      );

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return GridPopScope(
      searchTextController: searchTextController,
      filter: filter,
      rootNavigatorPop: widget.rootNavigatorPop,
      child: GridConfiguration(
        watch: gridSettings.watch,
        child: GridFrame<FavoritePost>(
          key: gridKey,
          slivers: [
            _SearchBarWidget(
              api: api,
              filter: filter,
              safeModeState: safeModeState,
              searchTextController: searchTextController,
              searchFocus: searchFocus,
              settingsService: settingsService,
            ),
            Builder(
              builder: (context) {
                final padding = MediaQuery.systemGestureInsetsOf(context);

                return SliverPadding(
                  padding: EdgeInsets.only(
                    left: padding.left * 0.2,
                    right: padding.right * 0.2,
                  ),
                  sliver: CurrentGridSettingsLayout<FavoritePost>(
                    source: filter.backingStorage,
                    progress: filter.progress,
                    gridSeed: gridSeed,
                  ),
                );
              },
            ),
          ],
          functionality: GridFunctionality(
            scrollUpOn: [(NavigationButtonEvents.maybeOf(context)!, null)],
            selectionActions: SelectionActions.of(context),
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
            onEmptySource: EmptyWidgetBackground(
              subtitle: l10n.emptyFavoritedPosts,
            ),
            search: PageNameSearchWidget(
              leading: IconButton(
                onPressed: _openDrawer,
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            settingsButton: GridSettingsButton.fromWatchable(
              gridSettings,
              header: SafeModeSegment(state: safeModeState),
              buildHideName: false,
              localizeHideNames: (_) => "",
            ),
            registerNotifiers: (child) => OnBooruTagPressed(
              onPressed: _onPressed,
              child: filter.inject(child),
            ),
            download:
                downloadManager != null && localTags != null ? _download : null,
            source: filter,
          ),
          description: GridDescription(
            actions: <GridAction<FavoritePost>>[
              if (downloadManager != null && localTags != null)
                booru_actions.downloadFavoritePost(
                  context,
                  settings.selectedBooru,
                  null,
                  downloadManager: downloadManager!,
                  localTags: localTags!,
                  settingsService: settingsService,
                ),
              booru_actions.favorites<FavoritePost>(
                context,
                favoritePosts,
                showDeleteSnackbar: true,
              ),
            ],
            pullToRefresh: false,
            pageName: l10n.favoritesLabel,
            gridSeed: gridSeed,
          ),
        ),
      ),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  const _SearchBarWidget({
    // super.key,
    required this.api,
    required this.filter,
    required this.safeModeState,
    required this.searchTextController,
    required this.searchFocus,
    required this.settingsService,
  });

  final TextEditingController searchTextController;
  final FocusNode searchFocus;

  final BooruAPI api;

  final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  final SafeModeState safeModeState;

  final SettingsService settingsService;

  void launchGrid(BuildContext context) {
    if (searchTextController.text.isNotEmpty) {
      context.openSafeModeDialog(settingsService, (safeMode) {
        BooruRestoredPage.open(
          context,
          booru: api.booru,
          tags: searchTextController.text.trim(),
          rootNavigator: false,
          saveSelectedPage: (_) {},
          overrideSafeMode: safeMode,
          // wrapScaffold: true,
        );
      });
    }
  }

  void clear() {
    searchTextController.text = "";
    filter.clearRefresh();
    searchFocus.unfocus();
  }

  void onChanged(String? _) {
    filter.clearRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    const padding = EdgeInsets.only(
      right: 16,
      left: 16,
      top: 4,
      bottom: 8,
    );

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: padding,
          child: SearchBarAutocompleteWrapper(
            search: BarSearchWidget(
              onChanged: onChanged,
              complete: api.searchTag,
              textEditingController: searchTextController,
            ),
            searchFocus: searchFocus,
            child: (
              context,
              controller,
              focus,
              onSubmitted,
            ) =>
                SearchBar(
              onSubmitted: (str) {
                onSubmitted();
                filter.clearRefresh();
              },
              onTapOutside: (event) => focus.unfocus(),
              elevation: const WidgetStatePropertyAll(0),
              focusNode: focus,
              controller: controller,
              onChanged: onChanged,
              hintText: l10n.filterHint,
              leading: IconButton(
                onPressed: () => launchGrid(context),
                icon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              trailing: [
                ChainedFilterIcon(
                  filter: filter,
                  controller: searchTextController,
                  complete: api.searchTag,
                  focusNode: searchFocus,
                ),
                IconButton(
                  onPressed: clear,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
