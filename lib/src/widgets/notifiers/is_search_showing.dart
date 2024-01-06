// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class IsSearchShowingHolder extends StatefulWidget {
  final bool defaultValue;
  final Widget child;

  const IsSearchShowingHolder(
      {super.key, this.defaultValue = false, required this.child});

  @override
  State<IsSearchShowingHolder> createState() => _IsSearchShowingHolderState();
}

class _IsSearchShowingHolderState extends State<IsSearchShowingHolder> {
  late bool isSearching = widget.defaultValue;

  @override
  Widget build(BuildContext context) {
    return IsSearchShowingNotifier(
      isSearching: isSearching,
      flip: () => setState(() {
        isSearching = !isSearching;
      }),
      child: widget.child,
    );
  }
}

class IsSearchShowingNotifier extends InheritedWidget {
  final bool isSearching;
  final void Function() flip;

  const IsSearchShowingNotifier(
      {super.key,
      required this.isSearching,
      required this.flip,
      required super.child});

  static bool of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<IsSearchShowingNotifier>();

    return widget!.isSearching;
  }

  static bool? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<IsSearchShowingNotifier>();

    return widget?.isSearching;
  }

  static void flipOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<IsSearchShowingNotifier>();

    widget!.flip();
  }

  @override
  bool updateShouldNotify(IsSearchShowingNotifier oldWidget) =>
      oldWidget.isSearching != isSearching;
}
