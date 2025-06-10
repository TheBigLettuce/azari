// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";

class ScaffoldWithSelectionBar extends StatefulWidget {
  const ScaffoldWithSelectionBar({
    super.key,
    this.actions,
    this.navBarHeight = 80,
    required this.child,
  });

  final SelectionActions? actions;

  final int navBarHeight;

  final Widget child;

  @override
  State<ScaffoldWithSelectionBar> createState() =>
      _ScaffoldWithSelectionBarState();
}

class _ScaffoldWithSelectionBarState extends State<ScaffoldWithSelectionBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.actions != null) {
      return widget.actions!.inject(
        AnnotatedRegion(
          value: makeSystemUiOverlayStyle(theme),
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: SelectionBar(actions: widget.actions!),
            body: GestureDeadZones(
              left: true,
              right: true,
              child: Builder(
                builder: (buildContext) {
                  final bottomPadding = MediaQuery.viewPaddingOf(
                    context,
                  ).bottom;

                  final data = MediaQuery.of(buildContext);

                  return MediaQuery(
                    data: data.copyWith(
                      viewPadding:
                          data.viewPadding +
                          EdgeInsets.only(bottom: bottomPadding),
                    ),
                    child: widget.child,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
