// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/booru/booru_search_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:url_launcher/url_launcher.dart";

class BooruRestoredPage extends StatefulWidget {
  const BooruRestoredPage({
    super.key,
    required this.state,
    this.generateGlue,
    required this.pagingRegistry,
    this.overrideSafeMode,
    this.onDispose,
    required this.db,
  });

  final GridStateBooru state;
  final PagingStateRegistry pagingRegistry;
  final SafeMode? overrideSafeMode;
  final void Function()? onDispose;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;

  final DbConn db;

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String tags,
    this.tagManager,
    this.secondaryGrid,
    HiddenBooruPostService hiddenBooruPosts,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    api = BooruAPI.fromEnum(booru, client, this);

    source = secondaryGrid.makeSource(
      api,
      tagManager.excluded,
      this,
      tags,
      hiddenBooruPosts,
    );
  }

  final Dio client;
  final TagManager tagManager;
  final SecondaryGridService secondaryGrid;
  late final BooruAPI api;
  late final PostsSourceService<Post> source;

  int? currentSkipped;

  @override
  bool reachedEnd = false;

  late final state = GridSkeletonRefreshingState<Post>(
    initalCellCount: source.count,
    reachedEnd: () => reachedEnd,
    clearRefresh: AsyncGridRefresh(source.clearRefresh),
    next: source.next,
  );

  @override
  void updateTime() => secondaryGrid.currentState
      .copy(time: DateTime.now())
      .saveSecondary(secondaryGrid);

  @override
  void dispose() {
    client.close();

    state.dispose();

    secondaryGrid.destroy();
  }

  SafeMode get safeMode => secondaryGrid.currentState.safeMode;
  set safeMode(SafeMode s) =>
      secondaryGrid.currentState.copy(safeMode: s).saveSecondary(secondaryGrid);

  @override
  double get offset => secondaryGrid.currentState.scrollOffset;

  @override
  int get page => secondaryGrid.page;

  @override
  set page(int p) => secondaryGrid.page = p;

  @override
  void setOffset(double o) => secondaryGrid.currentState
      .copy(scrollOffset: o)
      .saveSecondary(secondaryGrid);
}

class _BooruRestoredPageState extends State<BooruRestoredPage> {
  GridStateBooruService get gridStateBooru => widget.db.gridStateBooru;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> blacklistedWatcher;

  late final SearchLaunchGrid search;

  late final RestoredBooruPageState pagingState;

  BooruAPI get api => pagingState.api;
  GridSkeletonRefreshingState<Post> get state => pagingState.state;
  TagManager get tagManager => pagingState.tagManager;
  PostsSourceService<Post> get source => pagingState.source;

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(widget.state.name, () {
      final secondary = widget.db.secondaryGrid(
        state.settings.selectedBooru,
        widget.state.name,
      );

      return RestoredBooruPageState(
        widget.state.booru,
        widget.state.tags,
        secondary.tagManager,
        secondary,
        hiddenBooruPost,
      );
    }) as RestoredBooruPageState;

    search = SearchLaunchGrid(
      SearchLaunchGridData(
        completeTag: api.completeTag,
        mainFocus: state.mainFocus,
        header: TagsWidget(
          tagging: tagManager.latest,
          onPress: (tag, safeMode) {},
        ),
        searchText: widget.state.tags,
        addItems: (_) => const [],
        disabled: true,
        onSubmit: (context, tag) {},
      ),
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = favoritePosts.watch((event) {
      state.refreshingStatus.mutation.notify();
      setState(() {});
    });

    blacklistedWatcher = hiddenBooruPost.watch((_) {
      state.refreshingStatus.mutation.notify();
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    widget.onDispose?.call();

    search.dispose();

    super.dispose();
  }

  // SafeMode _safeMode() {
  //   final prev = Dbs.g.main.gridStateBoorus.getByNameSync(widget.state.name)!;

  //   return prev.safeMode;
  // }

  void _download(int i) => source.forIdx(i)?.download(context);

  void _onTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruSearchPage(
            booru: booru,
            tags: tag,
            wrapScaffold: true,
            overrideSafeMode: safeMode,
            db: widget.db,
          );
        },
      ),
    ).then((value) => PauseVideoNotifier.maybePauseOf(context, false));
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        provided: widget.generateGlue,
        child: Builder(
          builder: (context) {
            return BooruAPINotifier(
              api: api,
              child: GridSkeleton(
                state,
                (context) => GridFrame<Post>(
                  key: state.gridKey,
                  slivers: [
                    CurrentGridSettingsLayout<Post>(
                      mutation: state.refreshingStatus.mutation,
                      gridSeed: state.gridSeed,
                    ),
                  ],
                  mainFocus: state.mainFocus,
                  getCell: source.forIdxUnsafe,
                  initalScrollPosition: pagingState.offset,
                  functionality: GridFunctionality(
                    settingsButton:
                        GridSettingsButton.fromWatchable(gridSettings),
                    updateScrollPosition: pagingState.setOffset,
                    onError: (error) {
                      return OutlinedButton.icon(
                        onPressed: () {
                          launchUrl(
                            Uri.https(api.booru.url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        label:
                            Text(AppLocalizations.of(context)!.openInBrowser),
                        icon: const Icon(Icons.public),
                      );
                    },
                    download: _download,
                    selectionGlue: GlueProvider.generateOf(context)(),
                    refreshingStatus: state.refreshingStatus,
                    search: OverrideGridSearchWidget(
                      SearchAndFocus(
                        search.searchWidget(context, hint: api.booru.name),
                        search.searchFocus,
                      ),
                    ),
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: _onTagPressed,
                      child: BooruAPINotifier(api: api, child: child),
                    ),
                  ),
                  description: GridDescription(
                    actions: [
                      BooruGridActions.download(context, api.booru),
                      BooruGridActions.favorites(
                        context,
                        favoritePosts,
                        showDeleteSnackbar: true,
                      ),
                    ],
                    inlineMenuButtonItems: true,
                    keybindsDescription:
                        AppLocalizations.of(context)!.booruGridPageName,
                    gridSeed: state.gridSeed,
                  ),
                ),
                canPop: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
