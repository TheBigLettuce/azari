// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
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
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:azari/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:azari/src/widgets/selection_actions.dart";
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
    required this.db,
    required this.procPop,
  });

  final PagingStateRegistry pagingRegistry;

  final void Function(bool) procPop;

  final DbConn db;

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage>
    with CommonGridData<Post, BooruPage> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  GridPostSource get source => pagingState.source;

  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> timeUpdater;
  late final StreamSubscription<void> hiddenPostWatcher;

  final menuController = MenuController();

  late final AppLifecycleListener lifecycleListener;

  late final _MainGridPagingState pagingState;

  bool inForeground = true;
  int? currentSkipped;

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(
      settings.selectedBooru.string,
      () {
        final mainGrid = widget.db.mainGrid(settings.selectedBooru);

        return _MainGridPagingState.prototype(
          widget.db.tagManager,
          hiddenBooruPost,
          mainGrid,
          settings.selectedBooru,
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
          final gridState = gridKey.currentState;
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

    if (pagingState.api.wouldBecomeStale &&
        pagingState.needToRefresh(const Duration(hours: 1))) {
      source.clear();

      pagingState.updateTime();
    }

    watchSettings();

    favoritesWatcher = favoritePosts.backingStorage.watch((event) {
      source.backingStorage.addAll([]);
    });

    hiddenPostWatcher = widget.db.hiddenBooruPost.watch((_) {
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
                db: DbConn.of(context),
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
    gridSettings.cancel();
    favoritesWatcher.cancel();
    hiddenPostWatcher.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  void _download(int i) => source
      .forIdx(i)
      ?.download(DownloadManager.of(context), PostTags.fromContext(context));

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

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
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
    final l10n = context.l10n();
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    return switch (BooruSubPage.of(context)) {
      BooruSubPage.booru => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: GridConfiguration(
            watch: gridSettings.watch,
            child: BooruAPINotifier(
              api: pagingState.api,
              child: OnBooruTagPressed(
                onPressed: _onBooruTagPressed,
                child: GridFrame<Post>(
                  key: gridKey,
                  slivers: [
                    _HottestTagNotifier(
                      api: pagingState.api,
                      randomNumber: gridSeed,
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
                  functionality: GridFunctionality(
                    selectionActions: SelectionActions.of(context),
                    scrollingSink: ScrollingSinkProvider.maybeOf(context),
                    scrollUpOn: navBarEvents == null
                        ? const []
                        : [(navBarEvents, null)],
                    settingsButton: GridSettingsButton.onlyHeader(
                      SafeModeButton(settingsWatcher: settings.s.watch),
                    ),
                    source: source,
                    search: RawSearchWidget(
                      (context, settingsButton, bottomWidget) => SliverAppBar(
                        pinned: true,
                        floating: true,
                        leading: Center(
                          child: IconButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            icon: const Icon(Icons.menu_rounded),
                          ),
                        ),
                        bottom: bottomWidget ??
                            PreferredSize(
                              preferredSize: const Size.fromHeight(56),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: SizedBox(
                                  height: 40,
                                  child: PopularRandomChips(
                                    db: widget.db,
                                    safeMode: () => settings.safeMode,
                                    booru: pagingState.booru,
                                    onTagPressed: _onBooruTagPressed,
                                    listPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        centerTitle: true,
                        title: IconButton(
                          onPressed: () => BooruSearchPage.open(context),
                          icon: const Icon(Icons.search_rounded),
                        ),
                        actions: [
                          if (settingsButton != null) settingsButton,
                        ],
                      ),
                    ),
                    download: _download,
                    updateScrollPosition: pagingState.setOffset,
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: _onBooruTagPressed,
                      child: BooruAPINotifier(
                        api: pagingState.api,
                        child: child,
                      ),
                    ),
                  ),
                  description: GridDescription(
                    actions: [
                      actions.downloadPost(
                          context, pagingState.api.booru, null),
                      actions.favorites(
                        context,
                        favoritePosts,
                        showDeleteSnackbar: true,
                      ),
                      actions.hide(context, hiddenBooruPost),
                    ],
                    animationsOnSourceWatch: false,
                    pageName: l10n.booruLabel,
                    gridSeed: gridSeed,
                  ),
                  initalScrollPosition: pagingState.offset,
                ),
              ),
            ),
          ),
        ),
      BooruSubPage.favorites => FavoritePostsPage(
          rootNavigatorPop: widget.procPop,
          db: widget.db,
        ),
      BooruSubPage.bookmarks => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: BookmarkPage(
            pagingRegistry: widget.pagingRegistry,
            saveSelectedPage: _setSecondaryName,
            db: widget.db,
          ),
        ),
      BooruSubPage.hiddenPosts => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: HiddenPostsPage(
            db: widget.db.hiddenBooruPost,
          ),
        ),
      BooruSubPage.downloads => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: DownloadsPage(
            downloadManager: DownloadManager.of(context),
            db: widget.db,
          ),
        ),
      BooruSubPage.visited => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: VisitedPostsPage(
            db: widget.db.visitedPosts,
          ),
        ),
    };
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

    final gridConfig = GridConfiguration.of(context);

    return switch (gridConfig.layoutType) {
      GridLayoutType.grid ||
      GridLayoutType.gridMasonry =>
        GridLayoutPlaceholder(description: widget.description),
      GridLayoutType.list =>
        ListLayoutPlaceholder(description: widget.description),
      GridLayoutType.gridQuilted => GridQuiltedLayoutPlaceholder(
          description: widget.description,
          randomNumber: widget.randomNumber,
        ),
    };
  }
}

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

  late final BooruAPI api = BooruAPI.fromEnum(booru, client);
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

class OpenMenuButton extends StatelessWidget {
  const OpenMenuButton({
    super.key,
    required this.controller,
    required this.booru,
    required this.launchGrid,
    required this.context,
  });

  final TextEditingController controller;
  final Booru booru;
  final BuildContext context;

  final OpenSearchCallback launchGrid;

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
  AppLocalizations l10n,
) =>
    PopupMenuItem(
      onTap: () {
        if (tag.isEmpty) {
          return;
        }

        context.openSafeModeDialog(
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
  });

  final BooruAPI api;
  final int randomNumber;

  @override
  Widget build(BuildContext context) {
    final notifier = GlobalProgressTab.maybeOf(context)?.hottestTags(api.booru);
    if (notifier == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return HottestTagsCarousel(
      db: DbConn.of(context),
      api: api,
      notifier: notifier,
      randomNumber: randomNumber,
    );
  }
}

class HottestTagsCarousel extends StatefulWidget {
  const HottestTagsCarousel({
    super.key,
    required this.db,
    required this.api,
    required this.notifier,
    required this.randomNumber,
  });

  final int randomNumber;

  final ValueNotifier<Future<void>?> notifier;

  final BooruAPI api;

  final DbConn db;

  @override
  State<HottestTagsCarousel> createState() => _HottestTagsCarouselState();
}

class _HottestTagsCarouselState extends State<HottestTagsCarousel> {
  late final StreamSubscription<void> subsc;
  late List<_HottestTagData> list;

  late final random = Random(widget.randomNumber);

  @override
  void initState() {
    super.initState();

    final refreshedAt = widget.db.hottestTags.refreshedAt(widget.api.booru);

    if (refreshedAt == null ||
        refreshedAt.add(const Duration(days: 3)).isBefore(DateTime.now())) {
      _loadHottestTags(widget.notifier, widget.db, widget.api);
    }

    widget.notifier.addListener(listener);

    list = loadAndFilter();

    subsc = widget.db.hottestTags.watch(widget.api.booru, (_) {
      setState(() {
        list = loadAndFilter();
      });
    });
  }

  List<_HottestTagData> loadAndFilter() {
    final all = widget.db.hottestTags.all(widget.api.booru);
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
                        overrideSafeMode: SettingsService.db().current.safeMode,
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
  DbConn db,
  BooruAPI api,
) async {
  if (notifier.value != null) {
    return;
  }

  return notifier.value = Future(() async {
    final res = <HottestTag>[];

    try {
      Random random;
      try {
        random = Random.secure();
      } catch (_) {
        random = Random(9538659403);
      }

      final tags =
          (await api.searchTag("")).fold(<String, BooruTag>{}, (map, e) {
        map[e.tag] = e;

        return map;
      });

      final localTags = db.localTagDictionary
          .mostFrequent(45)
          .where((e) => !tags.containsKey(e.tag))
          .take(15)
          .toList();

      final favoriteTags = db.tagManager.pinned
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
          db.tagManager.excluded,
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

      db.hottestTags.replace(res, api.booru);
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
