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
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/bookmark_button.dart";
import "package:gallery/src/pages/booru/booru_grid_actions.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/booru/open_menu_button.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/blacklisted_posts.dart";
import "package:gallery/src/pages/more/favorite_booru_page.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/pages/more/tags/single_post.dart";
import "package:gallery/src/pages/more/tags/tags_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/notifiers/booru_api.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";
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
    HiddenBooruPostService hiddenBooruPosts,
    this.booru,
    this.tagManager,
    this.mainGrid,
    this.gridBookmarks,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    source =
        mainGrid.makeSource(api, tagManager.excluded, this, hiddenBooruPosts);
  }

  factory _MainGridPagingState.prototype(
    TagManager tagManager,
    HiddenBooruPostService hiddenBooruPosts,
    MainGridService mainGrid,
    Booru booru,
    GridBookmarkService gridBookmarks,
  ) =>
      _MainGridPagingState(
        hiddenBooruPosts,
        booru,
        tagManager,
        mainGrid,
        gridBookmarks,
      );

  final Booru booru;

  @override
  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru, client, this);
  final TagManager tagManager;
  final Dio client;
  late final GridPostSource source;
  final MainGridService mainGrid;
  final GridBookmarkService gridBookmarks;

  @override
  void updateTime() => mainGrid.time = DateTime.now();

  bool needToRefresh(Duration microseconds) =>
      mainGrid.time.isBefore(DateTime.now().subtract(microseconds));

  String? restoreSecondaryGrid;

  @override
  double get offset => mainGrid.currentState.offset;

  @override
  int get page => mainGrid.page;

  @override
  set page(int p) => mainGrid.page = p;

  @override
  void setOffset(double o) =>
      mainGrid.currentState.copy(offset: o).save(mainGrid);

  @override
  void dispose() {
    client.close();
    source.destroy();
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
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  GridPostSource get source => pagingState.source;

  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> timeUpdater;

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
          hiddenBooruPost,
          mainGrid,
          state.settings.selectedBooru,
          gridBookmarks,
        );
      },
    );

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
            source.clearRefresh();
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

      pagingState.updateTime();
    }

    favoritesWatcher = favoritePosts.backingStorage.watch((event) {
      source.backingStorage.addAll([]);
    });

    if (pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = gridBookmarks.get(pagingState.restoreSecondaryGrid!)!;

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) {
              return BooruRestoredPage(
                pagingRegistry: widget.pagingRegistry,
                generateGlue: GlueProvider.generateOf(context),
                db: DatabaseConnectionNotifier.of(context),
                booru: e.booru,
                tags: e.tags,
                saveSelectedPage: _setSecondaryName,
                name: e.name,
              );
            },
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    favoritesWatcher.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    search.dispose();

    state.dispose();

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  void _download(int i) => source
      .forIdx(i)
      ?.download(DownloadManager.of(context), PostTags.fromContext(context));

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
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
            generateGlue: GlueProvider.generateOf(context),
            overrideSafeMode: safeMode,
            db: widget.db,
            saveSelectedPage: _setSecondaryName,
            pagingRegistry: widget.pagingRegistry,
          );
        },
      ),
    );
  }

  // ignore: use_setters_to_change_properties
  void _setSecondaryName(String? name) {
    pagingState.restoreSecondaryGrid = name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (BooruSubPage.of(context)) {
      BooruSubPage.booru => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: GridConfiguration(
            watch: gridSettings.watch,
            child: BooruAPINotifier(
              api: pagingState.api,
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
                          Uri.https(pagingState.api.booru.url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                  GridFooter<void>(storage: source.backingStorage),
                ],
                functionality: GridFunctionality(
                  settingsButton: GridSettingsButton.fromWatchable(
                    gridSettings,
                    SafeModeButton(settingsWatcher: state.settings.s.watch),
                  ),
                  selectionGlue: GlueProvider.generateOf(context)(),
                  source: source,
                  search: RawSearchWidget(
                    (settingsButton, bottomWidget) => SliverAppBar(
                      leading: Center(
                        child: IconButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ),
                      floating: true,
                      pinned: true,
                      snap: true,
                      stretch: true,
                      bottom: bottomWidget ??
                          const PreferredSize(
                            preferredSize: Size.zero,
                            child: SizedBox.shrink(),
                          ),
                      centerTitle: true,
                      title: search.searchWidget(
                        context,
                        hint: pagingState.api.booru.name,
                      ),
                      actions: [if (settingsButton != null) settingsButton],
                    ),
                  ),
                  download: _download,
                  updateScrollPosition: pagingState.setOffset,
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
                  animationsOnSourceWatch: false,
                  pageName: l10n.booruLabel,
                  keybindsDescription: l10n.booruGridPageName,
                  gridSeed: state.gridSeed,
                ),
                initalScrollPosition: pagingState.offset,
              ),
            ),
          ),
        ),
      BooruSubPage.favorites => FavoriteBooruStateHolder(
          db: widget.db,
          build: (context, favoriteBooruState) {
            return GridPopScope(
              searchTextController: favoriteBooruState.searchTextController,
              filter: favoriteBooruState.filter,
              rootNavigatorPop: widget.procPop,
              child: GlueProvider(
                generate: GlueProvider.generateOf(context),
                child: FavoriteBooruPage(
                  wrapGridPage: true,
                  asSliver: false,
                  api: pagingState.api,
                  state: favoriteBooruState,
                  db: widget.db,
                ),
              ),
            );
          },
        ),
      BooruSubPage.bookmarks => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: BookmarkPage(
            pagingRegistry: widget.pagingRegistry,
            generateGlue: GlueProvider.generateOf(context),
            saveSelectedPage: _setSecondaryName,
            db: widget.db,
          ),
        ),
      BooruSubPage.hiddenPosts => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: BlacklistedPostsPage(
            generateGlue: GlueProvider.generateOf(context),
            db: widget.db.hiddenBooruPost,
          ),
        ),
    };
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

  final FavoritePostSourceService db;

  @override
  State<_LatestAndExcluded> createState() => __LatestAndExcludedState();
}

class __LatestAndExcludedState extends State<_LatestAndExcluded> {
  BooruTagging get excluded => widget.tagManager.excluded;
  BooruTagging get latest => widget.tagManager.latest;

  bool showExcluded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        title: Text(l10n.searchSinglePost),
                        content: SinglePost(
                          tagManager: widget.tagManager,
                          db: widget.db,
                        ),
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
                          title: Text(l10n.addToExcluded),
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
            child: Text(l10n.showExcludedTags),
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
