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
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/glue_bottom_app_bar.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton(
    this.f, {
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

  final void Function(BuildContext, int) onDestinationSelected;

  final Widget Function(BuildContext) f;
  final bool extendBody;
  final AnimatedIconsMixin animatedIcons;
  final ChangePageMixin changePage;

  final Booru booru;

  final CallbackDescriptionNested? callback;

  final bool showAnimeMangaPages;
  final bool noNavBar;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> {
  ChangePageMixin get changePage => widget.changePage;
  int get currentRoute => changePage.currentRoute;

  bool showRail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    showRail = MediaQuery.sizeOf(context).width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final child = GestureDeadZones(
      right: true,
      left: true,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Easing.standard,
            padding: EdgeInsets.only(
              top: NetworkStatus.g.hasInternet ? 0 : 24,
            ),
            child: Builder(
              builder: (buildContext) {
                final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

                final data = MediaQuery.of(buildContext);

                return MediaQuery(
                  data: data.copyWith(
                    viewPadding: data.viewPadding +
                        EdgeInsets.only(bottom: bottomPadding),
                  ),
                  child: Builder(builder: widget.f),
                );
              },
            ),
          ),
          if (!NetworkStatus.g.hasInternet)
            Animate(
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
                  color: ElevationOverlay.applySurfaceTint(
                    colorScheme.surface,
                    colorScheme.surfaceTint,
                    3,
                  ).withOpacity(0.8),
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
                              AppLocalizations.of(context)!.noInternet,
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
            ),
        ],
      ),
    );

    return _SelectionHolder(
      hide: widget.animatedIcons.hide,
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
          bottomNavigationBar: showRail
              ? Builder(
                  builder: (context) {
                    SelectionCountNotifier.countOf(context);

                    return GlueBottomAppBar(
                      GlueStateProvider.of(context),
                      controller: widget.animatedIcons.selectionBarController,
                    );
                  },
                )
              : Builder(builder: (context) {
                  return _NavBar(
                    noNavigationIcons: widget.callback != null,
                    icons: widget.animatedIcons,
                    child: Builder(
                      builder: (context) => NavigationBar(
                        labelBehavior:
                            NavigationDestinationLabelBehavior.onlyShowSelected,
                        backgroundColor: theme.colorScheme.surfaceContainer
                            .withOpacity(0.95),
                        selectedIndex: currentRoute,
                        onDestinationSelected: (i) =>
                            widget.onDestinationSelected(context, i),
                        destinations: widget.callback != null
                            ? const []
                            : widget.animatedIcons.icons(
                                context,
                                currentRoute,
                                widget.booru,
                                widget.showAnimeMangaPages,
                              ),
                      ),
                    ),
                  );
                }),
          resizeToAvoidBottomInset: false,
          drawer: _Drawer(
              changePage: widget.changePage,
              db: DatabaseConnectionNotifier.of(context)),
          body: showRail && widget.callback == null
              ? Row(
                  children: [
                    Animate(
                      autoPlay: false,
                      value: 0,
                      effects: const [
                        SlideEffect(
                          curve: Easing.emphasizedAccelerate,
                          end: Offset(-1, 0),
                          begin: Offset.zero,
                        ),
                      ],
                      controller: widget.animatedIcons.controllerNavBar,
                      child: Builder(builder: (context) {
                        return NavigationRail(
                          // leading: IconButton(
                          //   onPressed: () {
                          //     Scaffold.of(context).openDrawer();
                          //   },
                          //   icon: const Icon(Icons.menu_rounded),
                          // ),
                          groupAlignment: -0.6,
                          onDestinationSelected: (i) =>
                              widget.onDestinationSelected(context, i),
                          destinations: widget.animatedIcons.railIcons(
                            currentRoute,
                            widget.booru,
                            widget.showAnimeMangaPages,
                          ),
                          selectedIndex: widget.changePage.currentRoute,
                        );
                      }),
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

class _SelectionHolder extends StatefulWidget {
  const _SelectionHolder({
    required this.hide,
    required this.defaultPreferences,
    required this.child,
  });
  final Widget child;
  final Set<GluePreferences> defaultPreferences;

  final void Function(bool backward) hide;

  @override
  State<_SelectionHolder> createState() => __SelectionHolderState();
}

class __SelectionHolderState extends State<_SelectionHolder> {
  late final SelectionGlueState glueState;

  @override
  void initState() {
    super.initState();

    glueState = SelectionGlueState(hide: widget.hide);
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
        : Animate(
            controller: icons.controllerNavBar,
            target: glueState.actions != null ? 1 : 0,
            effects: [
              const MoveEffect(
                curve: Easing.emphasizedAccelerate,
                begin: Offset.zero,
                end: Offset(0, 100),
              ),
              SwapEffect(
                builder: (context, _) {
                  return glueState.actions != null
                      ? GlueBottomAppBar(
                          glueState,
                          controller: icons.selectionBarController,
                        )
                      : const Padding(padding: EdgeInsets.zero);
                },
              ),
            ],
            child: child,
          );
  }
}

class _Drawer extends StatefulWidget {
  const _Drawer({
    // super.key,
    required this.db,
    required this.changePage,
  });

  final DbConn db;
  final ChangePageMixin changePage;

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

    return Builder(
      builder: (context) => NavigationDrawer(
        onDestinationSelected: (value) {
          final nav = widget.changePage.mainKey.currentState;
          if (nav != null) {
            while (nav.canPop()) {
              nav.pop();
            }
          }

          BooruSubPage.selectOf(context, BooruSubPage.fromIdx(value));
          Scaffold.of(context).closeDrawer();
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
      ),
    );
  }
}
