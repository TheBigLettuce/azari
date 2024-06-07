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
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton(
    this.state,
    this.f, {
    super.key,
    required this.extendBody,
    required this.navBar,
    required this.noNavBar,
  });
  final SkeletonState state;
  final Widget Function(BuildContext) f;
  final bool extendBody;

  final Widget navBar;
  final bool noNavBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnnotatedRegion(
      value: navBarStyleForTheme(
        theme,
        transparent: !noNavBar,
        highTone: !noNavBar,
      ),
      child: Scaffold(
        extendBody: extendBody,
        extendBodyBehindAppBar: true,
        drawerEnableOpenDragGesture: false,
        bottomNavigationBar: navBar,
        resizeToAvoidBottomInset: false,
        drawer: _Drawer(
          db: DatabaseConnectionNotifier.of(context),
        ),
        body: GestureDeadZones(
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
                    final bottomPadding =
                        MediaQuery.viewPaddingOf(context).bottom;

                    final data = MediaQuery.of(buildContext);

                    return MediaQuery(
                      data: data.copyWith(
                        viewPadding: data.viewPadding +
                            EdgeInsets.only(bottom: bottomPadding),
                      ),
                      child: Builder(builder: f),
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
                                    color:
                                        colorScheme.onSurface.withOpacity(0.8),
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
        ),
      ),
    );
  }
}

class _Drawer extends StatefulWidget {
  const _Drawer({
    // super.key,
    required this.db,
  });

  final DbConn db;

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
