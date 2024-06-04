// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";

class CurrentContentNotifier extends InheritedWidget {
  const CurrentContentNotifier({
    super.key,
    required this.content,
    required super.child,
  });
  final Contentable content;

  static Contentable of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CurrentContentNotifier>();

    return widget!.content;
  }

  @override
  bool updateShouldNotify(CurrentContentNotifier oldWidget) =>
      content != oldWidget.content;
}
