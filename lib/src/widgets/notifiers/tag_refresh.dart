// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class TagRefreshNotifier extends InheritedWidget {
  const TagRefreshNotifier({
    super.key,
    required this.notify,
    required this.isRefreshing,
    required this.setIsRefreshing,
    required super.child,
  });
  final bool isRefreshing;
  final void Function() notify;
  final void Function(bool) setIsRefreshing;

  static void Function()? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagRefreshNotifier>();

    return widget?.notify;
  }

  static bool? isRefreshingOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagRefreshNotifier>();

    return widget?.isRefreshing;
  }

  static void Function(bool)? setIsRefreshingOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagRefreshNotifier>();

    return widget?.setIsRefreshing;
  }

  @override
  bool updateShouldNotify(TagRefreshNotifier oldWidget) =>
      oldWidget.notify != notify ||
      oldWidget.isRefreshing != isRefreshing ||
      oldWidget.setIsRefreshing != setIsRefreshing;
}
