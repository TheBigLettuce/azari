// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as actions;
import "package:azari/src/pages/booru/bookmark_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/booru/downloads.dart";
import "package:azari/src/pages/booru/favorite_posts_page.dart";
import "package:azari/src/pages/booru/hidden_posts.dart";
import "package:azari/src/pages/booru/visited_posts.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/pages/other/settings/settings_page.dart";
import "package:azari/src/pages/search/booru/booru_search_page.dart";
import "package:azari/src/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

class BooruPage extends StatefulWidget {
  const BooruPage({
    super.key,
    required this.pagingRegistry,
    required this.procPop,
    required this.gridBookmarks,
    required this.hiddenBooruPosts,
    required this.favoritePosts,
    required this.settingsService,
    required this.tagManager,
    required this.gridDbs,
    required this.downloadManager,
    required this.localTags,
    required this.hottestTags,
    required this.gridSettings,
    required this.visitedPosts,
    required this.selectionController,
  });

  final PagingStateRegistry pagingRegistry;

  final void Function(bool) procPop;
  final SelectionController selectionController;

  final GridBookmarkService? gridBookmarks;
  final HiddenBooruPostsService? hiddenBooruPosts;
  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;
  final HottestTagsService? hottestTags;
  final GridSettingsService? gridSettings;
  final VisitedPostsService? visitedPosts;

  final GridDbService gridDbs;

  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) =>
      db.get<GridDbService>() != null;

  static Future<void> open(
    BuildContext context, {
    required PagingStateRegistry pagingRegistry,
    required void Function(bool) procPop,
  }) {
    final db = Services.of(context);
    final gridDbs = db.get<GridDbService>();
    if (gridDbs == null) {
      showSnackbar(
        context,
        "Booru functionality isn't available", // TODO: change
      );

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BooruPage(
          pagingRegistry: pagingRegistry,
          procPop: procPop,
          gridDbs: gridDbs,
          selectionController: SelectionActions.controllerOf(context),
          tagManager: db.get<TagManagerService>(),
          gridBookmarks: db.get<GridBookmarkService>(),
          hiddenBooruPosts: db.get<HiddenBooruPostsService>(),
          favoritePosts: db.get<FavoritePostSourceService>(),
          downloadManager: DownloadManager.of(context),
          localTags: db.get<LocalTagsService>(),
          hottestTags: db.get<HottestTagsService>(),
          gridSettings: db.get<GridSettingsService>(),
          visitedPosts: db.get<VisitedPostsService>(),
          settingsService: db.require<SettingsService>(),
        ),
      ),
    );
  }

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage> with CommonGridData<BooruPage> {
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  HiddenBooruPostsService? get hiddenBooruPosts => widget.hiddenBooruPosts;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;
  HottestTagsService? get hottestTags => widget.hottestTags;
  VisitedPostsService? get visitedPosts => widget.visitedPosts;

  GridDbService get gridDbs => widget.gridDbs;
  BooruChipsState get currentSubpage => pagingState.currentSubpage;

  @override
  SettingsService get settingsService => widget.settingsService;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  GridPostSource get source => pagingState.source;

  late final StreamSubscription<void>? favoritesWatcher;
  late final StreamSubscription<void>? hiddenPostWatcher;
  late final StreamSubscription<void> timeUpdater;

  final menuController = MenuController();

  late final AppLifecycleListener lifecycleListener;

  late final _MainGridPagingState pagingState;

  bool inForeground = true;
  int? currentSkipped;

  @override
  void onNewSettings(SettingsData prevSettings, SettingsData newSettings) {
    if (prevSettings.safeMode != newSettings.safeMode) {
      pagingState.popularStatus.clearRefresh();
      pagingState.videosStatus.clearRefresh();
      pagingState.randomStatus.clearRefresh();
    }
  }

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(
      settings.selectedBooru.string,
      () {
        final mainGrid = gridDbs.openMain(settings.selectedBooru);

        return _MainGridPagingState.prototype(
          settings.selectedBooru,
          mainGrid,
          gridBookmarks: gridBookmarks,
          tagManager: tagManager,
          hiddenBooruPosts: hiddenBooruPosts,
          settingsService: settingsService,
          selectionController: widget.selectionController,
          actions: [
            if (downloadManager != null && localTags != null)
              actions.downloadPost(
                context,
                settings.selectedBooru,
                null,
                downloadManager: downloadManager!,
                localTags: localTags!,
                settingsService: settingsService,
              ),
            if (favoritePosts != null)
              actions.favorites(
                context,
                favoritePosts!,
                showDeleteSnackbar: true,
              ),
            if (hiddenBooruPosts != null)
              actions.hide(context, hiddenBooruPosts!),
          ],
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
          source.clearRefresh();

          pagingState.updateTime();
        }
      },
    );

    timeUpdater = Stream<void>.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneralService.addTimeSpent(5.seconds.inMilliseconds);
      }
    });

    if (pagingState.api.wouldBecomeStale &&
        pagingState.needToRefresh(const Duration(hours: 1))) {
      source.clear();

      pagingState.updateTime();
    }

    watchSettings();

    favoritesWatcher = favoritePosts?.cache.countEvents.listen((event) {
      source.backingStorage.addAll([]);
    });

    hiddenPostWatcher = hiddenBooruPosts?.watch((_) {
      source.backingStorage.addAll([]);
      pagingState.randomStatus.source.backingStorage.addAll([]);
      pagingState.videosStatus.source.backingStorage.addAll([]);
      pagingState.popularStatus.source.backingStorage.addAll([]);
    });

    if (gridBookmarks != null && pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = gridBookmarks!.get(pagingState.restoreSecondaryGrid!)!;

        BooruRestoredPage.open(
          context,
          pagingRegistry: widget.pagingRegistry,
          booru: e.booru,
          tags: e.tags,
          saveSelectedPage: _setSecondaryName,
          name: e.name,
          rootNavigator: false,
        );
      });
    }
  }

  @override
  void dispose() {
    gridSettings.cancel();
    favoritesWatcher?.cancel();
    hiddenPostWatcher?.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  void _onBooruTagPressed(
    BuildContext context_,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    if (tag.isEmpty) {
      return;
    }

    ExitOnPressRoute.maybeExitOf(context_);

    BooruRestoredPage.open(
      context,
      booru: booru,
      tags: tag,
      overrideSafeMode: safeMode,
      saveSelectedPage: _setSecondaryName,
      pagingRegistry: widget.pagingRegistry,
      rootNavigator: false,
    );
  }

  // ignore: use_setters_to_change_properties
  void _setSecondaryName(String? name) {
    pagingState.restoreSecondaryGrid = name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    // final theme = Theme.of(context);

    return switch (BooruSubPage.of(context)) {
      BooruSubPage.booru => pagingState.source.inject(
          GridPopScope(
            searchTextController: null,
            filter: null,
            rootNavigatorPop: widget.procPop,
            child: BooruAPINotifier(
              api: pagingState.api,
              child: OnBooruTagPressed(
                onPressed: _onBooruTagPressed,
                child: ShellScope(
                  settingsButton: ShellSettingsButton.onlyHeader(
                    SafeModeButton(settingsWatcher: settingsService.watch),
                  ),
                  configWatcher: gridSettings.watch,
                  appBar: RawAppBarType(
                    (context, settingsButton, bottomWidget) => SliverAppBar(
                      pinned: true,
                      floating: true,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: const Icon(Icons.menu_rounded),
                      ),
                      bottom: bottomWidget,
                      title: const AppLogoTitle(),
                      actions: [
                        IconButton(
                          onPressed: () => BooruSearchPage.open(context),
                          icon: const Icon(Icons.search_rounded),
                        ),
                        if (settingsButton != null) settingsButton,
                        // IconButton(
                        //   onPressed: () {
                        //     Scaffold.of(context).openDrawer();
                        //   },
                        //   icon: const Icon(Icons.menu_rounded),
                        // ),
                      ],
                    ),
                  ),
                  searchBottomWidget: PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 40,
                        child: Builder(
                          builder: (context) => PopularRandomChips(
                            // safeMode: () => settings.safeMode,
                            // booru: pagingState.booru,
                            // onTagPressed: _onBooruTagPressed,
                            listPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            state: currentSubpage,
                            onPressed: (state) {
                              final scrollController =
                                  ShellScrollNotifier.maybeOf(context);

                              if (state == currentSubpage ||
                                  scrollController == null) {
                                return;
                              }

                              pagingState.currentSubpage = state;
                              pagingState.selectionController.setCount(0);

                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  stackInjector: pagingState.stackInjector,
                  elements: switch (currentSubpage) {
                    BooruChipsState.latest => [
                        ElementPriority(
                          PostsShellElement(
                            key: const ValueKey(BooruChipsState.latest),
                            status: pagingState.status,
                            initialScrollPosition: pagingState.offset,
                            updateScrollPosition: pagingState.setOffset,
                            overrideSlivers: [
                              if (hottestTags != null)
                                _HottestTagNotifier(
                                  api: pagingState.api,
                                  randomNumber: gridSeed,
                                  hottestTags: hottestTags!,
                                  tagManager: tagManager,
                                  localTags: localTags,
                                  settingsService: settingsService,
                                ),
                              Builder(
                                builder: (context) {
                                  final padding =
                                      MediaQuery.systemGestureInsetsOf(context);

                                  return SliverPadding(
                                    padding: EdgeInsets.only(
                                      left: padding.left * 0.2,
                                      right: padding.right * 0.2,
                                    ),
                                    sliver: CurrentGridSettingsLayout<Post>(
                                      source: source.backingStorage,
                                      progress: source.progress,
                                      gridSeed: gridSeed,
                                      selection: null,
                                      buildEmpty: (e) => EmptyWidgetWithButton(
                                        error: e,
                                        buttonText: l10n.openInBrowser,
                                        onPressed: () {
                                          launchUrl(
                                            Uri.https(
                                              pagingState.api.booru.url,
                                            ),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Builder(
                                builder: (context) {
                                  final padding =
                                      MediaQuery.systemGestureInsetsOf(context);

                                  return SliverPadding(
                                    padding: EdgeInsets.only(
                                      left: padding.left * 0.2,
                                      right: padding.right * 0.2,
                                    ),
                                    sliver: GridConfigPlaceholders(
                                      progress: source.progress,
                                      randomNumber: gridSeed,
                                    ),
                                  );
                                },
                              ),
                              GridFooter<void>(storage: source.backingStorage),
                            ],
                          ),
                        ),
                      ],
                    BooruChipsState.popular => [
                        ElementPriority(
                          PostsShellElement(
                            key: const ValueKey(BooruChipsState.popular),
                            updateScrollPosition:
                                pagingState.popularStatus.setOffset,
                            initialScrollPosition:
                                pagingState.popularStatus.localScrollOffset,
                            status: pagingState.popularStatus,
                          ),
                        ),
                      ],
                    BooruChipsState.random => [
                        ElementPriority(
                          PostsShellElement(
                            key: const ValueKey(BooruChipsState.random),
                            updateScrollPosition:
                                pagingState.randomStatus.setOffset,
                            initialScrollPosition:
                                pagingState.randomStatus.localScrollOffset,
                            status: pagingState.randomStatus,
                          ),
                        ),
                      ],
                    BooruChipsState.videos => [
                        ElementPriority(
                          PostsShellElement(
                            key: const ValueKey(BooruChipsState.videos),
                            updateScrollPosition:
                                pagingState.videosStatus.setOffset,
                            initialScrollPosition:
                                pagingState.videosStatus.localScrollOffset,
                            status: pagingState.videosStatus,
                          ),
                        ),
                      ],
                  },
                ),
              ),
            ),
          ),
        ),
      BooruSubPage.favorites => FavoritePostsPage(
          rootNavigatorPop: widget.procPop,
          gridSettings: widget.gridSettings!,
          favoritePosts: favoritePosts!,
          settingsService: settingsService,
          downloadManager: downloadManager,
          localTags: localTags,
          selectionController: widget.selectionController,
        ),
      BooruSubPage.bookmarks => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: BookmarkPage(
            pagingRegistry: widget.pagingRegistry,
            saveSelectedPage: _setSecondaryName,
            gridBookmarks: gridBookmarks!,
            gridDbs: gridDbs,
            selectionController: widget.selectionController,
            settingsService: settingsService,
          ),
        ),
      BooruSubPage.hiddenPosts => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: HiddenPostsPage(
            hiddenBooruPosts: hiddenBooruPosts!,
            settingsService: settingsService,
            selectionController: widget.selectionController,
          ),
        ),
      BooruSubPage.downloads => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: DownloadsPage(
            downloadManager: downloadManager!,
            settingsService: settingsService,
            selectionController: widget.selectionController,
          ),
        ),
      BooruSubPage.visited => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: VisitedPostsPage(
            visitedPosts: visitedPosts!,
            settingsService: settingsService,
            selectionController: widget.selectionController,
          ),
        ),
    };
  }
}

class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textBaseline: TextBaseline.ideographic,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.87),
            shape: BoxShape.circle,
          ),
          child: Transform.rotate(
            angle: 0.4363323,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                "阿",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  fontFamily: "KiwiMaru",
                ),
              ),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(right: 8)),
        Text(
          "アザリ", // TODO: show 아사리 when Korean locale, consider showing Hanzi variations for Chinese locales 阿闍梨
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: "NotoSerif",
          ),
        ),
      ],
    );
  }
}

class GridConfigPlaceholders extends StatefulWidget {
  const GridConfigPlaceholders({
    super.key,
    required this.progress,
    this.description = const CellStaticData(),
    required this.randomNumber,
  });

  final CellStaticData description;
  final int randomNumber;
  final RefreshingProgress progress;

  @override
  State<GridConfigPlaceholders> createState() => _GridConfigPlaceholdersState();
}

class _GridConfigPlaceholdersState extends State<GridConfigPlaceholders> {
  late final StreamSubscription<bool> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.progress.inRefreshing) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    final gridConfig = ShellConfiguration.of(context);

    return switch (gridConfig.layoutType) {
      GridLayoutType.grid ||
      GridLayoutType.list =>
        ListLayoutPlaceholder(description: widget.description),
      GridLayoutType.gridQuilted => GridQuiltedLayoutPlaceholder(
          description: widget.description,
          randomNumber: widget.randomNumber,
        ),
    };
  }
}

class _CurrentPageRefreshIndicator extends StatefulWidget {
  const _CurrentPageRefreshIndicator({
    super.key,
    required this.initialValue,
    required this.stream,
    required this.latest,
    required this.video,
    required this.popular,
    required this.random,
    required this.child,
  });

  final Stream<BooruChipsState> stream;
  final BooruChipsState initialValue;

  final SourceShellElementState<Post> latest;
  final SourceShellElementState<Post> video;
  final SourceShellElementState<Post> popular;
  final SourceShellElementState<Post> random;

  final Widget child;

  @override
  State<_CurrentPageRefreshIndicator> createState() =>
      __CurrentPageRefreshIndicatorState();
}

class __CurrentPageRefreshIndicatorState
    extends State<_CurrentPageRefreshIndicator> {
  late final StreamSubscription<BooruChipsState> _events;
  late BooruChipsState value;

  @override
  void initState() {
    super.initState();

    value = widget.initialValue;

    _events = widget.stream.listen((e) {
      if (e == value) {
        return;
      }

      setState(() {
        value = e;
      });
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (value) {
      BooruChipsState.latest => widget.latest,
      BooruChipsState.popular => widget.popular,
      BooruChipsState.random => widget.random,
      BooruChipsState.videos => widget.video,
    };

    return SourceShellRefreshIndicator(
      selection: status.selection,
      source: status.source,
      child: widget.child,
    );
  }
}

class _StackInjector implements ShellScopeOverlayInjector {
  _StackInjector(
    this.stream,
    this.chipsState,
    this.latest,
    this.video,
    this.popular,
    this.random,
    this.selectionController,
  );

  final SelectionController selectionController;

  final Stream<BooruChipsState> stream;
  BooruChipsState chipsState;

  final SourceShellElementState<Post> latest;
  final SourceShellElementState<Post> video;
  final SourceShellElementState<Post> popular;
  final SourceShellElementState<Post> random;

  @override
  List<Widget> injectStack(BuildContext context) {
    return const [];
  }

  @override
  OnEmptyInterface get onEmpty => const OnEmptyInterface.empty();

  @override
  Widget wrapChild(Widget child) {
    return ShellSelectionCountHolder(
      key: null,
      selection: latest.selection,
      controller: selectionController,
      child: _CurrentPageRefreshIndicator(
        initialValue: chipsState,
        latest: latest,
        popular: popular,
        random: random,
        video: video,
        stream: stream,
        child: child,
      ),
    );
  }

  @override
  double tryCalculateScrollSizeToItem(
    double contentSize,
    int idx,
    GridLayoutType layoutType,
    GridColumn columns,
  ) {
    final source = switch (chipsState) {
      BooruChipsState.latest => latest.source,
      BooruChipsState.popular => popular.source,
      BooruChipsState.random => random.source,
      BooruChipsState.videos => video.source,
    };

    if (layoutType == GridLayoutType.list) {
      return contentSize * idx / source.count;
    } else {
      return contentSize *
          (idx / columns.number - 1) /
          (source.count / columns.number);
    }
  }
}

class _MainGridPagingState implements PagingEntry {
  _MainGridPagingState(
    HiddenBooruPostsService? hiddenBooruPosts,
    this.booru,
    this.tagManager,
    this.mainGrid,
    this.gridBookmarks,
    this.settingsService,
    this.actions,
    this.selectionController,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    source = mainGrid.makeSource(
      api,
      this,
      hiddenBooruPosts: hiddenBooruPosts,
      excluded: tagManager?.excluded,
    );

    status = SourceShellElementState(
      onEmpty: const OnEmptyInterface.empty(),
      source: source,
      selectionController: selectionController,
      actions: actions,
    );

    stackInjector = _StackInjector(
      _subpageEvents.stream,
      BooruChipsState.latest,
      status,
      videosStatus,
      popularStatus,
      randomStatus,
      selectionController,
    );
  }

  factory _MainGridPagingState.prototype(
    Booru booru,
    MainGridHandle mainGrid, {
    required TagManagerService? tagManager,
    required HiddenBooruPostsService? hiddenBooruPosts,
    required GridBookmarkService? gridBookmarks,
    required SettingsService settingsService,
    required SelectionController selectionController,
    required List<SelectionBarAction> actions,
  }) =>
      _MainGridPagingState(
        hiddenBooruPosts,
        booru,
        tagManager,
        mainGrid,
        gridBookmarks,
        settingsService,
        actions,
        selectionController,
      );

  final Booru booru;

  @override
  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru, client);
  final TagManagerService? tagManager;
  final Dio client;
  late final GridPostSource source;
  final MainGridHandle mainGrid;
  final GridBookmarkService? gridBookmarks;
  final SelectionController selectionController;
  final List<SelectionBarAction> actions;
  late final _StackInjector stackInjector;

  final SettingsService settingsService;

  final popularPageSaver = PageSaver.noPersist();
  final videosPageSaver = PageSaver.noPersist();
  final randomPageSaver = PageSaver.noPersist();

  final _subpageEvents = StreamController<BooruChipsState>.broadcast();

  BooruChipsState get currentSubpage => stackInjector.chipsState;
  set currentSubpage(BooruChipsState s) {
    stackInjector.chipsState = s;
    _subpageEvents.add(s);
  }

  late final SourceShellElementState<Post> status;
  // late final

  late final popularStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        popularPageSaver.page = 0;

        final ret = await api.page(
          popularPageSaver.page,
          "",
          tagManager?.excluded,
          settingsService.current.safeMode,
          order: BooruPostsOrder.score,
          pageSaver: popularPageSaver,
        );

        return ret.$1;
      },
      next: () async {
        final ret = await api.page(
          popularPageSaver.page + 1,
          "",
          tagManager?.excluded,
          settingsService.current.safeMode,
          order: BooruPostsOrder.score,
          pageSaver: popularPageSaver,
        );

        return ret.$1;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

  late final videosStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        videosPageSaver.page = 0;

        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: settingsService.current.randomVideosAddTags,
          page: videosPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: settingsService.current.randomVideosAddTags,
          page: videosPageSaver.page + 1,
        );

        videosPageSaver.page += 1;

        return ret;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

  late final randomStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        randomPageSaver.page = 0;

        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          false,
          page: randomPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          false,
          page: randomPageSaver.page + 1,
        );

        randomPageSaver.page += 1;

        return ret;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

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
  void setOffset(double o) {
    mainGrid.currentState.copy(offset: o).save(mainGrid);
  }

  @override
  void dispose() {
    client.close();
    source.destroy();
    status.destroy();

    _subpageEvents.close();

    popularStatus.source.destroy();
    popularStatus.destroy();

    videosStatus.source.destroy();
    videosStatus.destroy();

    randomStatus.source.destroy();
    randomStatus.destroy();
  }
}

class OnBooruTagPressed extends InheritedWidget {
  const OnBooruTagPressed({
    super.key,
    required this.onPressed,
    required super.child,
  });

  final OnBooruTagPressedFunc onPressed;

  static OnBooruTagPressedFunc of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    return widget!.onPressed;
  }

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

class OpenMenuButton extends StatelessWidget {
  const OpenMenuButton({
    super.key,
    required this.controller,
    required this.booru,
    required this.launchGrid,
    required this.context,
    required this.settingsService,
  });

  final TextEditingController controller;
  final Booru booru;
  final BuildContext context;

  final OpenSearchCallback launchGrid;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return PopupMenuButton(
      itemBuilder: (_) {
        return MenuWrapper.menuItems(context, controller.text, true, [
          launchGridSafeModeItem(
            context,
            controller.text,
            launchGrid,
            l10n,
            settingsService: settingsService,
          ),
        ]);
      },
    );
  }
}

PopupMenuItem<void> launchGridSafeModeItem(
  BuildContext context,
  String tag,
  OpenSearchCallback launchGrid,
  AppLocalizations l10n, {
  required SettingsService settingsService,
}) =>
    PopupMenuItem(
      onTap: () {
        if (tag.isEmpty) {
          return;
        }

        context.openSafeModeDialog(
          settingsService,
          (value) => launchGrid(context, tag, value),
        );
      },
      child: Text(l10n.searchWithSafeMode),
    );

class _HottestTagNotifier extends StatelessWidget {
  const _HottestTagNotifier({
    // super.key,
    required this.api,
    required this.randomNumber,
    required this.hottestTags,
    required this.tagManager,
    required this.settingsService,
    required this.localTags,
  });

  final BooruAPI api;
  final int randomNumber;

  final TagManagerService? tagManager;
  final LocalTagsService? localTags;

  final HottestTagsService hottestTags;
  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final notifier = GlobalProgressTab.maybeOf(context)?.hottestTags(api.booru);
    if (notifier == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return HottestTagsCarousel(
      api: api,
      notifier: notifier,
      randomNumber: randomNumber,
      hottestTags: hottestTags,
      tagManager: tagManager,
      localTags: localTags,
      settingsService: settingsService,
    );
  }
}

class HottestTagsCarousel extends StatefulWidget {
  const HottestTagsCarousel({
    super.key,
    required this.api,
    required this.notifier,
    required this.randomNumber,
    required this.hottestTags,
    required this.tagManager,
    required this.settingsService,
    required this.localTags,
  });

  final int randomNumber;

  final ValueNotifier<Future<void>?> notifier;

  final BooruAPI api;

  final TagManagerService? tagManager;
  final LocalTagsService? localTags;

  final HottestTagsService hottestTags;
  final SettingsService settingsService;

  @override
  State<HottestTagsCarousel> createState() => _HottestTagsCarouselState();
}

class _HottestTagsCarouselState extends State<HottestTagsCarousel> {
  HottestTagsService get hottestTags => widget.hottestTags;
  TagManagerService? get tagManager => widget.tagManager;

  SettingsService get settingsService => widget.settingsService;

  late final StreamSubscription<void> subsc;
  late List<_HottestTagData> list;

  late final random = math.Random(widget.randomNumber);

  @override
  void initState() {
    super.initState();

    final refreshedAt = hottestTags.refreshedAt(widget.api.booru);

    if (refreshedAt == null ||
        refreshedAt.add(const Duration(days: 3)).isBefore(DateTime.now())) {
      if (widget.localTags != null && tagManager != null) {
        _loadHottestTags(
          widget.notifier,
          widget.api,
          hottestTags: hottestTags,
          localTagsService: widget.localTags!,
          tagManager: tagManager!,
        );
      }
    }

    widget.notifier.addListener(listener);

    list = loadAndFilter();

    subsc = hottestTags.watch(widget.api.booru, (_) {
      setState(() {
        list = loadAndFilter();
      });
    });
  }

  List<_HottestTagData> loadAndFilter() {
    final all = hottestTags.all(widget.api.booru);
    final ret = <_HottestTagData>[];
    final m = <String, void>{};

    for (final tag in all) {
      final urlList = tag.thumbUrls.toList()..shuffle(random);
      if (urlList.isEmpty) {
        continue;
      }

      if (urlList.length == 1) {
        final urlRating = urlList.first;

        ret.add(
          _HottestTagData(
            postId: urlRating.postId,
            tag: tag.tag,
            count: tag.count,
            thumbUrl: urlRating.url,
          ),
        );
      } else {
        var first = urlList.first;
        for (final url in urlList) {
          if (m.containsKey(url.url)) {
            continue;
          } else {
            m[url.url] = null;

            first = url;
          }
        }

        ret.add(
          _HottestTagData(
            postId: first.postId,
            tag: tag.tag,
            count: tag.count,
            thumbUrl: first.url,
          ),
        );
      }
    }

    return ret..shuffle(random);
  }

  @override
  void dispose() {
    subsc.cancel();
    widget.notifier.removeListener(listener);

    super.dispose();
  }

  void listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifier.value != null && list.isEmpty) {
      return SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: 160 * GridAspectRatio.oneFive.value),
          child: CarouselView.weighted(
            itemSnapping: true,
            flexWeights: const [3, 2, 1],
            shrinkExtent: 200,
            children: List.generate(30, (i) => const ShimmerLoadingIndicator()),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.zero,
      );
    }

    final theme = Theme.of(context);

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: 160 * GridAspectRatio.oneFive.value),
          child: CarouselView.weighted(
            enableSplash: false,
            itemSnapping: true,
            flexWeights: const [3, 2, 1],
            shrinkExtent: 200,
            children: list.map<Widget>((tag) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  HottestTagWidget(
                    tag: tag,
                    booru: widget.api.booru,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => OnBooruTagPressed.maybePressOf(
                        context,
                        tag.tag,
                        widget.api.booru,
                        overrideSafeMode: settingsService.current.safeMode,
                      ),
                      onLongPress: () => Post.imageViewSingle(
                        context,
                        widget.api.booru,
                        tag.postId,
                      ),
                      overlayColor: WidgetStateProperty.resolveWith(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return theme.colorScheme.onSurface
                              .withValues(alpha: 0.1);
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return theme.colorScheme.onSurface
                              .withValues(alpha: 0.08);
                        }
                        if (states.contains(WidgetState.focused)) {
                          return theme.colorScheme.onSurface
                              .withValues(alpha: 0.1);
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _HottestTagData {
  const _HottestTagData({
    required this.postId,
    required this.tag,
    required this.count,
    required this.thumbUrl,
  });

  final int postId;
  final int count;

  final String tag;
  final String thumbUrl;
}

class HottestTagWidget extends StatelessWidget {
  const HottestTagWidget({
    super.key,
    required this.tag,
    required this.booru,
  });

  final _HottestTagData tag;
  final Booru booru;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Image(
          color: Colors.black.withValues(alpha: 0.15),
          colorBlendMode: BlendMode.darken,
          image: CachedNetworkImageProvider(tag.thumbUrl),
          frameBuilder: (
            context,
            child,
            frame,
            wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded) {
              return child;
            }

            return frame == null
                ? const ShimmerLoadingIndicator()
                : child.animate().fadeIn();
          },
          alignment: Alignment.topCenter,
          fit: BoxFit.cover,
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
              left: 14,
            ),
            child: Text(
              tag.tag,
              maxLines: 1,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension HottestTagsProgress on GlobalProgressTab {
  ValueNotifier<Future<void>?> hottestTags(Booru booru) =>
      get("hottestTags${booru.string}", () => ValueNotifier(null));
}

Future<void> _loadHottestTags(
  ValueNotifier<Future<void>?> notifier,
  BooruAPI api, {
  required HottestTagsService hottestTags,
  required LocalTagsService localTagsService,
  required TagManagerService tagManager,
}) async {
  if (notifier.value != null) {
    return;
  }

  return notifier.value = Future(() async {
    final res = <HottestTag>[];

    try {
      math.Random random;
      try {
        random = math.Random.secure();
      } catch (_) {
        random = math.Random(9538659403);
      }

      final tags =
          (await api.searchTag("")).fold(<String, BooruTag>{}, (map, e) {
        map[e.tag] = e;

        return map;
      });

      final localTags = localTagsService
          .mostFrequent(45)
          .where((e) => !tags.containsKey(e.tag))
          .take(15)
          .toList();

      final favoriteTags = tagManager.pinned
          .get(130)
          .where((e) => !tags.containsKey(e.tag))
          .toList()
        ..shuffle(random);

      for (final tag in localTags.isNotEmpty
          ? tags.values
              .take(tags.length - localTags.length)
              .followedBy(localTags)
              .followedBy(favoriteTags.take(5).map((e) => BooruTag(e.tag, 1)))
          : tags.values.followedBy(
              favoriteTags.take(5).map((e) => BooruTag(e.tag, 1)),
            )) {
        final posts = await api.page(
          0,
          tag.tag,
          tagManager.excluded,
          SafeMode.normal,
          limit: 15,
          pageSaver: PageSaver.noPersist(),
        );

        res.add(
          HottestTag(tag: tag.tag, count: tag.count, booru: api.booru).copy(
            thumbUrls: posts.$1
                .map(
                  (post) => ThumbUrlRating(
                    postId: post.id,
                    url: post.previewUrl,
                    rating: post.rating,
                  ),
                )
                .toList(),
          ),
        );
      }

      hottestTags.replace(res, api.booru);
    } catch (e, trace) {
      Logger.root.severe("loadHottestTags", e, trace);
    } finally {
      notifier.value = null;
    }

    return;
  });
}

class BooruAPINotifier extends InheritedWidget {
  const BooruAPINotifier({
    super.key,
    required this.api,
    required super.child,
  });

  final BooruAPI api;

  static BooruAPI of(BuildContext context) {
    return maybeOf(context)!;
  }

  static BooruAPI? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<BooruAPINotifier>();

    return widget?.api;
  }

  @override
  bool updateShouldNotify(BooruAPINotifier oldWidget) {
    return api != oldWidget.api;
  }
}
