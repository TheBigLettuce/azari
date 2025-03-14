// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/build_theme.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class ScaffoldSelectionBar extends StatefulWidget {
  const ScaffoldSelectionBar({
    super.key,
    this.addScaffoldAndBar = false,
    this.navBarHeight = 80,
    required this.child,
  });

  final bool addScaffoldAndBar;

  final int navBarHeight;

  final Widget child;

  @override
  State<ScaffoldSelectionBar> createState() => _ScaffoldSelectionBarState();
}

class _ScaffoldSelectionBarState extends State<ScaffoldSelectionBar> {
  late final SelectionActions? _actions;

  @override
  void initState() {
    super.initState();

    _actions = widget.addScaffoldAndBar ? SelectionActions() : null;
  }

  @override
  void dispose() {
    _actions?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return widget.addScaffoldAndBar
        ? _actions!.inject(
            AnnotatedRegion(
              value: navBarStyleForTheme(
                theme,
                transparent: false,
                highTone: false,
              ),
              child: Scaffold(
                extendBody: true,
                resizeToAvoidBottomInset: false,
                bottomNavigationBar: _SlidingBar(actions: _actions),
                body: GestureDeadZones(
                  left: true,
                  right: true,
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
                        child: widget.child,
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        : widget.child;
  }
}

class _SlidingBar extends StatefulWidget {
  const _SlidingBar({
    // super.key,
    required this.actions,
  });

  final SelectionActions actions;

  @override
  State<_SlidingBar> createState() => __SlidingBarState();
}

class __SlidingBarState extends State<_SlidingBar>
    with DefaultSelectionEventsMixin {
  @override
  SelectionAreaSize get selectionSizes =>
      const SelectionAreaSize(base: 0, expanded: 80);

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: false,
      target: widget.actions.controller.isExpanded ? 1 : 0,
      effects: [
        SlideEffect(
          duration: 220.ms,
          curve: Easing.standard,
          end: Offset.zero,
          begin: const Offset(0, 1),
        ),
      ],
      child: SelectionBar(
        selectionActions: widget.actions,
        actions: actions,
      ),
    );
  }
}
