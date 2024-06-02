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
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:url_launcher/url_launcher.dart";

class BooruRestoredPage extends StatefulWidget {
  const BooruRestoredPage({
    super.key,
    this.generateGlue,
    this.pagingRegistry,
    this.overrideSafeMode,
    required this.db,
    this.name,
    required this.booru,
    required this.tags,
    this.wrapScaffold = false,
    required this.saveSelectedPage,
  });

  final String? name;
  final Booru booru;
  final String tags;
  final PagingStateRegistry? pagingRegistry;
  final SafeMode? overrideSafeMode;
  final void Function(String? e) saveSelectedPage;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool wrapScaffold;

  final DbConn db;

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class LocalBookmark extends GridBookmark {
  const LocalBookmark({
    required super.tags,
    required super.booru,
    required super.name,
    required super.time,
  });

  @override
  GridBookmark copy({
    String? tags,
    String? name,
    Booru? booru,
    DateTime? time,
  }) =>
      LocalBookmark(
        tags: tags ?? this.tags,
        booru: booru ?? this.booru,
        name: name ?? this.name,
        time: time ?? this.time,
      );
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String tags,
    this.tagManager,
    this.secondaryGrid,
    HiddenBooruPostService hiddenBooruPosts,
    this.gridBookmarks,
    this.addToBookmarks,
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

  bool addToBookmarks;

  @override
  void updateTime() =>
      gridBookmarks.get(secondaryGrid.name)!.copy(time: DateTime.now()).save();

  final Dio client;
  final TagManager tagManager;
  late final BooruAPI api;

  final SecondaryGridService secondaryGrid;
  final GridBookmarkService gridBookmarks;
  late final GridPostSource source;

  int? currentSkipped;

  @override
  bool reachedEnd = false;

  late final state = GridSkeletonState<Post>();

  @override
  Future<void> dispose([bool closeGrid = true]) {
    client.close();
    // source.destroy();
    state.dispose();

    if (closeGrid) {
      return secondaryGrid.close();
    } else {
      return secondaryGrid.destroy();
    }
  }

  SafeMode get safeMode => secondaryGrid.currentState.safeMode;
  set safeMode(SafeMode s) =>
      secondaryGrid.currentState.copy(safeMode: s).saveSecondary(secondaryGrid);

  @override
  double get offset => secondaryGrid.currentState.offset;

  @override
  int get page => secondaryGrid.page;

  @override
  set page(int p) => secondaryGrid.page = p;

  @override
  void setOffset(double o) =>
      secondaryGrid.currentState.copy(offset: o).saveSecondary(secondaryGrid);
}

class _BooruRestoredPageState extends State<BooruRestoredPage> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<void> favoritesWatcher;

  late final SearchLaunchGrid search;

  late final RestoredBooruPageState pagingState;

  BooruAPI get api => pagingState.api;
  GridSkeletonState<Post> get state => pagingState.state;
  TagManager get tagManager => pagingState.tagManager;
  GridPostSource get source => pagingState.source;

  RestoredBooruPageState makePageEntry(String name) {
    final secondary = widget.db.secondaryGrid(
      widget.booru,
      name,
      widget.overrideSafeMode,
      widget.name == null,
    );

    return RestoredBooruPageState(
      widget.booru,
      widget.tags,
      secondary.tagManager,
      secondary,
      hiddenBooruPost,
      gridBookmarks,
      widget.name != null,
    );
  }

  @override
  void initState() {
    super.initState();

    final name =
        widget.name ?? DateTime.now().microsecondsSinceEpoch.toString();

    widget.saveSelectedPage(name);

    pagingState =
        widget.pagingRegistry?.getOrRegister(name, () => makePageEntry(name)) ??
            makePageEntry(name);

    pagingState.tagManager.latest.add(widget.tags);

    if (gridBookmarks.get(pagingState.secondaryGrid.name) == null) {
      gridBookmarks.add(
        objFactory.makeGridBookmark(
          booru: widget.booru,
          name: pagingState.secondaryGrid.name,
          time: DateTime.now(),
          tags: widget.tags,
        ),
      );
    }

    search = SearchLaunchGrid(
      SearchLaunchGridData(
        completeTag: api.completeTag,
        header: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8),
          child: TagsWidget(
            tagging: tagManager.latest,
            onPress: (tag, safeMode) {
              _onTagPressed(
                context,
                state.settings.selectedBooru,
                tag,
                safeMode,
              );
            },
          ),
        ),
        searchText: pagingState.source.tags,
        addItems: (_) => const [],
        onSubmit: (context, tag) {
          pagingState.source.tags = tag;
          pagingState.source.clearRefresh();
          gridBookmarks.get(name)!.copy(tags: tag).save();
        },
      ),
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = favoritePosts.backingStorage.watch((event) {
      source.backingStorage.addAll([]);
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    if (widget.pagingRegistry == null) {
      widget.saveSelectedPage(null);
      if (!pagingState.addToBookmarks) {
        gridBookmarks.delete(pagingState.secondaryGrid.name);
      }
      pagingState.dispose(pagingState.addToBookmarks);
    } else {
      if (!isRestart) {
        widget.saveSelectedPage(null);
        if (!pagingState.addToBookmarks) {
          gridBookmarks.delete(pagingState.secondaryGrid.name);
        }
        (widget.pagingRegistry!.remove(pagingState.secondaryGrid.name)!
                as RestoredBooruPageState)
            .dispose(pagingState.addToBookmarks);
      }
    }

    search.dispose();

    super.dispose();
  }

  void _download(int i) => source
      .forIdx(i)
      ?.download(DownloadManager.of(context), PostTags.fromContext(context));

  void _onTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
            wrapScaffold: true,
            overrideSafeMode: safeMode,
            db: widget.db,
            saveSelectedPage: (s) {},
          );
        },
      ),
    ).then((value) {
      PauseVideoNotifier.maybePauseOf(context, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        addScaffold: widget.wrapScaffold,
        provided: widget.generateGlue,
        child: Builder(
          builder: (context) {
            return BooruAPINotifier(
              api: api,
              child: GridPopScope(
                searchTextController: null,
                filter: null,
                searchFocus: null,
                child: GridFrame<Post>(
                  key: state.gridKey,
                  slivers: [
                    CurrentGridSettingsLayout<Post>(
                      source: source.backingStorage,
                      progress: source.progress,
                      gridSeed: state.gridSeed,
                      unselectOnUpdate: false,
                      buildEmpty: (e) => EmptyWidgetWithButton(
                        error: e,
                        buttonText: l10n.openInBrowser,
                        onPressed: () {
                          launchUrl(
                            Uri.https(api.booru.url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                    GridFooter<void>(
                      storage: source.backingStorage,
                      name: source.tags,
                    ),
                  ],
                  initalScrollPosition: pagingState.offset,
                  functionality: GridFunctionality(
                    settingsButton: GridSettingsButton.fromWatchable(
                      gridSettings,
                      SafeModeButton(secondaryGrid: pagingState.secondaryGrid),
                    ),
                    updateScrollPosition: pagingState.setOffset,
                    download: _download,
                    selectionGlue: GlueProvider.generateOf(context)(),
                    source: source,
                    search: OverrideGridSearchWidget(
                      SearchAndFocus(
                        search.searchWidget(
                          context,
                          hint: api.booru.name,
                          disabled: pagingState.addToBookmarks,
                        ),
                        search.searchFocus,
                      ),
                    ),
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: _onTagPressed,
                      child: BooruAPINotifier(api: api, child: child),
                    ),
                  ),
                  description: GridDescription(
                    menuButtonItems: [
                      IconButton(
                        icon: pagingState.addToBookmarks
                            ? const Icon(Icons.bookmark_remove_rounded)
                            : const Icon(Icons.bookmark_add_rounded),
                        onPressed: () {
                          pagingState.addToBookmarks =
                              !pagingState.addToBookmarks;

                          setState(() {});
                        },
                      ),
                    ],
                    actions: [
                      BooruGridActions.download(context, api.booru),
                      BooruGridActions.favorites(
                        context,
                        favoritePosts,
                        showDeleteSnackbar: true,
                      ),
                      BooruGridActions.hide(context, hiddenBooruPost),
                    ],
                    animationsOnSourceWatch: false,
                    inlineMenuButtonItems: true,
                    keybindsDescription: l10n.booruGridPageName,
                    gridSeed: state.gridSeed,
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
