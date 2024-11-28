// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/build_theme.dart";
import "package:azari/l10n/generated/app_localizations.dart";
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
    required this.scrollingEvents,
    required this.child,
  });

  final AnimatedIconsMixin animatedIcons;
  final ChangePageMixin changePage;

  final Booru booru;

  final Stream<bool> scrollingEvents;

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
    final db = DatabaseConnectionNotifier.of(context);

    final bottomNavigationBar = showRail
        ? null
        : HomeNavigationBar(
            scrollingEvents: widget.scrollingEvents,
            desitinations: widget.animatedIcons.icons(
              context,
              widget.booru,
              widget.onDestinationSelected,
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

    final child = showRail
        ? Row(
            children: [
              _NavigationRail(
                onDestinationSelected: widget.onDestinationSelected,
                animatedIcons: widget.animatedIcons,
                booru: widget.booru,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          )
        : body;

    return AnnotatedRegion(
      value: navBarStyleForTheme(theme),
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
        body: child,
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
    final l10n = AppLocalizations.of(context)!;
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    final destinations = isExpanded
        ? [
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
          ]
        : widget.animatedIcons.railIcons(l10n, widget.booru);

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
    required this.scrollingEvents,
  });

  final List<Widget> desitinations;
  final Stream<bool> scrollingEvents;

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar>
    with DefaultSelectionEventsMixin {
  SelectionController get controller => selectionActions.controller;

  late final StreamSubscription<bool> events;

  bool scrollingUp = false;

  @override
  void initState() {
    super.initState();

    events = widget.scrollingEvents.listen((newScrollingUp) {
      if (newScrollingUp != scrollingUp) {
        setState(() {
          scrollingUp = newScrollingUp;
        });
      }
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = CurrentRoute.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dividerColor = colorScheme.surfaceBright.withValues(alpha: 0.9);
    final backgroundColor =
        colorScheme.surfaceContainer.withValues(alpha: 0.95);

    final double opacity = !scrollingUp || controller.isExpanded ? 1 : 0.2;

    const indicatorShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );

    return AnimatedSize(
      alignment: Alignment.bottomCenter,
      duration: Durations.medium3,
      curve: Easing.standard,
      child: AnimatedOpacity(
        curve: Easing.standard,
        duration: Durations.medium1,
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: 0,
              endIndent: 0,
              color: dividerColor,
            ),
            if (controller.isExpanded)
              SelectionBar(
                actions: actions,
                selectionActions: selectionActions,
              )
            else
              NavigationBar(
                height: 48,
                indicatorShape: indicatorShape,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                backgroundColor: backgroundColor,
                selectedIndex: currentRoute.index,
                destinations: widget.desitinations,
              ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bottomBarColor = colorScheme.surface.withValues(alpha: 0.95);
    final textColor = colorScheme.onPrimary.withValues(alpha: 0.8);
    final boxColor = colorScheme.primary.withValues(alpha: 0.8);

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
      case CurrentRoute.search:
        widget.animatedIcons.searchIconController.reverse().then(
              (value) => widget.animatedIcons.searchIconController.forward(),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusBarColor = colorScheme.surface.withValues(alpha: 0);
    final textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    final brightnessReversed = theme.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    final navigationDestinations = BooruSubPage.values.map(
      (e) => NavigationDrawerDestination(
        selectedIcon: Icon(e.selectedIcon),
        icon: Icon(e.icon),
        label: Text(
          e == BooruSubPage.booru
              ? settings.selectedBooru.string
              : e.translatedString(l10n),
        ),
      ),
    );

    final textStyle = theme.textTheme.labelLarge?.copyWith(color: textColor);

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarBrightness: brightnessReversed,
      ),
      child: NavigationDrawer(
        onDestinationSelected: selectDestination,
        selectedIndex: selectedBooruPage.index,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text(
                  l10n.booruLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    child: IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: openSettings,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...navigationDestinations,
          const Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 16, bottom: 10),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 16, 10),
            child: Text(
              l10n.latestBookmarks,
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (bookmarks.isEmpty)
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 28 - 16)),
                    Text(
                      l10n.noBookmarks,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            )
          else
            _AnimatedTagColumn(
              key: key,
              initalBookmarks: bookmarks,
              db: widget.db,
            ),
        ],
      ),
    );
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
          (context, animation) => _BookmarkTile(e: e, db: widget.db),
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
          child: _BookmarkTile(e: e.$2, db: widget.db),
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
      child: _BookmarkTile(e: e, db: widget.db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      initialItemCount: bookmarks.length,
      itemBuilder: itemBuilder,
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    // super.key,
    required this.e,
    required this.db,
  });

  final GridBookmark e;

  final DbConn db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    void openBooruSearchPage() {
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
              db: db,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: InkWell(
          onTap: openBooruSearchPage,
          customBorder: const StadiumBorder(),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 12)),
              Icon(
                Icons.bookmark_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const Padding(padding: EdgeInsets.only(right: 12)),
              Text(e.tags, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}