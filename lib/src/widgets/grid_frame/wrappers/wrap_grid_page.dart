// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/main.dart";
import "package:gallery/src/pages/glue_bottom_app_bar.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

class WrapGridPage extends StatefulWidget {
  const WrapGridPage({
    super.key,
    this.provided,
    this.addScaffold = false,
    this.navBarHeight = 80,
    required this.child,
  });
  final SelectionGlue Function([Set<GluePreferences>])? provided;
  final int navBarHeight;
  final bool addScaffold;
  final Widget child;

  @override
  State<WrapGridPage> createState() => _WrapGridPageState();
}

class _WrapGridPageState extends State<WrapGridPage>
    with SingleTickerProviderStateMixin {
  final glueState = SelectionGlueState(
    hide: (_) {},
  );
  SelectionGlue _generate([Set<GluePreferences> set = const {}]) {
    return widget.provided?.call(set) ??
        glueState.glue(
          () => MediaQuery.viewInsetsOf(context).bottom != 0,
          (f) {
            setState(f);
          },
          () => widget.navBarHeight,
          false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = SelectionCountNotifier(
      count: glueState.count,
      countUpdateTimes: glueState.countUpdateTimes,
      child: GlueProvider(
        generate: _generate,
        child: widget.child,
      ),
    );

    return widget.addScaffold
        ? AnnotatedRegion(
            value: navBarStyleForTheme(
              theme,
              transparent: false,
              highTone: false,
            ),
            child: Scaffold(
              extendBody: true,
              resizeToAvoidBottomInset: false,
              bottomNavigationBar: Animate(
                target: glueState.actions?.$1 == null ? 0 : 1,
                effects: [
                  MoveEffect(
                    duration: 220.ms,
                    curve: Easing.emphasizedDecelerate,
                    end: Offset.zero,
                    begin: Offset(
                      0,
                      100 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                  ),
                ],
                child: GlueBottomAppBar(glueState),
              ),
              body: GestureDeadZones(
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
                      child: child,
                    );
                  },
                ),
              ),
            ),
          )
        : child;
  }
}
