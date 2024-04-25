// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class ImageViewInfoTilesRefreshNotifier extends InheritedWidget {
  const ImageViewInfoTilesRefreshNotifier({
    super.key,
    required this.count,
    required this.incr,
    required super.child,
  });
  final void Function() incr;
  final int count;

  static void refreshOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<
        ImageViewInfoTilesRefreshNotifier>();

    widget?.incr();
  }

  static int of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<
        ImageViewInfoTilesRefreshNotifier>();

    return widget!.count;
  }

  @override
  bool updateShouldNotify(ImageViewInfoTilesRefreshNotifier oldWidget) =>
      count != oldWidget.count;
}
