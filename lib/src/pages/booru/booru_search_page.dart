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
import "package:gallery/src/pages/booru/add_to_bookmarks_button.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
// import "package:path/path.dart" as path;
import "package:url_launcher/url_launcher.dart";

class BooruSearchPage extends StatefulWidget {
  const BooruSearchPage({
    super.key,
    required this.booru,
    required this.tags,
    this.generateGlue,
    this.overrideSafeMode,
    this.wrapScaffold = false,
    required this.db,
  });

  final Booru booru;
  final String tags;
  final SafeMode? overrideSafeMode;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool wrapScaffold;

  final DbConn db;

  @override
  State<BooruSearchPage> createState() => _BooruSearchPageState();
}

class BooruSearchPagingEntry implements PagingEntry {
  BooruSearchPagingEntry(Booru booru, this.safeMode, String initTags)
      : client = BooruAPI.defaultClientForBooru(booru) {
    throw "";
    api = BooruAPI.fromEnum(booru, client, EmptyPageSaver());
    // source = PostsSourceService.currentTemporary(
    //   api,
    //   tagManager.excluded,
    //   this,
    //   initialTags: initTags,
    // );

    state = GridSkeletonRefreshingState(
      reachedEnd: () => reachedEnd,
      clearRefresh: AsyncGridRefresh(source.clearRefresh),
      next: source.next,
    );
  }

  final Dio client;
  late final TagManager tagManager;
  late final BooruAPI api;

  late final PostsSourceService<Post> source;
  late final GridSkeletonRefreshingState<Post> state;

  SafeMode? safeMode;

  bool removeDb = true;

  @override
  int page = 0;

  @override
  bool reachedEnd = false;

  double _currentScroll = 0;

  @override
  double get offset => _currentScroll;

  @override
  void dispose() {
    source.destroy();
    client.close();
    state.dispose();
  }

  @override
  void setOffset(double o) => _currentScroll = o;

  @override
  void updateTime() {}

  void moveToBookmark(BuildContext context, String tags) {
    // final instance = (source as IsarCurrentBooruSource).db;

    // instance.close().then((value) {
    //   removeDb = false;

    //   final f = File.fromUri(
    //     Uri.file(
    //       path.joinAll([
    //         Dbs.g.temporaryDbDir,
    //         "${instance.name}.isar",
    //       ]),
    //     ),
    //   );
    //   f.renameSync(
    //     path.joinAll([
    //       Dbs.g.appStorageDir,
    //       "${instance.name}.isar",
    //     ]),
    //   );
    //   Dbs.g.main.writeTxnSync(
    //     () => Dbs.g.main.gridStateBoorus.putSync(
    //       GridStateBooru(
    //         api.booru,
    //         tags: tags,
    //         scrollOffset: _currentScroll,
    //         safeMode: safeMode ?? state.settings.safeMode,
    //         name: instance.name,
    //         time: DateTime.now(),
    //       ),
    //     ),
    //   );

    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         AppLocalizations.of(context)!.bookmarked,
    //       ),
    //     ),
    //   );
    //   state.gridKey.currentState?.selection.reset();

    //   Navigator.pop(context);
    // });
  }
}

class _BooruSearchPageState extends State<BooruSearchPage> {
  GridStateBooruService get gridStateBooru => widget.db.gridStateBooru;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  PostsSourceService<Post> get source => pagingState.source;

  late final StreamSubscription<void> blacklistedWatcher;
  late final StreamSubscription<SettingsData?> settingsWatcher;
  // late final StreamSubscription<void> favoritesWatcher;

  late final BooruSearchPagingEntry pagingState;

  late final SearchLaunchGrid search;

  GridSkeletonRefreshingState<Post> get state => pagingState.state;
  BooruAPI get api => pagingState.api;
  TagManager get tagManager => pagingState.tagManager;

  @override
  void initState() {
    super.initState();

    pagingState = BooruSearchPagingEntry(
      widget.booru,
      widget.overrideSafeMode,
      widget.tags,
    );

    search = SearchLaunchGrid(
      SearchLaunchGridData(
        completeTag: api.completeTag,
        mainFocus: state.mainFocus,
        header: Padding(
          padding: const EdgeInsets.all(8),
          child: TagsWidget(
            tagging: tagManager.latest,
            onPress: (tag, safeMode) {
              Navigator.pop(context);

              _clearAndRefreshB(tag);
            },
          ),
        ),
        searchText: widget.tags,
        addItems: (_) => const [],
        searchTextAsLabel: true,
        onSubmit: (context, tag) {
          Navigator.pop(context);

          _clearAndRefreshB(tag);
        },
      ),
    );

    tagManager.latest.add(widget.tags);

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    // favoritesWatcher = Dbs.g.main.favoriteBoorus.watchLazy().listen((event) {
    //   state.refreshingStatus.mutation.notify();
    //   setState(() {});
    // });

    blacklistedWatcher = hiddenBooruPost.watch((_) {
      state.refreshingStatus.mutation.notify();
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    // favoritesWatcher.cancel();
    blacklistedWatcher.cancel();

    pagingState.dispose();
    search.dispose();

    super.dispose();
  }

  void _clearAndRefreshB(String tag) {
    search.searchController.text = tag;
    pagingState.source.tags = tag;

    setState(() {
      search.tags = tag;
    });

    state.refreshingStatus.refresh();
  }

  void _download(int i) => source.forIdx(i)?.download(context);

  void _moveToBookmarkF(BuildContext context) {
    if (search.tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.searchTextIsEmpty,
          ),
        ),
      );

      return;
    }

    state.refreshingStatus.mutation.cellCount = 0;

    pagingState.moveToBookmark(context, search.tags);
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        addScaffold: widget.wrapScaffold,
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
                    CurrentGridSettingsLayout(
                      mutation: state.refreshingStatus.mutation,
                      gridSeed: state.gridSeed,
                    ),
                  ],
                  mainFocus: state.mainFocus,
                  getCell: pagingState.source.forIdxUnsafe,
                  functionality: GridFunctionality(
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
                      onPressed: (context, _, tag, overrideSafeMode) {
                        pagingState.safeMode = overrideSafeMode;
                        search.searchController.text = tag;

                        _clearAndRefreshB(tag);
                      },
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
                    menuButtonItems: [
                      AddToBookmarksButton(
                        state: state,
                        f: _moveToBookmarkF,
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
