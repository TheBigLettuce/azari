// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

part "../parts/fab.dart";

sealed class GridFabType {
  const GridFabType();

  Widget widget(BuildContext context);
}

class NoGridFab implements GridFabType {
  const NoGridFab();

  @override
  Widget widget(BuildContext context) => const SizedBox.shrink();
}

class DefaultGridFab implements GridFabType {
  const DefaultGridFab();

  @override
  Widget widget(BuildContext context) {
    return IsScrollingNotifier(
      notifier: GridScrollNotifier.notifierOf(context),
      child: const _Fab(),
    );
  }
}

class OverrideGridFab implements GridFabType {
  const OverrideGridFab(this.child);

  final Widget Function() child;

  @override
  Widget widget(BuildContext context) {
    return IsScrollingNotifier(
      notifier: GridScrollNotifier.notifierOf(context),
      child: child(),
    );
  }
}

class IsScrollingNotifier extends InheritedNotifier<ValueNotifier<bool>> {
  const IsScrollingNotifier({
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static bool of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<IsScrollingNotifier>();

    return widget!.notifier!.value;
  }
}
