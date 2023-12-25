// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../db/state_restoration.dart';

class TagManagerNotifier<T extends TagManagerType> extends InheritedWidget {
  const TagManagerNotifier._(
      {super.key, required this.tagManager, required super.child});

  final TagManager<T> tagManager;

  @override
  bool updateShouldNotify(TagManagerNotifier oldWidget) {
    return tagManager != oldWidget.tagManager;
  }

  static TagManagerNotifier<Restorable> restorable(
          TagManager<Restorable> tagManager, Widget child) =>
      TagManagerNotifier._(tagManager: tagManager, child: child);

  static TagManagerNotifier<Unrestorable> unrestorable(
          TagManager<Unrestorable> tagManager, Widget child) =>
      TagManagerNotifier._(tagManager: tagManager, child: child);

  static TagManager<Restorable> ofRestorable(BuildContext context) {
    return maybeOfRestorable(context)!;
  }

  static TagManager<Restorable>? maybeOfRestorable(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<TagManagerNotifier<Restorable>>();

    return widget?.tagManager;
  }

  static TagManager<Unrestorable> ofUnrestorable(BuildContext context) {
    return maybeOfUnrestorable(context)!;
  }

  static TagManager<Unrestorable>? maybeOfUnrestorable(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<TagManagerNotifier<Unrestorable>>();

    return widget?.tagManager;
  }
}
