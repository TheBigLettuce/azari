// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/home/downloads.dart";
import "package:azari/src/ui/material/pages/home/favorite_posts_page.dart";
import "package:azari/src/ui/material/pages/home/hidden_posts.dart";
import "package:azari/src/ui/material/pages/search/booru/booru_search_page.dart";
import "package:azari/src/ui/material/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/ui/material/widgets/adaptive_page.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/list_tile_list_styled.dart";
import "package:azari/src/ui/material/widgets/menu_wrapper.dart";
import "package:azari/src/ui/material/widgets/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/scaling_right_menu.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/quilted_grid.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";

class BooruPage extends StatefulWidget {
  const BooruPage({
    super.key,
    required this.pagingRegistry,
    required this.procPop,
    required this.selectionController,
  });

  final PagingStateRegistry pagingRegistry;

  final void Function(bool) procPop;
  final SelectionController selectionController;

  static bool hasServicesRequired() => GridDbService.available;

  static Future<void> open(
    BuildContext context, {
    required PagingStateRegistry pagingRegistry,
    required void Function(bool) procPop,
  }) {
    if (!hasServicesRequired()) {
      addAlert(
        "BooruPage",
        "Booru functionality isn't available", // TODO: change
      );

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BooruPage(
          pagingRegistry: pagingRegistry,
          procPop: procPop,
          selectionController: SelectionActions.controllerOf(context),
        ),
      ),
    );
  }

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage>
    with SettingsWatcherMixin, BooruPageMixin {
  @override
  BooruChipsState get currentSubpage => pagingState.currentSubpage;

  @override
  PagingStateRegistry get pagingRegistry => widget.pagingRegistry;

  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  void onNewSettings({
    required SettingsData newSettings,
    required SettingsData oldSettings,
  }) {
    if (oldSettings.safeMode != newSettings.safeMode) {
      if (pagingState.popularStatus.isNotEmpty) {
        pagingState.popularStatus.clearRefresh();
      }

      if (pagingState.videosStatus.isNotEmpty) {
        pagingState.videosStatus.clearRefresh();
      }

      if (pagingState.randomStatus.isNotEmpty) {
        pagingState.randomStatus.clearRefresh();
      }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return ScalingRightMenu(
      menuContent: BookmarksMenuBooru(
        selectionController: widget.selectionController,
      ),
      child: switch (BooruSubPage.of(context)) {
        BooruSubPage.booru => pagingState.source.inject(
          BooruPageOnPopScope(
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
                    SafeModeButtonSettings(
                      settingsWatcher: const SettingsService().watch,
                    ),
                  ),
                  appBar: RawAppBarType(
                    (context, settingsButton, bottomWidget) => SliverAppBar(
                      pinned: true,
                      floating: true,
                      backgroundColor: theme.colorScheme.surface.withValues(
                        alpha: 1,
                      ),
                      scrolledUnderElevation: 0,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: const Icon(Icons.menu_rounded),
                      ),
                      bottom: bottomWidget,
                      title: Center(
                        child: GestureDetector(
                          onTap: () => BooruSearchPage.open(context),
                          child: AbsorbPointer(
                            child: Hero(
                              tag: "searchBarAnchor",
                              child: SearchBar(
                                leading: BooruLetterIcon(
                                  booru: settings.selectedBooru,
                                ),
                                elevation: const WidgetStatePropertyAll(0),
                                hintText: l10n.searchHintBooru,
                                constraints: const BoxConstraints(
                                  minWidth: 360,
                                  maxWidth: 460,
                                  minHeight: 34,
                                  maxHeight: 34,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () {
                              ScalingRightMenu.maybeOf(context)?.open();
                            },
                            icon: const Icon(Icons.bookmarks_outlined),
                          ),
                        ),
                        if (settingsButton != null) settingsButton,
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
                          gridSettings: gridSettings,
                          status: pagingState.status,
                          initialScrollPosition: pagingState.offset,
                          updateScrollPosition: pagingState.setOffset,
                          overrideSlivers: [
                            if (HottestTagsService.available)
                              HottestTagsCarousel(api: pagingState.api),
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
                                    // gridSeed: gridSeed,
                                    selection: null,
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
                                    // randomNumber: gridSeed,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    BooruChipsState.popular => [
                      ElementPriority(
                        PostsShellElement(
                          gridSettings: gridSettings,
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
                          gridSettings: gridSettings,
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
                          gridSettings: gridSettings,
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
          selectionController: widget.selectionController,
        ),
        BooruSubPage.downloads => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: DownloadsPage(selectionController: widget.selectionController),
        ),
        BooruSubPage.more => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: widget.procPop,
          child: MorePage(selectionController: widget.selectionController),
        ),
      },
    );
  }
}

class BookmarksMenuBooru extends StatefulWidget {
  const BookmarksMenuBooru({super.key, required this.selectionController});

  final SelectionController selectionController;

  @override
  State<BookmarksMenuBooru> createState() => _BookmarksMenuBooruState();
}

class _BookmarksMenuBooruState extends State<BookmarksMenuBooru> {
  final PageController pageController = PageController(viewportFraction: 0.8);

  final StreamController<void> _updates = StreamController.broadcast();
  late final StreamSubscription<void> _updatesEvents;

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  String? currentPage;

  late final ClusteredSource source;

  @override
  void initState() {
    super.initState();

    const gridBookmarks = GridBookmarkService();

    _updatesEvents = _updates.stream.listen((_) {
      setState(() {});
    });

    source = ClusteredSource(
      gridBookmarks,
      const SettingsService(),
      _updates.sink,
      widget.selectionController,
      gridSettings,
    )..refresh(gridBookmarks);
  }

  @override
  void dispose() {
    _updatesEvents.cancel();
    _updates.close();
    source.dispose();
    pageController.dispose();
    gridSettings.cancel();

    super.dispose();
  }

  void launchGrid(BuildContext context, GridBookmark e) {
    currentPage = e.name;

    BooruRestoredPage.open(
      context,
      booru: e.booru,
      tags: e.tags,
      name: e.name,
    ).whenComplete(() => currentPage = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return source.sources.isEmpty ||
            source.sources.fold(true, (v, e) {
              return v && e.backingStorage.isEmpty;
            })
        ? EmptyWidgetBackground(subtitle: l10n.noBookmarks)
        : SingleChildScrollView(
            child: Column(
              spacing: 16,
              children: source.sourcesBooru
                  .where((e) => e.value.source.backingStorage.isNotEmpty)
                  .map((eBooru) {
                    final booru = eBooru.key;
                    final (source: e, state: _) = eBooru.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              booru.string,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(bottom: 12)),
                        ListTileListBodyStyled(
                          children: e.backingStorage.map((bookmark) {
                            final thumbnailData = bookmark.thumbnails.isEmpty
                                ? null
                                : bookmark.thumbnails.first;

                            return ListTile(
                              onTap: () => launchGrid(context, bookmark),
                              trailing: IconButton(
                                onPressed: () => const GridBookmarkService()
                                    .delete(bookmark.name),
                                icon: const Icon(Icons.bookmark_remove_rounded),
                              ),
                              leading: SizedBox.square(
                                dimension: 48,
                                child: GridCellImage(
                                  blur:
                                      thumbnailData?.rating ==
                                          PostRating.explicit ||
                                      thumbnailData?.rating ==
                                          PostRating.questionable,
                                  imageAlign: Alignment.center,
                                  thumbnail: thumbnailData == null
                                      ? MemoryImage(kTransparentImage)
                                      : CachedNetworkImageProvider(
                                          thumbnailData.url,
                                        ),
                                ),
                              ),
                              title: Text(
                                bookmark.tags,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                l10n.date(bookmark.time),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  })
                  .toList(),
            ),
          );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key, required this.selectionController});

  final SelectionController selectionController;

  static bool hasServicesRequired() => GridBookmarkService.available;

  @override
  State<MorePage> createState() => MoreStatePage();
}

class MoreStatePage extends State<MorePage>
    with
        SettingsWatcherMixin,
        VisitedPostsService,
        SingleTickerProviderStateMixin {
  late final StreamSubscription<void> _safeModeEvents;

  late final sourceVisited = GenericListSource<VisitedPost>(
    () => Future.value(
      all.where((e) => safeMode.current.inLevelPostRating(e.rating)).toList(),
    ),
    watchCount: const VisitedPostsService().watch,
  );

  late final int _randomNumber;

  late final AnimationController animationController;
  late final SafeModeState safeMode;

  late final _StackState status;

  final gridSettingsVisited = CancellableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.six,
    layoutType: GridLayoutType.list,
  );

  late final SourceShellElementState<VisitedPost> stateVisited;

  @override
  void initState() {
    super.initState();

    _randomNumber = math.Random().nextInt(90_000);

    animationController = AnimationController(
      vsync: this,
      duration: Durations.long1,
      reverseDuration: Durations.medium1,
      value: 1,
    );

    safeMode = SafeModeState(settings.safeMode);

    _safeModeEvents = safeMode.events.listen((_) {
      sourceVisited.clearRefresh();
    });

    status = _StackState(
      SourceOnEmptyInterface(
        sourceVisited,
        (context) => context.l10n().emptyPostsVisited,
      ),
    );

    stateVisited = SourceShellElementState(
      source: sourceVisited,
      selectionController: widget.selectionController,
      actions: [
        SelectionBarAction(
          Icons.remove_rounded,
          (selected) => removeAll(selected.cast()),
          true,
        ),
      ],
      gridSettings: gridSettingsVisited,
    );
  }

  @override
  void dispose() {
    _safeModeEvents.cancel();
    safeMode.dispose();
    animationController.dispose();
    stateVisited.destroy();
    gridSettingsVisited.cancel();
    status.dispose();
    sourceVisited.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ShellScope(
      stackInjector: status,
      appBar: TitleAppBarType(
        title: l10n.more,
        trailingItems: HiddenPostsPage.hasServicesRequired()
            ? [
                IconButton(
                  onPressed: () => HiddenPostsPage.open(context),
                  icon: const Icon(Icons.hide_image_outlined),
                ),
              ]
            : null,
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      elements: [
        ElementPriority(
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: Builder(
                      builder: (context) {
                        final l10n = context.l10n();
                        final theme = Theme.of(context);

                        final gestureInsets = MediaQuery.systemGestureInsetsOf(
                          context,
                        );

                        final padding = EdgeInsets.only(
                          right: gestureInsets.right > 0
                              ? gestureInsets.right / 2
                              : 0,
                          left: gestureInsets.left > 0
                              ? gestureInsets.left / 2
                              : 0,
                        );

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12) +
                              padding,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 4,
                            children: [
                              Text(
                                l10n.visitedPage,
                                style: theme.textTheme.titleMedium,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SafeModeButton(safeMode: safeMode),
                                  IconButton(
                                    onPressed: () {
                                      animationController.reverse().then((_) {
                                        clear();
                                        animationController.forward();
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          hideOnEmpty: false,
        ),
        ElementPriority(
          AnimatedBuilder(
            animation: animationController.view,
            builder: (context, child) => SliverOpacity(
              opacity: Easing.emphasizedAccelerate.transform(
                animationController.value,
              ),
              sliver: ShellElement(
                state: stateVisited,
                gridSettings: gridSettingsVisited,
                slivers: [
                  QuiltedGridLayout<VisitedPost>(
                    source: sourceVisited.backingStorage,
                    progress: sourceVisited.progress,
                    selection: stateVisited.selection,
                    randomNumber: _randomNumber,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StackState extends ShellScopeOverlayInjector {
  _StackState(this.onEmpty);

  @override
  List<Widget> injectStack(BuildContext context) => const [];

  @override
  final OnEmptyInterface onEmpty;

  @override
  double tryCalculateScrollSizeToItem(double contentSize, int idx) => 0;

  @override
  Widget wrapChild(Widget child) {
    return child;
  }

  void dispose() {}
}

class BooruPageOnPopScope extends StatefulWidget {
  const BooruPageOnPopScope({
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
  State<BooruPageOnPopScope> createState() => _BooruPageOnPopScopeState();
}

class _BooruPageOnPopScopeState extends State<BooruPageOnPopScope>
    with ShellPopScopeMixin {
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

    super.onPopInvoked(didPop, null);
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

class BooruLetterIcon extends StatelessWidget {
  const BooruLetterIcon({super.key, required this.booru});

  final Booru booru;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.87),
        shape: BoxShape.circle,
      ),
      child: Transform.rotate(
        angle: 0.4363323,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            booru.string[0],
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
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
    );
  }
}

class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textBaseline: TextBaseline.ideographic,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const AppLogoIcon(),
        const Padding(padding: EdgeInsets.only(right: 8)),
        Text(
          "アザリ", // TODO: show 아사리 when Korean locale, consider showing Hanzi variations for Chinese locales 阿闍梨
          style: theme.textTheme.titleLarge?.copyWith(fontFamily: "NotoSerif"),
        ),
      ],
    );
  }
}

class GridConfigPlaceholders extends StatefulWidget {
  const GridConfigPlaceholders({
    super.key,
    required this.progress,
    this.randomNumber = 2,
  });

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
      GridLayoutType.grid => const GridLayoutPlaceholder(),
      GridLayoutType.list => const ListLayoutPlaceholder(),
      GridLayoutType.gridQuilted => GridQuiltedLayoutPlaceholder(
        randomNumber: widget.randomNumber,
        circle: false,
        tightMode: false,
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

  static OnBooruTagPressedFunc of(BuildContext context) => maybeOf(context)!;

  static OnBooruTagPressedFunc? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    return widget?.onPressed;
  }

  static void pressOf(
    BuildContext context,
    String tag,
    Booru booru, {
    SafeMode? overrideSafeMode,
  }) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    widget!.onPressed(context, booru, tag, overrideSafeMode);
  }

  static void maybePressOf(
    BuildContext context,
    String tag,
    Booru booru, {
    SafeMode? overrideSafeMode,
  }) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

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
          launchGridSafeModeItem(context, controller.text, launchGrid, l10n),
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
) => PopupMenuItem(
  onTap: () {
    if (tag.isEmpty) {
      return;
    }

    context.openSafeModeDialog((value) => launchGrid(context, tag, value));
  },
  child: Text(l10n.searchWithSafeMode),
);

class HottestTagsCarousel extends StatefulWidget {
  const HottestTagsCarousel({
    super.key,
    required this.api,
    this.randomNumber = 2,
  });

  final int randomNumber;

  final BooruAPI api;

  @override
  State<HottestTagsCarousel> createState() => _HottestTagsCarouselState();
}

class _HottestTagsCarouselState extends State<HottestTagsCarousel>
    with HottestTagsService {
  late final StreamSubscription<void> _events;
  late List<_HottestTagData> list;

  late final random = math.Random(widget.randomNumber);

  @override
  void initState() {
    super.initState();

    final time = refreshedAt(widget.api.booru);
    if (time == null ||
        time.add(const Duration(days: 3)).isBefore(DateTime.now())) {
      const TasksService().add<HottestTagsCarousel>(
        () => _loadHottestTags(widget.api),
      );
    }

    list = loadAndFilter();

    _events = watch(widget.api.booru, (_) {
      setState(() {
        list = loadAndFilter();
      });
    });
  }

  List<_HottestTagData> loadAndFilter() {
    final ret = <_HottestTagData>[];
    final m = <String, void>{};

    for (final tag in all(widget.api.booru)) {
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
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = const TasksService().status<HottestTagsCarousel>(context);

    if (task.isWaiting && list.isEmpty) {
      return SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 160 * GridAspectRatio.oneFive.value,
          ),
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
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    final theme = Theme.of(context);
    final List<int> weights = switch (AdaptivePage.size(context)) {
      AdaptivePageSize.extraSmall || AdaptivePageSize.small => const [3, 2, 1],
      AdaptivePageSize.medium => const [3, 2, 1, 1],
      AdaptivePageSize.large => const [3, 2, 2, 1],
      AdaptivePageSize.extraLarge => const [3, 2, 2, 2],
    };

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 160 * GridAspectRatio.oneFive.value,
          ),
          child: CarouselView.weighted(
            enableSplash: false,
            itemSnapping: true,
            flexWeights: weights,
            shrinkExtent: 200,
            children: list.map<Widget>((tag) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  HottestTagWidget(tag: tag, booru: widget.api.booru),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => OnBooruTagPressed.maybePressOf(
                        context,
                        tag.tag,
                        widget.api.booru,
                        overrideSafeMode:
                            const SettingsService().current.safeMode,
                      ),
                      onLongPress: () => openPostAsync(
                        context,
                        booru: widget.api.booru,
                        postId: tag.postId,
                      ),
                      overlayColor: WidgetStateProperty.resolveWith((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          );
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          );
                        }
                        if (states.contains(WidgetState.focused)) {
                          return theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          );
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
  const HottestTagWidget({super.key, required this.tag, required this.booru});

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
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
            padding: const EdgeInsets.only(bottom: 12, left: 14),
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

Future<void> _loadHottestTags(BooruAPI api) async {
  if (!LocalTagsService.available || !TagManagerService.available) {
    return;
  }

  final ret = <HottestTag>[];

  try {
    math.Random random;
    try {
      random = math.Random.secure();
    } catch (_) {
      random = math.Random(9538659403);
    }

    final tags = (await api.searchTag("")).fold(<String, TagData>{}, (map, e) {
      map[e.tag] = e;

      return map;
    });

    final localTags = const LocalTagsService()
        .mostFrequent(45)
        .where((e) => !tags.containsKey(e.tag))
        .take(15)
        .toList();

    final favoriteTags =
        const TagManagerService().pinned
            .get(130)
            .where((e) => !tags.containsKey(e.tag))
            .toList()
          ..shuffle(random);

    for (final tag
        in (localTags.isNotEmpty && tags.length > localTags.length)
            ? tags.values
                  .take(tags.length - localTags.length)
                  .followedBy(localTags)
                  .followedBy(favoriteTags.take(5))
            : tags.values.followedBy(favoriteTags.take(5))) {
      final posts = await api.page(
        0,
        tag.tag,
        SafeMode.normal,
        limit: 15,
        pageSaver: PageSaver.noPersist(),
      );

      ret.add(
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

    const HottestTagsService().replace(ret, api.booru);
  } catch (e, trace) {
    Logger.root.severe("loadHottestTags", e, trace);
  }
}

class BooruAPINotifier extends InheritedWidget {
  const BooruAPINotifier({super.key, required this.api, required super.child});

  final BooruAPI api;

  static BooruAPI of(BuildContext context) {
    return maybeOf(context)!;
  }

  static BooruAPI? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<BooruAPINotifier>();

    return widget?.api;
  }

  @override
  bool updateShouldNotify(BooruAPINotifier oldWidget) {
    return api != oldWidget.api;
  }
}

class ClusteredSource {
  ClusteredSource(
    GridBookmarkService service,
    SettingsService settings,
    this.updateSink,
    this.selectionController,
    this.gridSettings,
  ) {
    events = service.watch((_) {
      refresh(service);
    });

    final current = settings.current.selectedBooru;
    _sources[current] = _makeSource(current);

    for (final e in Booru.values.where((e) => e != current)) {
      _sources[e] = _makeSource(e);
    }
  }

  final GridSettingsData gridSettings;
  final SelectionController selectionController;
  final Sink<void> updateSink;

  late final StreamSubscription<int> events;

  final _sources =
      <
        Booru,
        ({
          GenericListSource<GridBookmark> source,
          SourceShellScopeElementState<GridBookmark> state,
        })
      >{};

  Iterable<
    MapEntry<
      Booru,
      ({
        GenericListSource<GridBookmark> source,
        SourceShellScopeElementState<GridBookmark> state,
      })
    >
  >
  get sourcesBooru => _sources.entries;

  Iterable<ResourceSource<int, GridBookmark>> get sources =>
      _sources.values.map((e) => e.source);
  Iterable<SourceShellScopeElementState<GridBookmark>> get statuses =>
      _sources.values.map((e) => e.state);

  void refresh(GridBookmarkService service) {
    for (final e in _sources.values) {
      e.source.backingStorage.clear(true);
    }

    for (final e in service.all) {
      final source = _sources.putIfAbsent(e.booru, () => _makeSource(e.booru));

      source.source.backingStorage.add(e, true);
    }

    for (final e in _sources.values) {
      e.source.backingStorage.addAll([]);
    }

    updateSink.add(null);
  }

  ({
    GenericListSource<GridBookmark> source,
    SourceShellScopeElementState<GridBookmark> state,
  })
  _makeSource(Booru booru) {
    final source = GenericListSource<GridBookmark>(null);

    return (
      source: source,
      state: SourceShellScopeElementState(
        source: source,
        gridSettings: gridSettings,
        selectionController: selectionController,
        actions: const [],
        wrapRefresh: null,
        onEmpty: SourceOnEmptyInterface(
          source,
          (context) => context.l10n().noBooruBookmarks(booru.string),
        ),
      ),
    );
  }

  void dispose() {
    events.cancel();
    for (final e in _sources.values) {
      e.source.destroy();
      e.state.destroy();
    }
  }
}
