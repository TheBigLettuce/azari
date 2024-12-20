// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

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
    required this.db,
    required this.rootNavigatorPop,
  });

  final void Function(bool)? rootNavigatorPop;

  final DbConn db;

  @override
  State<FavoritePostsPage> createState() => _FavoritePostsPageState();
}

class _FavoritePostsPageState extends State<FavoritePostsPage>
    with CommonGridData<Post, FavoritePostsPage> {
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.favoritePosts;

  late final StreamSubscription<void> _safeModeWatcher;

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  late final client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
  late final BooruAPI api;

  late final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  late final SafeModeState safeModeState;

  @override
  void initState() {
    super.initState();

    safeModeState = SafeModeState(settings.safeMode);

    api = BooruAPI.fromEnum(settings.selectedBooru, client);

    filter = ChainedFilterResourceSource(
      favoritePosts,
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.same => sameFavorites(
              cells,
              data,
              end,
              _collector,
              safeModeState.current,
            ),
          FilteringMode.tag => (
              searchTextController.text.isEmpty
                  ? cells.where(
                      (e) => safeModeState.current.inLevel(e.rating.asSafeMode),
                    )
                  : cells.where(
                      (e) =>
                          e.tags.contains(searchTextController.text) &&
                          safeModeState.current.inLevel(e.rating.asSafeMode),
                    ),
              data
            ),
          FilteringMode.gif => (
              cells.where(
                (element) =>
                    element.type == PostContentType.gif &&
                    safeModeState.current.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode.video => (
              cells.where(
                (element) =>
                    element.type == PostContentType.video &&
                    safeModeState.current.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode() => (
              cells.where(
                (e) => safeModeState.current.inLevel(e.rating.asSafeMode),
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
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.rating,
        SortingMode.score,
      },
      initialFilteringMode: MiscSettingsService.db().current.favoritesPageMode,
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
    ExitOnPressRoute.maybeExitOf(context);

    searchTextController.text = t;
    filter.filteringMode = FilteringMode.tag;

    if (safeMode != null) {
      safeModeState.setCurrent(safeMode);
    }

    gridKey.currentState?.tryScrollUp();
  }

  void download(int i) => filter
      .forIdxUnsafe(i)
      .download(DownloadManager.of(context), PostTags.fromContext(context));

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
            ),
            CurrentGridSettingsLayout<FavoritePost>(
              source: filter.backingStorage,
              progress: filter.progress,
              gridSeed: gridSeed,
            ),
          ],
          functionality: GridFunctionality(
            scrollUpOn: [(NavigationButtonEvents.maybeOf(context)!, null)],
            selectionActions: SelectionActions.of(context),
            scrollingSink: ScrollingSinkProvider.maybeOf(context),
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
              child: child,
            ),
            download: download,
            source: filter,
          ),
          description: GridDescription(
            actions: [
              booru_actions.download(context, settings.selectedBooru, null),
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
  });

  final TextEditingController searchTextController;
  final FocusNode searchFocus;

  final BooruAPI api;

  final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  final SafeModeState safeModeState;

  void launchGrid(BuildContext context) {
    if (searchTextController.text.isNotEmpty) {
      context.openSafeModeDialog((safeMode) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => BooruRestoredPage(
              db: DbConn.of(context),
              booru: api.booru,
              tags: searchTextController.text.trim(),
              saveSelectedPage: (_) {},
              overrideSafeMode: safeMode,
              // wrapScaffold: true,
            ),
          ),
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
