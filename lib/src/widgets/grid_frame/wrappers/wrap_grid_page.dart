// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/build_theme.dart";
import "package:azari/src/pages/home/home_skeleton.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class WrapGridPage extends StatefulWidget {
  const WrapGridPage({
    super.key,
    this.addScaffoldAndBar = false,
    this.navBarHeight = 80,
    required this.child,
  });

  final bool addScaffoldAndBar;

  final int navBarHeight;

  final Widget child;

  @override
  State<WrapGridPage> createState() => _WrapGridPageState();
}

class _WrapGridPageState extends State<WrapGridPage> {
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
                bottomNavigationBar: _SlidingBar(
                  actions: _actions!,
                ),
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
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final StreamSubscription<void> _expandedEvents;
  late final StreamSubscription<List<SelectionButton> Function()?>
      _actionEvents;

  List<SelectionButton> _actions = const [];
  List<SelectionButton> Function()? _prevFunc;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Durations.medium1);

    _actionEvents = widget.actions
        .connect(const SelectionAreaSize(base: 0, expanded: 80))
        .listen((newActions) {
      if (_prevFunc == newActions) {
        return;
      } else if (newActions == null) {
        setState(() {
          _prevFunc = null;
          _actions = const [];
        });
      } else {
        setState(() {
          _actions = newActions();
          _prevFunc = newActions;
        });
      }
    });

    _expandedEvents = widget.actions.controller.expandedEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _expandedEvents.cancel();
    _actionEvents.cancel();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: false,
      controller: controller,
      value: widget.actions.controller.isExpanded ? 1 : 0,
      effects: [
        MoveEffect(
          duration: 220.ms,
          curve: Easing.emphasizedDecelerate,
          end: Offset.zero,
          begin: Offset(0, 100 + MediaQuery.viewPaddingOf(context).bottom),
        ),
      ],
      child: SelectionBar(
        selectionActions: widget.actions,
        actions: _actions,
      ),
    );
  }
}
