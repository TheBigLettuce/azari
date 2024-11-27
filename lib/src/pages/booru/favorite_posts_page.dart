// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as booru_actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";

class FavoritePostsPage extends StatefulWidget with DbConnHandle<DbConn> {
  const FavoritePostsPage({
    super.key,
    required this.db,
    required this.rootNavigatorPop,
  });

  final void Function(bool)? rootNavigatorPop;

  @override
  final DbConn db;

  @override
  State<FavoritePostsPage> createState() => _FavoritePostsPageState();
}

class _FavoritePostsPageState extends State<FavoritePostsPage> {
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.favoritePosts;

  late final StreamSubscription<SettingsData?> settingsWatcher;

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  late final state = GridSkeletonState<FavoritePost>();
  late final client =
      BooruAPI.defaultClientForBooru(state.settings.selectedBooru);
  late final BooruAPI api;

  late final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(state.settings.selectedBooru, client);

    filter = ChainedFilterResourceSource(
      favoritePosts,
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.same => sameFavorites(
              cells,
              data,
              end,
              _collector,
              state.settings.safeMode,
            ),
          FilteringMode.tag => (
              searchTextController.text.isEmpty
                  ? cells.where(
                      (e) =>
                          state.settings.safeMode.inLevel(e.rating.asSafeMode),
                    )
                  : cells.where(
                      (e) =>
                          e.tags.contains(searchTextController.text) &&
                          state.settings.safeMode.inLevel(e.rating.asSafeMode),
                    ),
              data
            ),
          FilteringMode.gif => (
              cells.where(
                (element) =>
                    element.type == PostContentType.gif &&
                    state.settings.safeMode.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode.video => (
              cells.where(
                (element) =>
                    element.type == PostContentType.video &&
                    state.settings.safeMode.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode() => (
              cells.where(
                (e) => state.settings.safeMode.inLevel(e.rating.asSafeMode),
              ),
              data
            )
        };
      },
      ListStorage(reverse: true),
      prefilter: () {
        MiscSettingsService.db()
            .current
            .copy(favoritesPageMode: filter.filteringMode)
            .save();
      },
      allowedFilteringModes: const {
        FilteringMode.tag,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.same,
      },
      allowedSortingModes: const {},
      initialFilteringMode: MiscSettingsService.db().current.favoritesPageMode,
      initialSortingMode: SortingMode.none,
    );

    filter.clearRefresh();

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;
      filter.clearRefresh();
    });

    filter.clearRefresh();
  }

  @override
  void dispose() {
    client.close(force: true);
    settingsWatcher.cancel();
    filter.destroy();

    searchFocus.dispose();
    searchTextController.dispose();

    state.dispose();

    super.dispose();
  }

  Iterable<FavoritePost> _collector(
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
    Navigator.pop(context);

    searchTextController.text = t;
    filter.filteringMode = FilteringMode.tag;
  }

  void download(int i) => filter
      .forIdxUnsafe(i)
      .download(DownloadManager.of(context), PostTags.fromContext(context));

  List<GridAction<FavoritePost>> gridActions() {
    return [
      booru_actions.download(context, state.settings.selectedBooru, null),
      booru_actions.favorites<FavoritePost>(
        context,
        favoritePosts,
        showDeleteSnackbar: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = GridFrame<FavoritePost>(
      key: state.gridKey,
      slivers: [
        CurrentGridSettingsLayout<FavoritePost>(
          source: filter.backingStorage,
          progress: filter.progress,
          gridSeed: state.gridSeed,
        ),
      ],
      functionality: GridFunctionality(
        selectionActions: SelectionActions.of(context),
        scrollingSink: ScrollingSinkProvider.maybeOf(context),
        onEmptySource: EmptyWidgetBackground(
          subtitle: l10n.emptyFavoritedPosts,
        ),
        search: PageNameSearchWidget(
          leading: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu_rounded),
          ),
          trailingItems: [
            ChainedFilterIcon(
              filter: filter,
              controller: searchTextController,
              complete: api.searchTag,
              onChange: (str) => filter.clearRefresh(),
              focusNode: searchFocus,
            ),
          ],
        ),
        settingsButton: GridSettingsButton.fromWatchable(gridSettings),
        registerNotifiers: (child) => OnBooruTagPressed(
          onPressed: _onPressed,
          child: child,
        ),
        download: download,
        source: filter,
      ),
      description: GridDescription(
        actions: gridActions(),
        pullToRefresh: false,
        pageName: l10n.favoritesLabel,
        gridSeed: state.gridSeed,
      ),
    );

    return GridPopScope(
      searchTextController: searchTextController,
      filter: filter,
      rootNavigatorPop: widget.rootNavigatorPop,
      child: GridConfiguration(
        watch: gridSettings.watch,
        child: child,
      ),
    );
  }
}
