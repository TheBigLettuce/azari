// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:animations/animations.dart";
import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/settings_page.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({
    super.key,
    required this.animatedIcons,
    required this.onDestinationSelected,
    required this.booru,
    required this.scrollingState,
    required this.drawer,
    required this.child,
  });

  final AnimatedIconsMixin animatedIcons;

  final Booru booru;

  final ScrollingStateSink scrollingState;

  final DestinationCallback onDestinationSelected;

  final Widget? drawer;

  final Widget child;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with NetworkStatusApi, NetworkStatusWatcher {
  bool showRail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    showRail = MediaQuery.sizeOf(context).width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);

    final bottomNavigationBar = showRail
        ? null
        : HomeNavigationBar(
            scrollingState: widget.scrollingState,
            onDestinationSelected: widget.onDestinationSelected,
            desitinations: widget.animatedIcons.icons(
              context,
              widget.booru,
            ),
          );

    final body = GestureDeadZones(
      right: true,
      left: true,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _SkeletonBody(
            bottomPadding: bottomPadding,
            hasInternet: hasInternet,
            child: widget.child,
          ),
          if (!hasInternet) const NoNetworkIndicator(),
        ],
      ),
    );

    return AnnotatedRegion(
      value: navBarStyleForTheme(
        theme,
        highTone: false,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        drawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: bottomNavigationBar,
        drawer: widget.drawer,
        // backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
        body: switch (showRail) {
          true => Row(
              children: [
                _NavigationRail(
                  onDestinationSelected: widget.onDestinationSelected,
                  animatedIcons: widget.animatedIcons,
                  booru: widget.booru,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          false => body,
        },
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({
    // super.key,
    required this.bottomPadding,
    required this.hasInternet,
    required this.child,
  });

  final double bottomPadding;
  final bool hasInternet;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);

    final padding = EdgeInsets.only(top: hasInternet ? 0 : 24);
    final viewPadding =
        data.viewPadding + EdgeInsets.only(bottom: bottomPadding);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Easing.standard,
      padding: padding,
      child: MediaQuery(
        data: data.copyWith(viewPadding: viewPadding),
        child: child,
      ),
    );
  }
}

class NoNetworkIndicator extends StatelessWidget {
  const NoNetworkIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final containerColor =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final textColor = colorScheme.onSurface.withValues(alpha: 0.8);

    final effects = [
      MoveEffect(
        duration: 200.ms,
        curve: Easing.standard,
        begin: Offset(
          0,
          -(24 + MediaQuery.viewPaddingOf(context).top),
        ),
        end: Offset.zero,
      ),
    ];

    final padding = EdgeInsets.only(
      top: MediaQuery.viewPaddingOf(context).top,
    );

    final size = MediaQuery.sizeOf(context);

    return Animate(
      autoPlay: true,
      effects: effects,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedContainer(
          duration: 200.ms,
          curve: Easing.standard,
          color: containerColor,
          child: Padding(
            padding: padding,
            child: SizedBox(
              height: 24,
              width: size.width,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.signal_wifi_off_outlined,
                      size: 14,
                      color: textColor,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                    ),
                    Text(
                      l10n.noInternet,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationRail extends StatefulWidget {
  const _NavigationRail({
    // super.key,
    required this.onDestinationSelected,
    required this.animatedIcons,
    required this.booru,
  });

  final AnimatedIconsMixin animatedIcons;

  final Booru booru;

  final DestinationCallback onDestinationSelected;

  @override
  State<_NavigationRail> createState() => __NavigationRailState();
}

class __NavigationRailState extends State<_NavigationRail>
    with DefaultSelectionEventsMixin {
  @override
  SelectionAreaSize get selectionSizes =>
      const SelectionAreaSize(base: 0, expanded: 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final isExpanded = selectionActions.controller.isExpanded;

    final currentRoute = isExpanded ? 0 : CurrentRoute.of(context).index;

    void goToPage(int i) {
      widget.onDestinationSelected(
        context,
        CurrentRoute.fromIndex(i),
      );
    }

    void useAction(int i_) {
      int i = i_;

      if (i == 0) {
        selectionActions.controller.setCount(0);
      } else if (actions.isNotEmpty) {
        i -= 1;
        actions[i].consume();
      }
    }

    final destinations = switch (isExpanded) {
      true => [
          const NavigationRailDestination(
            icon: Icon(Icons.close_rounded),
            label: SizedBox.shrink(),
          ),
          ...actions.map(
            (e) => NavigationRailDestination(
              icon: Icon(e.icon),
              label: const SizedBox.shrink(),
            ),
          ),
        ],
      false => widget.animatedIcons.railIcons(context, l10n, widget.booru),
    };

    return NavigationRail(
      groupAlignment: -0.6,
      onDestinationSelected: isExpanded ? useAction : goToPage,
      destinations: destinations,
      selectedIndex: currentRoute,
    );
  }
}

class HomeNavigationBar extends StatefulWidget {
  const HomeNavigationBar({
    super.key,
    required this.desitinations,
    required this.scrollingState,
    required this.onDestinationSelected,
  });

  final List<Widget> desitinations;
  final ScrollingStateSink scrollingState;

  final void Function(BuildContext, CurrentRoute) onDestinationSelected;

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

abstract class IsExpandedConnector {
  bool get isExpanded;
  set isExpanded(bool e);
}

class _HomeNavigationBarState extends State<HomeNavigationBar>
    with DefaultSelectionEventsMixin, TickerProviderStateMixin
    implements IsExpandedConnector {
  late final AnimationController scrollingAnimation;

  @override
  SelectionAreaSize get selectionSizes =>
      const SelectionAreaSize(base: 80.5, expanded: 80.5);

  SelectionController get controller => selectionActions.controller;

  late final StreamSubscription<bool> events;

  @override
  bool get isExpanded => mounted && (scrollingAnimation.value > 0);

  @override
  set isExpanded(bool e) {
    if (e && scrollingAnimation.value == 0) {
      scrollingAnimation.forward();
    } else if (!e && scrollingAnimation.value > 0) {
      scrollingAnimation.reverse();
    }
  }

  @override
  void initState() {
    super.initState();

    scrollingAnimation = AnimationController(
      value: 1,
      duration: Durations.short4,
      reverseDuration: Durations.short4,
      vsync: this,
    );

    widget.scrollingState.connect(this);

    events = widget.scrollingState.stream.listen((scrollingUp) {
      if (scrollingUp) {
        scrollingAnimation.forward();
      } else {
        scrollingAnimation.reverse();
      }
    });
  }

  @override
  void dispose() {
    widget.scrollingState.disconnect();

    scrollingAnimation.dispose();

    events.cancel();

    super.dispose();
  }

  @override
  void animateNavBar(bool show) {
    if (show) {
      scrollingAnimation.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = CurrentRoute.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor =
        colorScheme.surfaceContainer.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: scrollingAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: scrollingAnimation.view,
            curve: Easing.emphasizedDecelerate,
            reverseCurve: Easing.emphasizedAccelerate,
          ).drive<Offset>(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ),
          ),
          child: child,
        );
      },
      child: AnimatedSwitcher(
        switchInCurve: Easing.standard,
        switchOutCurve: Easing.standard,
        duration: Durations.medium3,
        child: switch (controller.isExpanded) {
          true => SelectionBar(
              actions: actions,
              selectionActions: selectionActions,
            ),
          false => NavigationBar(
              onDestinationSelected: (value) {
                widget.onDestinationSelected(
                  context,
                  CurrentRoute.fromIndex(value),
                );
              },
              labelTextStyle: WidgetStateMapper({
                WidgetState.disabled: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.38),
                ),
                WidgetState.selected: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                WidgetState.any: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              }),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              backgroundColor: backgroundColor,
              selectedIndex: currentRoute.index,
              destinations: widget.desitinations,
            ),
        },
        transitionBuilder: (child, animation) {
          return FadeScaleTransition(
            animation: animation,
            child: child,
          );
        },
      ),
    );
  }
}

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    super.key,
    required this.settingsService,
    required this.changePage,
    required this.animatedIcons,
    required this.gridBookmarks,
    required this.favoritePosts,
  });

  final ChangePageMixin changePage;
  final AnimatedIconsMixin animatedIcons;

  final GridBookmarkService? gridBookmarks;
  final FavoritePostSourceService? favoritePosts;

  final SettingsService settingsService;

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;

  late List<GridBookmark> bookmarks;
  late final StreamSubscription<void>? bookmarkEvents;

  late final SettingsData settings;

  final key = GlobalKey<AnimatedTagColumnState>();

  @override
  void initState() {
    super.initState();

    bookmarks = gridBookmarks?.firstNumber(5) ?? [];
    settings = widget.settingsService.current;

    bookmarkEvents = gridBookmarks?.watch(
      (_) {
        key.currentState?.diffAndAnimate(gridBookmarks!.firstNumber(5));
      },
      true,
    );
  }

  @override
  void dispose() {
    bookmarkEvents?.cancel();

    super.dispose();
  }

  void selectDestination(int value) {
    final nav = widget.changePage.mainKey.currentState;
    if (nav != null) {
      while (nav.canPop()) {
        nav.pop();
      }
    }

    BooruSubPage.selectOf(context, BooruSubPage.fromIdx(value));
    Scaffold.of(context).closeDrawer();
    widget.changePage.animateIcons(widget.animatedIcons);

    switch (CurrentRoute.of(context)) {
      case CurrentRoute.home:
        widget.animatedIcons.homeIconController.reverse().then(
              (value) => widget.animatedIcons.homeIconController.forward(),
            );
      case CurrentRoute.gallery:
        widget.animatedIcons.galleryIconController.reverse().then(
              (value) => widget.animatedIcons.galleryIconController.forward(),
            );
      case CurrentRoute.discover:
        widget.animatedIcons.discoverIconController.reverse().then(
              (value) => widget.animatedIcons.discoverIconController.forward(),
            );
    }
  }

  void openSettings() => SettingsPage.open(context);

  @override
  Widget build(BuildContext context) {
    final selectedBooruPage = BooruSubPage.of(context);
    final l10n = context.l10n();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusBarColor = colorScheme.surface.withValues(alpha: 0);

    final brightnessReversed = theme.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    final navigationDestinations = BooruSubPage.values.map(
      (e) => NavigationDrawerDestination(
        selectedIcon: Icon(e.selectedIcon),
        icon: Icon(e.icon),
        enabled: e.hasServices(),
        label: Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e == BooruSubPage.booru
                      ? settings.selectedBooru.string
                      : e.translatedString(l10n),
                ),
                if (e == BooruSubPage.favorites && favoritePosts != null)
                  DrawerNavigationBadgeStyle(
                    child: FavoritePostsCount(
                      favoritePosts: favoritePosts!,
                    ),
                  )
                else if (e == BooruSubPage.bookmarks && gridBookmarks != null)
                  DrawerNavigationBadgeStyle(
                    child: BookmarksCount(
                      gridBookmarks: gridBookmarks!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarBrightness: brightnessReversed,
      ),
      child: NavigationDrawer(
        onDestinationSelected: selectDestination,
        selectedIndex: selectedBooruPage.index,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: AppLogoTitle(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          ...navigationDestinations,
          if (bookmarks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                l10n.latestBookmarks,
                style: theme.textTheme.titleSmall,
              ),
            ),
            AnimatedTagColumn(
              key: key,
              initalBookmarks: bookmarks,
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          NavigationDrawerTile(
            icon: Icons.settings_outlined,
            label: l10n.settingsLabel,
            onPressed: openSettings,
          ),
          const Padding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class DrawerNavigationBadgeStyle extends StatelessWidget {
  const DrawerNavigationBadgeStyle({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 24),
      child: DefaultTextStyle(
        style: textStyle,
        child: child,
      ),
    );
  }
}

class BookmarksCount extends StatefulWidget {
  const BookmarksCount({
    super.key,
    required this.gridBookmarks,
  });

  final GridBookmarkService gridBookmarks;

  @override
  State<BookmarksCount> createState() => _BookmarksCountState();
}

class _BookmarksCountState extends State<BookmarksCount> {
  late final StreamSubscription<void> events;
  int count = 0;

  @override
  void initState() {
    super.initState();
    count = widget.gridBookmarks.count;

    events = widget.gridBookmarks.watch((newCount) {
      setState(() {
        count = newCount;
      });
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (count <= 0) {
      true => const SizedBox.shrink(),
      false => Text(count.toString()),
    };
  }
}

class FavoritePostsCount extends StatefulWidget {
  const FavoritePostsCount({
    super.key,
    required this.favoritePosts,
  });

  final FavoritePostSourceService favoritePosts;

  @override
  State<FavoritePostsCount> createState() => _FavoritePostsCountState();
}

class _FavoritePostsCountState extends State<FavoritePostsCount> {
  late final StreamSubscription<void> events;

  @override
  void initState() {
    super.initState();

    events = widget.favoritePosts.cache.countEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.favoritePosts.cache.count;

    return switch (count <= 0) {
      true => const SizedBox.shrink(),
      false => Text(count.toString()),
    };
  }
}

class AnimatedTagColumn extends StatefulWidget {
  const AnimatedTagColumn({
    super.key,
    required this.initalBookmarks,
  });

  final List<GridBookmark> initalBookmarks;

  @override
  State<AnimatedTagColumn> createState() => AnimatedTagColumnState();
}

class AnimatedTagColumnState extends State<AnimatedTagColumn> {
  late final List<GridBookmark> bookmarks;
  final listKey = GlobalKey<AnimatedListState>();

  void diffAndAnimate(List<GridBookmark> toNew) {
    if (toNew.isEmpty) {
      final prevList = bookmarks.toList();
      bookmarks.clear();

      for (final (i, e) in prevList.indexed) {
        listKey.currentState?.removeItem(
          i,
          (context, animation) => NavigationDrawerTile(
            icon: Icons.bookmark_outline_rounded,
            label: e.tags,
            onPressed: () => openBooruSearchPage(e),
          ),
        );
      }

      return;
    }

    final newMap = toNew.fold(<String, GridBookmark>{}, (map, e) {
      map[e.name] = e;

      return map;
    });

    final bookmarkMap = bookmarks.fold(<String, GridBookmark>{}, (map, e) {
      map[e.name] = e;

      return map;
    });

    final alive = <(int, GridBookmark)>[];
    final removed = <(int, GridBookmark)>[];
    final newBookmarks =
        toNew.indexed.where((e) => !bookmarkMap.containsKey(e.$2.name));

    for (final (idx, bookmark) in bookmarks.indexed) {
      if (newMap.containsKey(bookmark.name)) {
        alive.add((idx, bookmark));
      } else {
        removed.add((idx, bookmark));
      }
    }

    bookmarks.clear();
    bookmarks.addAll(toNew);

    for (final e in removed) {
      listKey.currentState?.removeItem(
        e.$1,
        (context, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, widget) {
            return SizedBox(
              height: sizeTween
                  .transform(Easing.standard.transform(animation.value)),
              child: SlideTransition(
                position: animation
                    .drive(CurveTween(curve: Easing.standardAccelerate))
                    .drive(slideTween),
                child: widget,
              ),
            );
          },
          child: NavigationDrawerTile(
            icon: Icons.bookmark_outline_rounded,
            label: e.$2.tags,
            onPressed: () => openBooruSearchPage(e.$2),
          ),
        ),
        duration: Durations.short3,
      );
    }

    for (final (i, _) in newBookmarks) {
      listKey.currentState?.insertAllItems(i, 1, duration: Durations.medium1);
    }
  }

  @override
  void initState() {
    super.initState();

    bookmarks = widget.initalBookmarks.toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static final sizeTween = Tween<double>(begin: 0, end: 56);
  static final slideTween =
      Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero);

  Widget itemBuilder(
    BuildContext context,
    int idx,
    Animation<double> animation,
  ) {
    final e = bookmarks[idx];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, widget) {
        return SizedBox(
          height: animation
              .drive(CurveTween(curve: Easing.standard))
              .drive(sizeTween)
              .value,
          child: SlideTransition(
            position: animation
                .drive(CurveTween(curve: Easing.emphasizedDecelerate))
                .drive(slideTween),
            child: widget,
          ),
        );
      },
      child: NavigationDrawerTile(
        icon: Icons.bookmark_outline_rounded,
        label: e.tags,
        onPressed: () => openBooruSearchPage(e),
      ),
    );
  }

  void openBooruSearchPage(GridBookmark e) {
    Scaffold.maybeOf(context)?.closeDrawer();

    BooruRestoredPage.open(
      context,
      booru: e.booru,
      tags: e.tags,
      name: e.name,
      rootNavigator: true,
      saveSelectedPage: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: bookmarks.length,
      itemBuilder: itemBuilder,
    );
  }
}

class NavigationDrawerTile extends StatelessWidget {
  const NavigationDrawerTile({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final IconData icon;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 12)),
              Icon(
                icon,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const Padding(padding: EdgeInsets.only(right: 12)),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
