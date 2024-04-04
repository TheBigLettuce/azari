// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';

import '../configuration/selection_glue.dart';
import '../configuration/selection_glue_state.dart';

class WrapGridPage extends StatefulWidget {
  final SelectionGlue Function([Set<GluePreferences>])? provided;
  final int navBarHeight;
  final bool addScaffold;
  final Widget child;

  const WrapGridPage({
    super.key,
    this.provided,
    this.addScaffold = false,
    this.navBarHeight = 80,
    required this.child,
  });

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
    final child = SelectionCountNotifier(
      count: glueState.count,
      countUpdateTimes: glueState.countUpdateTimes,
      child: GlueProvider(
        generate: _generate,
        child: widget.child,
      ),
    );

    return widget.addScaffold ? Scaffold(body: child) : child;
  }
}
