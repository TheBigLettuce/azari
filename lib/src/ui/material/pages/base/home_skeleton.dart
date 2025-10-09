// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/home/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/settings/settings_page.dart";
import "package:azari/src/ui/material/widgets/adaptive_page.dart";
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

  final _ribbonKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    showRail = MediaQuery.sizeOf(context).width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final bottomPadding = viewPadding.bottom;
    final theme = Theme.of(context);

    final bottomNavigationBar = showRail
        ? null
        : HomeNavigationBar(
            scrollingState: widget.scrollingState,
            onDestinationSelected: widget.onDestinationSelected,
            desitinations: widget.animatedIcons.icons(context, widget.booru),
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
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  viewPadding.bottom +
                  (showRail ? 0 : HomeNavigationBar.height),
            ),
            child: SelectionRibbon(key: _ribbonKey),
          ),
        ],
      ),
    );

    return AnnotatedRegion(
      value: makeSystemUiOverlayStyle(theme),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        drawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: bottomNavigationBar,
        drawer: widget.drawer,
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
          false => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewPadding: viewPadding.copyWith(
                bottom: viewPadding.bottom + HomeNavigationBar.height,
              ),
            ),
            child: body,
          ),
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

    final containerColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.8,
    );
    final textColor = colorScheme.onSurface.withValues(alpha: 0.8);

    final effects = [
      MoveEffect(
        duration: 200.ms,
        curve: Easing.standard,
        begin: Offset(0, -(24 + MediaQuery.viewPaddingOf(context).top)),
        end: Offset.zero,
      ),
    ];

    final padding = EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top);

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
                    const Padding(padding: EdgeInsets.only(right: 4)),
                    Text(l10n.noInternet, style: TextStyle(color: textColor)),
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
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final isExpanded = selectionActions.controller.isExpanded;

    final currentRoute = isExpanded ? 0 : CurrentRoute.of(context).index;

    void goToPage(int i) {
      widget.onDestinationSelected(context, CurrentRoute.fromIndex(i));
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

  static const double height = 80;

  final void Function(BuildContext, CurrentRoute) onDestinationSelected;

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

abstract class IsExpandedConnector {
  bool get isExpanded;
  set isExpanded(bool e);
}

class _HomeNavigationBarState extends State<HomeNavigationBar>
    with TickerProviderStateMixin
    implements IsExpandedConnector {
  late final AnimationController scrollingAnimation;

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
      reverseDuration: Durations.short1,
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

  final heightTween = Tween<double>(begin: 48, end: 72);
  final widthTween = Tween<double>(begin: 220, end: 280);
  final labelSizeTween = Tween<double>(begin: 4, end: 0);
  final backgroundAlphaTween = Tween<double>(begin: 0.75, end: 0.95);

  @override
  Widget build(BuildContext context) {
    final currentRoute = CurrentRoute.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                    theme.colorScheme.surface.withValues(alpha: 0.6),
                    theme.colorScheme.surface.withValues(alpha: 0.4),
                    theme.colorScheme.surface.withValues(alpha: 0.2),
                    theme.colorScheme.surface.withValues(alpha: 0.1),
                    theme.colorScheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: bottomPadding + 80,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: HomeNavigationBar.height + bottomPadding,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12) +
                  EdgeInsets.only(bottom: bottomPadding + 8),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.2,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  child: MediaQuery.removeViewPadding(
                    removeBottom: true,
                    context: context,
                    child: AnimatedBuilder(
                      animation: scrollingAnimation.view,
                      builder: (context, child) {
                        return SizedBox(
                          width: widthTween.transform(
                            Easing.standard.transform(scrollingAnimation.value),
                          ),
                          child: NavigationBar(
                            height: heightTween.transform(
                              Easing.standard.transform(
                                scrollingAnimation.value,
                              ),
                            ),
                            onDestinationSelected: (value) {
                              widget.onDestinationSelected(
                                context,
                                CurrentRoute.fromIndex(value),
                              );
                            },
                            indicatorColor: colorScheme.surfaceContainerLow
                                .withValues(alpha: 0),
                            labelTextStyle: WidgetStateMapper({
                              WidgetState.disabled: theme.textTheme.labelMedium
                                  ?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.38),
                                  ),
                              WidgetState.selected: theme.textTheme.labelMedium
                                  ?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              WidgetState.any: theme.textTheme.labelMedium
                                  ?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            }),

                            labelBehavior: scrollingAnimation.value >= 0.5
                                ? NavigationDestinationLabelBehavior.alwaysShow
                                : NavigationDestinationLabelBehavior.alwaysHide,
                            backgroundColor: colorScheme.surfaceContainerLow
                                .withValues(
                                  alpha: backgroundAlphaTween.transform(
                                    scrollingAnimation.value,
                                  ),
                                ),
                            selectedIndex: currentRoute.index,
                            destinations: widget.desitinations,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    required this.switchToHome,
  });

  final ChangePageMixin changePage;
  final AnimatedIconsMixin animatedIcons;

  final GridBookmarkService? gridBookmarks;
  final FavoritePostSourceService? favoritePosts;

  final VoidCallback switchToHome;

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

  final key = GlobalKey<__AnimatedTagColumnState>();

  @override
  void initState() {
    super.initState();

    bookmarks = gridBookmarks?.firstNumber(5) ?? [];
    settings = widget.settingsService.current;

    bookmarkEvents = gridBookmarks?.watch((_) {
      key.currentState?.diffAndAnimate(gridBookmarks!.firstNumber(5));
    }, true);
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

    widget.switchToHome();

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
                  _DrawerNavigationBadgeStyle(
                    child: _FavoritePostsCount(favoritePosts: favoritePosts!),
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
            _AnimatedTagColumn(key: key, initalBookmarks: bookmarks),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          _NavigationDrawerTile(
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

class _DrawerNavigationBadgeStyle extends StatelessWidget {
  const _DrawerNavigationBadgeStyle({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 24),
      child: DefaultTextStyle(style: textStyle, child: child),
    );
  }
}

class _BookmarksCount extends StatefulWidget {
  const _BookmarksCount({
    // super.key,
    required this.gridBookmarks,
  });

  final GridBookmarkService gridBookmarks;

  @override
  State<_BookmarksCount> createState() => __BookmarksCountState();
}

class __BookmarksCountState extends State<_BookmarksCount> {
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

class _FavoritePostsCount extends StatefulWidget {
  const _FavoritePostsCount({
    // super.key,
    required this.favoritePosts,
  });

  final FavoritePostSourceService favoritePosts;

  @override
  State<_FavoritePostsCount> createState() => __FavoritePostsCountState();
}

class __FavoritePostsCountState extends State<_FavoritePostsCount> {
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

class _AnimatedTagColumn extends StatefulWidget {
  const _AnimatedTagColumn({super.key, required this.initalBookmarks});

  final List<GridBookmark> initalBookmarks;

  @override
  State<_AnimatedTagColumn> createState() => __AnimatedTagColumnState();
}

class __AnimatedTagColumnState extends State<_AnimatedTagColumn> {
  late final List<GridBookmark> bookmarks;
  final listKey = GlobalKey<AnimatedListState>();

  void diffAndAnimate(List<GridBookmark> toNew) {
    if (toNew.isEmpty) {
      final prevList = bookmarks.toList();
      bookmarks.clear();

      for (final (i, e) in prevList.indexed) {
        listKey.currentState?.removeItem(
          i,
          (context, animation) => _NavigationDrawerTile(
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
    final newBookmarks = toNew.indexed.where(
      (e) => !bookmarkMap.containsKey(e.$2.name),
    );

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
              height: sizeTween.transform(
                Easing.standard.transform(animation.value),
              ),
              child: SlideTransition(
                position: animation
                    .drive(CurveTween(curve: Easing.standardAccelerate))
                    .drive(slideTween),
                child: widget,
              ),
            );
          },
          child: _NavigationDrawerTile(
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
  static final slideTween = Tween<Offset>(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  );

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
      child: _NavigationDrawerTile(
        icon: Icons.bookmark_outline_rounded,
        label: e.tags,
        onPressed: () => openBooruSearchPage(e),
      ),
    );
  }

  void openBooruSearchPage(GridBookmark e) {
    BooruRestoredPage.open(context, booru: e.booru, tags: e.tags, name: e.name);
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

class _NavigationDrawerTile extends StatelessWidget {
  const _NavigationDrawerTile({
    // super.key,
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
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const Padding(padding: EdgeInsets.only(right: 12)),
              Expanded(
                child: Text(
                  label,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionRibbon extends StatefulWidget {
  const SelectionRibbon({super.key});

  @override
  State<SelectionRibbon> createState() => _SelectionRibbonState();
}

class _SelectionRibbonState extends State<SelectionRibbon>
    with DefaultSelectionEventsMixin, SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: Durations.medium4,
      reverseDuration: Durations.medium1,
    );
  }

  @override
  void dispose() {
    animationController.dispose();

    super.dispose();
  }

  @override
  void animateNavBar(bool show) {
    if (show) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: animationController.view,
      builder: (context, child) => Opacity(
        opacity: animationController.value,
        child: IgnorePointer(
          ignoring: animationController.value == 0,
          child: child,
        ),
      ),
      child: Align(
        alignment: switch (AdaptivePageSize.of(context)) {
          AdaptivePageSize.extraSmall ||
          AdaptivePageSize.small => Alignment.centerRight,
          AdaptivePageSize.medium ||
          AdaptivePageSize.large ||
          AdaptivePageSize.extraLarge => Alignment.bottomRight,
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shadows: kElevationToShadow[2],
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.95,
              ),
              shape: const StadiumBorder(),
            ),
            child: IconButtonTheme(
              data: IconButtonThemeData(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.secondary,
                  ),
                  iconColor: WidgetStatePropertyAll(
                    theme.colorScheme.onSecondary,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8) +
                        const EdgeInsets.only(left: 12),
                    child: IconButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.primary,
                        ),
                        iconColor: WidgetStatePropertyAll(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                      onPressed: () {
                        selectionActions.controller.setCount(0);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  const Padding(padding: EdgeInsetsGeometry.only(right: 12)),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8) +
                        const EdgeInsets.only(right: 12),
                    child: AnimatedSize(
                      alignment: Alignment.centerRight,
                      curve: Easing.emphasizedDecelerate,
                      reverseDuration: Durations.short3,
                      duration: Durations.medium2,
                      child: Row(
                        spacing: 4,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...actions.map(
                            (e) => IconButton(
                              onPressed: e.consume,
                              icon: Icon(e.icon),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
