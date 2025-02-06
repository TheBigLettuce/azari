// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:animations/animations.dart";
import "package:azari/init_main/build_theme.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/pages/other/settings/settings_page.dart";
import "package:azari/src/platform/network_status.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({
    super.key,
    required this.animatedIcons,
    required this.onDestinationSelected,
    required this.changePage,
    required this.booru,
    required this.scrollingState,
    required this.child,
  });

  final AnimatedIconsMixin animatedIcons;
  final ChangePageMixin changePage;

  final Booru booru;

  final ScrollingStateSink scrollingState;

  final DestinationCallback onDestinationSelected;

  final Widget child;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> {
  ChangePageMixin get changePage => widget.changePage;

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
    final db = DbConn.of(context);

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
          _SkeletonBody(bottomPadding: bottomPadding, child: widget.child),
          if (!NetworkStatus.g.hasInternet) const _NoNetworkIndicator(),
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
        drawer: HomeDrawer(
          changePage: widget.changePage,
          db: db,
          animatedIcons: widget.animatedIcons,
        ),
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
    required this.child,
  });

  final double bottomPadding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);

    final padding = EdgeInsets.only(
      top: NetworkStatus.g.hasInternet ? 0 : 24,
    );
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

class _NoNetworkIndicator extends StatelessWidget {
  const _NoNetworkIndicator(
      // {super.key}
      );

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
      false => widget.animatedIcons.railIcons(l10n, widget.booru),
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
    if (e) {
      scrollingAnimation.forward();
    } else {
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

class SelectionBar extends StatefulWidget {
  const SelectionBar({
    super.key,
    required this.selectionActions,
    required this.actions,
  });

  final SelectionActions selectionActions;
  final List<SelectionButton> actions;

  @override
  State<SelectionBar> createState() => _SelectionBarState();
}

class _SelectionBarState extends State<SelectionBar> {
  late final StreamSubscription<void> _countEvents;

  @override
  void initState() {
    super.initState();

    _countEvents = widget.selectionActions.controller.countEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countEvents.cancel();

    super.dispose();
  }

  Widget _wrapped(SelectionButton e) => WrapGridActionButton(
        e.icon,
        e.consume,
        animate: e.animate,
        onLongPress: null,
        play: e.play,
        animation: const [],
        addBorder: false,
        notifier: null,
      );

  void _unselectAll() {
    widget.selectionActions.controller.setCount(0);
    HapticFeedback.mediumImpact();
  }

  List<PopupMenuEntry<void>> itemBuilderPopup(BuildContext context) {
    return widget.actions
        .getRange(0, widget.actions.length - 3)
        .map(
          (e) => PopupMenuItem<void>(
            onTap: e.consume,
            child: AbsorbPointer(
              child: _wrapped(e),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bottomBarColor = colorScheme.surface.withValues(alpha: 0.95);
    final textColor = colorScheme.onPrimary.withValues(alpha: 0.8);
    final boxColor = colorScheme.primary.withValues(alpha: 0.8);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    final actions = widget.actions.length < 4
        ? widget.actions.map(_wrapped).toList()
        : widget.actions
            .getRange(
              widget.actions.length != 4
                  ? widget.actions.length - 3
                  : widget.actions.length - 3 - 1,
              widget.actions.length,
            )
            .map(_wrapped)
            .toList();

    final count = widget.selectionActions.controller.count.toString();

    return Stack(
      fit: StackFit.passthrough,
      children: [
        const SizedBox(
          height: 80,
          child: AbsorbPointer(
            child: SizedBox.shrink(),
          ),
        ),
        BottomAppBar(
          color: bottomBarColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.actions.length > 4)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  position: PopupMenuPosition.under,
                  itemBuilder: itemBuilderPopup,
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 4,
                    children: actions,
                  ),
                ),
              ),
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 28,
                      minWidth: 28,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: boxColor,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text(
                            count,
                            style: textStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 4)),
                  IconButton.filledTonal(
                    onPressed: _unselectAll,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    super.key,
    required this.db,
    required this.changePage,
    required this.animatedIcons,
  });

  final ChangePageMixin changePage;
  final AnimatedIconsMixin animatedIcons;

  final DbConn db;

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  late List<GridBookmark> bookmarks = gridBookmarks.firstNumber(5);
  late final StreamSubscription<void> subscr;

  final settings = SettingsService.db().current;

  final key = GlobalKey<__AnimatedTagColumnState>();

  @override
  void initState() {
    super.initState();

    subscr = gridBookmarks.watch(
      (_) {
        key.currentState?.diffAndAnimate(gridBookmarks.firstNumber(5));
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr.cancel();

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

  void openSettings() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

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
                if (e == BooruSubPage.favorites)
                  _DrawerNavigationBadgeStyle(
                    child: _FavoritePostsCount(
                      db: widget.db,
                    ),
                  )
                else if (e == BooruSubPage.bookmarks)
                  _DrawerNavigationBadgeStyle(
                    child: _BookmarksCount(
                      db: widget.db,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              l10n.booruLabel,
              style: theme.textTheme.titleSmall,
            ),
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
            _AnimatedTagColumn(
              key: key,
              initalBookmarks: bookmarks,
              db: widget.db,
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Divider(),
          ),
          _NavigationDrawerTile(
            icon: Icons.settings_outlined,
            label: l10n.settingsLabel,
            onPressed: openSettings,
            db: widget.db,
          ),
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

class _BookmarksCount extends StatefulWidget {
  const _BookmarksCount({
    // super.key,
    required this.db,
  });

  final DbConn db;

  @override
  State<_BookmarksCount> createState() => __BookmarksCountState();
}

class __BookmarksCountState extends State<_BookmarksCount> {
  late final StreamSubscription<void> events;
  int count = 0;

  @override
  void initState() {
    super.initState();
    count = widget.db.gridBookmarks.count;

    events = widget.db.gridBookmarks.watch((newCount) {
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
    required this.db,
  });

  final DbConn db;

  @override
  State<_FavoritePostsCount> createState() => __FavoritePostsCountState();
}

class __FavoritePostsCountState extends State<_FavoritePostsCount> {
  late final StreamSubscription<void> events;

  @override
  void initState() {
    super.initState();

    events = widget.db.favoritePosts.cache.countEvents.listen((_) {
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
    final count = widget.db.favoritePosts.cache.count;

    return switch (count <= 0) {
      true => const SizedBox.shrink(),
      false => Text(count.toString()),
    };
  }
}

class _AnimatedTagColumn extends StatefulWidget {
  const _AnimatedTagColumn({
    super.key,
    required this.initalBookmarks,
    required this.db,
  });

  final List<GridBookmark> initalBookmarks;

  final DbConn db;

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
            db: widget.db,
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
          child: _NavigationDrawerTile(
            icon: Icons.bookmark_outline_rounded,
            label: e.$2.tags,
            onPressed: () => openBooruSearchPage(e.$2),
            db: widget.db,
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
      child: _NavigationDrawerTile(
        icon: Icons.bookmark_outline_rounded,
        label: e.tags,
        onPressed: () => openBooruSearchPage(e),
        db: widget.db,
      ),
    );
  }

  void openBooruSearchPage(GridBookmark e) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BooruRestoredPage(
            booru: e.booru,
            tags: e.tags,
            name: e.name,
            wrapScaffold: true,
            saveSelectedPage: (_) {},
            db: widget.db,
          );
        },
      ),
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

class _NavigationDrawerTile extends StatelessWidget {
  const _NavigationDrawerTile({
    // super.key,
    required this.db,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final IconData icon;

  final VoidCallback onPressed;

  final DbConn db;

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
