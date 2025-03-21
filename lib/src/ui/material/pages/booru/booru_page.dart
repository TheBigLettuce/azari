// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/services/resource_source/chained_filter.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/pages/booru/bookmark_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/booru/downloads.dart";
import "package:azari/src/ui/material/pages/booru/favorite_posts_page.dart";
import "package:azari/src/ui/material/pages/booru/hidden_posts.dart";
import "package:azari/src/ui/material/pages/booru/visited_posts.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/radio_dialog.dart";
import "package:azari/src/ui/material/pages/search/booru/booru_search_page.dart";
import "package:azari/src/ui/material/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/ui/material/widgets/common_grid_data.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/menu_wrapper.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
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

class _BooruPageState extends State<BooruPage>
    with CommonGridData<BooruPage>, BooruPageMixin {
  @override
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  @override
  HiddenBooruPostsService? get hiddenBooruPosts => widget.hiddenBooruPosts;
  @override
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  @override
  TagManagerService? get tagManager => widget.tagManager;
  @override
  DownloadManager? get downloadManager => widget.downloadManager;
  @override
  LocalTagsService? get localTags => widget.localTags;
  HottestTagsService? get hottestTags => widget.hottestTags;
  VisitedPostsService? get visitedPosts => widget.visitedPosts;

  @override
  GridDbService get gridDbs => widget.gridDbs;
  @override
  BooruChipsState get currentSubpage => pagingState.currentSubpage;

  @override
  SettingsService get settingsService => widget.settingsService;

  @override
  PagingStateRegistry get pagingRegistry => widget.pagingRegistry;

  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  void initState() {
    super.initState();

    watchSettings();
  }

  @override
  void onNewSettings(SettingsData prevSettings, SettingsData newSettings) {
    if (prevSettings.safeMode != newSettings.safeMode) {
      pagingState.popularStatus.clearRefresh();
      pagingState.videosStatus.clearRefresh();
      pagingState.randomStatus.clearRefresh();
    }
  }

  @override
  void openSecondaryBooruPage(GridBookmark e) {
    BooruRestoredPage.open(
      context,
      pagingRegistry: pagingRegistry,
      booru: e.booru,
      tags: e.tags,
      saveSelectedPage: setSecondaryName,
      name: e.name,
      rootNavigator: false,
    );
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
      saveSelectedPage: setSecondaryName,
      pagingRegistry: pagingRegistry,
      rootNavigator: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return switch (BooruSubPage.of(context)) {
      BooruSubPage.booru => pagingState.source.inject(
          _OnPopScope(
            searchTextController: null,
            filter: null,
            stackInjector: pagingState.stackInjector,
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

                              // setState(() {});
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
            saveSelectedPage: setSecondaryName,
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

class _OnPopScope extends StatefulWidget {
  const _OnPopScope({
    super.key,
    this.rootNavigatorPopCond = false,
    required this.searchTextController,
    required this.filter,
    this.rootNavigatorPop,
    required this.stackInjector,
    required this.child,
  });

  final bool rootNavigatorPopCond;

  final TextEditingController? searchTextController;
  final ChainedFilterResourceSource<dynamic, dynamic>? filter;

  final void Function(bool)? rootNavigatorPop;
  final BooruStackInjector stackInjector;

  final Widget child;

  @override
  State<_OnPopScope> createState() => _OnPopScopeState();
}

class _OnPopScopeState extends State<_OnPopScope> with ShellPopScopeMixin {
  @override
  ChainedFilterResourceSource<dynamic, dynamic>? get filter => widget.filter;

  @override
  void Function(bool)? get rootNavigatorPop => widget.rootNavigatorPop;

  @override
  bool get rootNavigatorPopCond => widget.rootNavigatorPopCond;

  @override
  TextEditingController? get searchTextController =>
      widget.searchTextController;

  late final StreamSubscription<BooruChipsState> chipsEvents;

  @override
  bool get canPop =>
      super.canPop && widget.stackInjector.chipsState == BooruChipsState.latest;

  @override
  void onPopInvoked(bool didPop, void _) {
    if (widget.stackInjector.chipsState != BooruChipsState.latest) {
      widget.stackInjector.updateChipsState(BooruChipsState.latest);
      return;
    }

    super.onPopInvoked(didPop, _);
  }

  @override
  void initState() {
    super.initState();

    chipsEvents = widget.stackInjector.stream.listen((e) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    chipsEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvoked,
      child: widget.child,
    );
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
