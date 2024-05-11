// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/posts_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/bookmark_button.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/booru/booru_search_page.dart";
import "package:gallery/src/pages/booru/open_menu_button.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/favorite_booru_page.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/pages/more/tags/single_post.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:url_launcher/url_launcher.dart";

typedef OnBooruTagPressedFunc = void Function(
  BuildContext context,
  Booru booru,
  String tag,
  SafeMode? overrideSafeMode,
);

class _MainGridPagingState implements PagingEntry {
  _MainGridPagingState(
    int initalCellCount,
    this.booru,
    this.tagManager,
    this.mainGrid,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    source = PostsSourceService.currentMain(api, tagManager.excluded, this);
    refreshingStatus = GridRefreshingStatus(
      initalCellCount,
      () => reachedEnd,
      clearRefresh: AsyncGridRefresh(source.clearRefresh),
      next: source.next,
    );
  }

  factory _MainGridPagingState.prototype(
    TagManager tagManager,
    MainGridService mainGrid,
    Booru booru,
  ) =>
      _MainGridPagingState(
        mainGrid.postsInside,
        booru,
        tagManager,
        mainGrid,
      );

  final Booru booru;

  @override
  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru, client, this);
  final TagManager tagManager;
  final Dio client;
  late final PostsSourceService source;
  final MainGridService mainGrid;

  int? currentSkipped;

  String? restoreSecondaryGrid;

  late final GridRefreshingStatus<Post> refreshingStatus;

  bool needToRefresh(Duration microseconds) => mainGrid.currentState.time
      .isBefore(DateTime.now().subtract(microseconds));

  @override
  double get offset => mainGrid.currentState.scrollOffset;

  @override
  void updateTime() =>
      mainGrid.currentState.copy(time: DateTime.now()).save(mainGrid);

  @override
  int get page => mainGrid.page;

  @override
  set page(int p) => mainGrid.page = p;

  @override
  void setOffset(double o) =>
      mainGrid.currentState.copy(scrollOffset: o).save(mainGrid);

  @override
  void dispose() {
    client.close();
    refreshingStatus.dispose();
  }
}

class BooruPage extends StatefulWidget {
  const BooruPage({
    super.key,
    required this.procPop,
    required this.pagingRegistry,
    required this.db,
  });

  final PagingStateRegistry pagingRegistry;

  final void Function(bool) procPop;

  final DbConn db;

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage> {
  GridStateBooruService get gridStateBooru => widget.db.gridStateBooru;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostService get favoritePosts => widget.db.favoritePosts;

  PostsSourceService get source => pagingState.source;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> timeUpdater;
  late final StreamSubscription<void> bookmarksWatcher;
  late final StreamSubscription<void> blacklistedWatcher;

  bool inForeground = true;

  late final AppLifecycleListener lifecycleListener;

  late final SearchLaunchGrid<Post> search;

  int? currentSkipped;

  late final _MainGridPagingState pagingState;

  late final state = GridSkeletonState<Post>();

  final menuController = MenuController();

  final _tagsWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(
      state.settings.selectedBooru.string,
      () {
        final mainGrid = widget.db.mainGrid(state.settings.selectedBooru);

        return _MainGridPagingState.prototype(
          mainGrid.tagManager,
          mainGrid,
          state.settings.selectedBooru,
        );
      },
    ) as _MainGridPagingState;

    bookmarksWatcher = gridStateBooru.watch((_) {
      setState(() {});
    });

    lifecycleListener = AppLifecycleListener(
      onHide: () {
        inForeground = false;
      },
      onShow: () {
        inForeground = true;

        if (pagingState.api.wouldBecomeStale &&
            pagingState.needToRefresh(const Duration(hours: 1))) {
          final gridState = state.gridKey.currentState;
          if (gridState != null) {
            gridState.resetFab();
            pagingState.refreshingStatus.refresh();
          }

          pagingState.updateTime();
        }
      },
    );

    timeUpdater = Stream<void>.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneralService.db()
            .current
            .add(timeSpent: 5.seconds.inMilliseconds)
            .save();
      }
    });

    search = SearchLaunchGrid(
      SearchLaunchGridData(
        completeTag: pagingState.api.completeTag,
        mainFocus: state.mainFocus,
        header: _LatestAndExcluded(
          key: _tagsWidgetKey,
          api: pagingState.api,
          db: favoritePosts,
          tagManager: pagingState.tagManager,
          onPressed: (tag, safeMode) {
            _onBooruTagPressed(
              context,
              pagingState.api.booru,
              tag,
              safeMode,
            );
          },
        ),
        searchText: "",
        swapSearchIconWithAddItems: false,
        addItems: (context) => [
          OpenMenuButton(
            context: context,
            controller: search.searchController,
            launchGrid: (context, tag, [safeMode]) {
              _onBooruTagPressed(context, pagingState.api.booru, tag, safeMode);
            },
            booru: pagingState.api.booru,
          ),
        ],
        onSubmit: (context, tag) =>
            _onBooruTagPressed(context, pagingState.api.booru, tag, null),
      ),
    );

    if (pagingState.api.wouldBecomeStale &&
        pagingState.needToRefresh(const Duration(hours: 1))) {
      source.clear();
      pagingState.refreshingStatus.mutation.cellCount = 0;

      pagingState.updateTime();
    }

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    blacklistedWatcher = hiddenBooruPost.watch((_) {
      pagingState.refreshingStatus.mutation.notify();
    });

    favoritesWatcher = favoritePosts.watch((event) {
      pagingState.refreshingStatus.mutation.notify();
    });

    if (pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = gridStateBooru.get(pagingState.restoreSecondaryGrid!)!;
        e.copy(time: DateTime.now()).save();

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) {
              return BooruRestoredPage(
                pagingRegistry: widget.pagingRegistry,
                onDispose: () {
                  if (!isRestart) {
                    pagingState.restoreSecondaryGrid = null;
                    widget.pagingRegistry.remove(e.name);
                  }
                },
                state: e,
                generateGlue: GlueProvider.generateOf(context),
              );
            },
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    settingsWatcher.cancel();
    favoritesWatcher.cancel();
    bookmarksWatcher.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    search.dispose();

    state.dispose();

    timeUpdater.cancel();

    lifecycleListener.dispose();
    scrollController.dispose();

    super.dispose();
  }

  void _download(int i) => source.forIdx(i)?.download(context);

  final scrollController = ScrollController();

  void _onBooruTagPressed(
    BuildContext _,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruSearchPage(
            booru: booru,
            tags: tag,
            generateGlue: GlueProvider.generateOf(context),
            overrideSafeMode: safeMode,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FavoriteBooruStateHolder(
      build: (context, favoriteBooruState) {
        return BooruAPINotifier(
          api: pagingState.api,
          child: GridSkeleton(
            state,
            (context) => GridFrame<Post>(
              key: state.gridKey,
              layout:
                  const GridSettingsLayoutBehaviour(GridSettingsBooru.current),
              overrideController: scrollController,
              functionality: GridFunctionality(
                selectionGlue: GlueProvider.generateOf(context)(),
                watchLayoutSettings: GridSettingsBooru.watch,
                refreshingStatus: pagingState.refreshingStatus,
                download: _download,
                search: OverrideGridSearchWidget(
                  SearchAndFocus(
                    search.searchWidget(
                      context,
                      hint: pagingState.api.booru.name,
                    ),
                    search.searchFocus,
                  ),
                ),
                updateScrollPosition: pagingState.setOffset,
                onError: (error) {
                  return FilledButton.icon(
                    onPressed: () {
                      launchUrl(
                        Uri.https(pagingState.api.booru.url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    label: Text(AppLocalizations.of(context)!.openInBrowser),
                    icon: const Icon(Icons.public),
                  );
                },
                registerNotifiers: (child) => OnBooruTagPressed(
                  onPressed: (context, booru, value, safeMode) {
                    Navigator.pop(context);

                    _onBooruTagPressed(context, booru, value, safeMode);
                  },
                  child: BooruAPINotifier(
                    api: pagingState.api,
                    child: child,
                  ),
                ),
              ),
              description: GridDescription(
                actions: [
                  BooruGridActions.download(context, pagingState.api.booru),
                  BooruGridActions.favorites(
                    context,
                    favoritePosts,
                    showDeleteSnackbar: true,
                  ),
                  BooruGridActions.hide(context, hiddenBooruPost),
                ],
                pages: PageSwitcherIcons(
                  [
                    PageIcon(
                      Icons.favorite_rounded,
                      count: favoritePosts.count,
                    ),
                    PageIcon(
                      Icons.bookmarks_rounded,
                      count: gridStateBooru.count,
                    ),
                  ],
                  (context, state, i) => switch (i) {
                    0 => PageDescription(
                        search: SearchAndFocus(
                          favoriteBooruState.search.searchWidget(
                            favoriteBooruState.context,
                            count: favoriteBooruState.loader.count(),
                          ),
                          favoriteBooruState.search.searchFocus,
                        ),
                        settingsButton: favoriteBooruState.gridSettingsButton(),
                        slivers: [
                          GlueProvider(
                            generate: GlueProvider.generateOf(context),
                            child: FavoriteBooruPage(
                              conroller: scrollController,
                              state: favoriteBooruState,
                            ),
                          ),
                        ],
                      ),
                    1 => PageDescription(
                        slivers: [
                          BookmarkPage(
                            scrollUp: () {
                              state.controller.animateTo(
                                0,
                                duration: const Duration(milliseconds: 180),
                                curve: Easing.standardAccelerate,
                              );
                            },
                            pagingRegistry: widget.pagingRegistry,
                            generateGlue: GlueProvider.generateOf(context),
                            saveSelectedPage: (s) =>
                                pagingState.restoreSecondaryGrid = s,
                            db: widget.db,
                          ),
                        ],
                      ),
                    int() => const PageDescription(slivers: []),
                  },
                ),
                inlineMenuButtonItems: true,
                settingsButton: GridFrameSettingsButton(
                  selectSafeMode: (safeMode, _) =>
                      state.settings.copy(safeMode: safeMode).save(),
                  safeMode: state.settings.safeMode,
                  selectGridColumn: (columns, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(columns: columns)
                          .save(),
                  selectGridLayout: (layoutType, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(layoutType: layoutType)
                          .save(),
                  selectRatio: (ratio, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(aspectRatio: ratio)
                          .save(),
                ),
                pageName: AppLocalizations.of(context)!.booruLabel,
                keybindsDescription:
                    AppLocalizations.of(context)!.booruGridPageName,
                gridSeed: state.gridSeed,
              ),
              mainFocus: state.mainFocus,
              getCell: pagingState.source.forIdxUnsafe,
              initalScrollPosition: pagingState.offset,
            ),
            canPop: false,
            secondarySelectionHide: () {
              favoriteBooruState.state.gridKey.currentState?.selection.reset();
            },
            onPop: (pop) {
              final gridState = state.gridKey.currentState;
              if (gridState != null && gridState.currentPage == 1) {
                if (favoriteBooruState
                    .search.searchTextController.text.isNotEmpty) {
                  favoriteBooruState.search.performSearch("");
                  return;
                }
              }

              final s = state.gridKey.currentState;
              if (s != null && s.currentPage != 0) {
                s.onSubpageSwitched(0, s.selection, s.controller);
                return;
              }

              widget.procPop(pop);
            },
          ),
        );
      },
    );
  }
}

class _LatestAndExcluded extends StatefulWidget {
  const _LatestAndExcluded({
    super.key,
    required this.onPressed,
    required this.tagManager,
    required this.api,
    required this.db,
  });

  final TagManager tagManager;
  final BooruAPI api;
  final void Function(String, SafeMode?) onPressed;

  final FavoritePostService db;

  @override
  State<_LatestAndExcluded> createState() => __LatestAndExcludedState();
}

class __LatestAndExcludedState extends State<_LatestAndExcluded> {
  BooruTagging get excluded => widget.tagManager.excluded;
  BooruTagging get latest => widget.tagManager.latest;

  bool showExcluded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(top: 8)),
        TagsWidget(
          tagging: latest,
          onPress: widget.onPressed,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: IconButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  DialogRoute<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.searchSinglePost,
                        ),
                        content: SinglePost(
                            tagManager: widget.tagManager, db: widget.db),
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 6)),
        if (showExcluded)
          TagsWidget(
            tagging: excluded,
            onPress: null,
            redBackground: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: IconButton.filled(
                onPressed: () {
                  Navigator.push(
                    context,
                    DialogRoute<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            AppLocalizations.of(context)!.addToExcluded,
                          ),
                          content: AutocompleteWidget(
                            null,
                            (s) {},
                            swapSearchIcon: false,
                            (s) {
                              widget.tagManager.excluded.add(s);

                              Navigator.pop(context);
                            },
                            () {},
                            widget.api.completeTag,
                            null,
                            submitOnPress: true,
                            roundBorders: true,
                            plainSearchBar: true,
                            showSearch: true,
                          ),
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ),
          )
        else
          TextButton(
            onPressed: () {
              showExcluded = !showExcluded;

              setState(() {});
            },
            child: Text(AppLocalizations.of(context)!.showExcludedTags),
          ),
      ],
    );
  }
}

class OnBooruTagPressed extends InheritedWidget {
  const OnBooruTagPressed({
    super.key,
    required this.onPressed,
    required super.child,
  });
  final OnBooruTagPressedFunc onPressed;

  static void pressOf(
    BuildContext context,
    String tag,
    Booru booru, {
    SafeMode? overrideSafeMode,
  }) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    widget!.onPressed(context, booru, tag, overrideSafeMode);
  }

  static void maybePressOf(
    BuildContext context,
    String tag,
    Booru booru, {
    SafeMode? overrideSafeMode,
  }) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    widget?.onPressed(context, booru, tag, overrideSafeMode);
  }

  @override
  bool updateShouldNotify(OnBooruTagPressed oldWidget) =>
      oldWidget.onPressed != onPressed;
}
