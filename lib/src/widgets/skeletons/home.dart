// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
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
        bottomNavigationBar: navBar,
        resizeToAvoidBottomInset: false,
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
