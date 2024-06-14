// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/glue_bottom_app_bar.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton(
    this.child, {
    super.key,
    required this.extendBody,
    required this.noNavBar,
    required this.animatedIcons,
    required this.showAnimeMangaPages,
    required this.onDestinationSelected,
    required this.changePage,
    required this.booru,
    required this.callback,
  });

  final void Function(BuildContext, CurrentRoute) onDestinationSelected;

  final bool extendBody;
  final AnimatedIconsMixin animatedIcons;
  final ChangePageMixin changePage;

  final Booru booru;

  final CallbackDescriptionNested? callback;

  final bool showAnimeMangaPages;
  final bool noNavBar;

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

  Future<void> _driveAnimation(bool forward) {
    return widget.animatedIcons
        .driveAnimation(forward: forward, rail: showRail);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    final child = GestureDeadZones(
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

    return _SelectionHolder(
      driveAnimation: _driveAnimation,
      hideNavBar: widget.animatedIcons.hideNavBar,
      defaultPreferences: widget.callback != null || showRail
          ? {}
          : {GluePreferences.persistentBarHeight},
      child: AnnotatedRegion(
        value: navBarStyleForTheme(
          theme,
          transparent: !widget.noNavBar,
          highTone: !widget.noNavBar,
        ),
        child: Scaffold(
          extendBody: widget.extendBody,
          extendBodyBehindAppBar: true,
          drawerEnableOpenDragGesture: false,
          bottomNavigationBar: _BottomNavigationBar(
            animatedIcons: widget.animatedIcons,
            changePage: changePage,
            onDestinationSelected: widget.onDestinationSelected,
            callback: widget.callback,
            booru: widget.booru,
            showAnimeMangaPages: widget.showAnimeMangaPages,
            showRail: showRail,
          ),
          resizeToAvoidBottomInset: false,
          drawer: _Drawer(
            changePage: widget.changePage,
            db: DatabaseConnectionNotifier.of(context),
            animatedIcons: widget.animatedIcons,
          ),
          body: showRail && widget.callback == null
              ? Row(
                  children: [
                    _NavigationRail(
                      onDestinationSelected: widget.onDestinationSelected,
                      animatedIcons: widget.animatedIcons,
                      booru: widget.booru,
                      showAnimeMangaPages: widget.showAnimeMangaPages,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: child),
                  ],
                )
              : child,
        ),
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Easing.standard,
      padding: EdgeInsets.only(
        top: NetworkStatus.g.hasInternet ? 0 : 24,
      ),
      child: MediaQuery(
        data: data.copyWith(
          viewPadding:
              data.viewPadding + EdgeInsets.only(bottom: bottomPadding),
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return Animate(
      autoPlay: true,
      effects: [
        MoveEffect(
          duration: 200.ms,
          curve: Easing.standard,
          begin: Offset(
            0,
            -(24 + MediaQuery.viewPaddingOf(context).top),
          ),
          end: Offset.zero,
        ),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedContainer(
          duration: 200.ms,
          curve: Easing.standard,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.viewPaddingOf(context).top,
            ),
            child: SizedBox(
              height: 24,
              width: MediaQuery.sizeOf(context).width,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.signal_wifi_off_outlined,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                    ),
                    Text(
                      l10n.noInternet,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
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

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    // super.key,
    required this.onDestinationSelected,
    required this.animatedIcons,
    required this.booru,
    required this.showAnimeMangaPages,
  });

  final void Function(BuildContext, CurrentRoute) onDestinationSelected;

  final AnimatedIconsMixin animatedIcons;

  final Booru booru;

  final bool showAnimeMangaPages;

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: false,
      value: 0,
      effects: const [
        SlideEffect(
          curve: Easing.emphasizedAccelerate,
          end: Offset(-1, 0),
          begin: Offset.zero,
        ),
      ],
      controller: animatedIcons.controllerNavBar,
      child: NavigationRail(
        groupAlignment: -0.6,
        onDestinationSelected: (i) => onDestinationSelected(
          context,
          CurrentRoute.fromIndex(i),
        ),
        destinations: animatedIcons.railIcons(
          booru,
          showAnimeMangaPages,
        ),
        selectedIndex: CurrentRoute.of(context).index,
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    // super.key,
    required this.animatedIcons,
    required this.changePage,
    required this.onDestinationSelected,
    required this.callback,
    required this.booru,
    required this.showAnimeMangaPages,
    required this.showRail,
  });

  final AnimatedIconsMixin animatedIcons;
  final ChangePageMixin changePage;

  final void Function(BuildContext, CurrentRoute) onDestinationSelected;

  final CallbackDescriptionNested? callback;

  final Booru booru;

  final bool showAnimeMangaPages;
  final bool showRail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (showRail) {
      SelectionCountNotifier.countOf(context);

      return GlueBottomAppBar(
        GlueStateProvider.of(context),
        controller: animatedIcons.selectionBarController,
      );
    } else {
      final currentRoute = CurrentRoute.of(context);

      return _NavBar(
        noNavigationIcons: callback != null,
        icons: animatedIcons,
        child: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: colorScheme.surfaceContainer.withOpacity(0.95),
          selectedIndex: currentRoute.index,
          onDestinationSelected: (i) =>
              onDestinationSelected(context, CurrentRoute.fromIndex(i)),
          destinations: callback != null
              ? const []
              : animatedIcons.icons(
                  context,
                  booru,
                  showAnimeMangaPages,
                ),
        ),
      );
    }
  }
}

class _SelectionHolder extends StatefulWidget {
  const _SelectionHolder({
    required this.driveAnimation,
    required this.defaultPreferences,
    required this.hideNavBar,
    required this.child,
  });

  final Set<GluePreferences> defaultPreferences;

  final Future<void> Function(bool forward) driveAnimation;
  final void Function(bool hide) hideNavBar;

  final Widget child;

  @override
  State<_SelectionHolder> createState() => __SelectionHolderState();
}

class __SelectionHolderState extends State<_SelectionHolder> {
  late final SelectionGlueState glueState;

  @override
  void initState() {
    super.initState();

    glueState = SelectionGlueState(
      driveAnimation: widget.driveAnimation,
      hideNavBar: widget.hideNavBar,
    );
  }

  SelectionGlue _generate([Set<GluePreferences> set = const {}]) {
    final s = set.isNotEmpty ? set : widget.defaultPreferences;

    return glueState.glue(
      keyboardVisible,
      setState,
      () => s.contains(GluePreferences.zeroSize) ? 0 : 80,
      s.contains(GluePreferences.persistentBarHeight),
    );
  }

  bool keyboardVisible() => MediaQuery.viewInsetsOf(context).bottom != 0;

  @override
  Widget build(BuildContext context) {
    return GlueStateProvider(
      state: glueState,
      child: SelectionCountNotifier(
        count: glueState.count,
        countUpdateTimes: glueState.countUpdateTimes,
        child: GlueProvider(
          generate: _generate,
          child: widget.child,
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.icons,
    required this.noNavigationIcons,
    required this.child,
  });

  final bool noNavigationIcons;
  final AnimatedIconsMixin icons;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glueState = GlueStateProvider.of(context);
    SelectionCountNotifier.countOf(context);

    return noNavigationIcons
        ? GlueBottomAppBar(glueState, controller: icons.selectionBarController)
        : Stack(
            children: [
              GlueBottomAppBar(
                glueState,
                controller: icons.selectionBarController,
              ),
              Animate(
                autoPlay: false,
                controller: icons.controllerNavBar,
                value: 0,
                effects: const [
                  SlideEffect(
                    curve: Easing.emphasizedAccelerate,
                    begin: Offset.zero,
                    end: Offset(0, 1),
                  ),
                ],
                child: child,
              ),
            ],
          );
  }
}

class _Drawer extends StatefulWidget {
  const _Drawer({
    // super.key,
    required this.db,
    required this.changePage,
    required this.animatedIcons,
  });

  final DbConn db;
  final ChangePageMixin changePage;
  final AnimatedIconsMixin animatedIcons;

  @override
  State<_Drawer> createState() => __DrawerState();
}

class __DrawerState extends State<_Drawer> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  late List<GridBookmark> bookmarks = gridBookmarks.firstNumber(5);
  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = gridBookmarks.watch(
      (_) {
        setState(() {
          bookmarks = gridBookmarks.firstNumber(5);
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  final settings = SettingsService.db().current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedBooruPage = BooruSubPage.of(context);

    return NavigationDrawer(
      onDestinationSelected: (value) {
        final nav = widget.changePage.mainKey.currentState;
        if (nav != null) {
          while (nav.canPop()) {
            nav.pop();
          }
        }

        BooruSubPage.selectOf(context, BooruSubPage.fromIdx(value));
        Scaffold.of(context).closeDrawer();
        widget.changePage.animateIcons(
          widget.animatedIcons,
          SettingsService.db().current.showAnimeMangaPages,
        );
      },
      selectedIndex: selectedBooruPage.index,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            l10n.booruLabel,
            style: theme.textTheme.titleSmall,
          ),
        ),
        ...BooruSubPage.values.map(
          (e) => NavigationDrawerDestination(
            selectedIcon: Icon(e.selectedIcon),
            icon: Icon(e.icon),
            label: Text(
              e == BooruSubPage.booru
                  ? settings.selectedBooru.string
                  : e.translatedString(l10n),
            ),
          ),
        ),
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
                    style: theme.textTheme.labelLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...bookmarks.map((e) {
            return SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: InkWell(
                  onTap: () {
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
                  },
                  customBorder: const StadiumBorder(),
                  child: Row(
                    children: [
                      const Padding(padding: EdgeInsets.only(left: 28 - 16)),
                      Icon(
                        Icons.bookmark_outline_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const Padding(padding: EdgeInsets.only(right: 12)),
                      Text(
                        e.tags,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
