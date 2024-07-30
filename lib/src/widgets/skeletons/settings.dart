// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/build_theme.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";

class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton(
    this.pageDescription,
    this.state, {
    super.key,
    this.appBar,
    this.bottomAppBar,
    this.fab,
    this.expectSliverBody = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    required this.child,
  });

  final String pageDescription;
  final SkeletonState state;
  final PreferredSizeWidget? appBar;
  final Widget? bottomAppBar;
  final Widget? fab;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool expectSliverBody;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    final theme = Theme.of(context);

    return AnnotatedRegion(
      value: navBarStyleForTheme(theme),
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        bottomNavigationBar: bottomAppBar,
        extendBody: extendBody,
        floatingActionButton: fab,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        drawerEnableOpenDragGesture:
            MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
        appBar: appBar,
        body: GestureDeadZones(
          left: true,
          right: true,
          child: appBar == null && expectSliverBody
              ? CustomScrollView(
                  slivers: [
                    SliverAppBar.large(
                      expandedHeight: 160,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          pageDescription,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: insets.bottom),
                      sliver: child,
                    ),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
