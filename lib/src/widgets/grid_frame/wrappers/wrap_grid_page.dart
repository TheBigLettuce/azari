// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';

import '../../../interfaces/cell/cell.dart';
import '../../../pages/glue_bottom_app_bar.dart';
import '../configuration/selection_glue.dart';
import '../configuration/selection_glue_state.dart';

class WrapGridPage<T extends Cell> extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final SelectionGlue<J> Function<J extends Cell>()? provided;
  final int navBarHeight;
  final Widget child;

  const WrapGridPage({
    super.key,
    required this.scaffoldKey,
    this.provided,
    this.navBarHeight = 80,
    required this.child,
  });

  @override
  State<WrapGridPage<T>> createState() => _WrapGridPageState();
}

class _WrapGridPageState<T extends Cell> extends State<WrapGridPage<T>>
    with SingleTickerProviderStateMixin {
  final glueState = SelectionGlueState(
    hide: (_) {},
  );
  late SelectionGlue<T> glue = widget.provided?.call() ??
      glueState.glue<T>(() => MediaQuery.viewInsetsOf(context).bottom != 0,
          (f) {
        glue = _generate();

        setState(f);
      }, () => widget.navBarHeight, false);

  SelectionGlue<J> _generate<J extends Cell>() {
    return widget.provided?.call() ??
        glueState.glue(() => MediaQuery.viewInsetsOf(context).bottom != 0, (f) {
          glue = _generate();

          setState(f);
        }, () => widget.navBarHeight, false);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionCountNotifier(
      count: glueState.count,
      child: GlueProvider<T>(
        generate: _generate,
        glue: glue,
        child: Scaffold(
          key: widget.scaffoldKey,
          extendBody: true,
          bottomNavigationBar: widget.provided != null
              ? null
              : Animate(
                  target: glueState.actions?.$1 == null ? 0 : 1,
                  effects: [
                    MoveEffect(
                      duration: 220.ms,
                      curve: Easing.emphasizedDecelerate,
                      end: Offset.zero,
                      begin: Offset(
                          0, 100 + MediaQuery.viewPaddingOf(context).bottom),
                    ),
                  ],
                  child: GlueBottomAppBar(glueState),
                ),
          body: widget.child,
        ),
      ),
    );
  }
}
