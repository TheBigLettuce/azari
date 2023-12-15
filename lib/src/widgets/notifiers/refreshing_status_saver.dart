// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class RefreshingStatusSaver extends InheritedWidget {
  final void Function(Future<int>) save;
  final void Function(void Function(int?, bool)) register;
  final void Function() reset;
  final void Function(void Function(int?, bool)) unregister;

  const RefreshingStatusSaver(
      {super.key,
      required this.save,
      required this.register,
      required this.unregister,
      required this.reset,
      required super.child});

  static bool saveOf(BuildContext context, Future<int> status) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<RefreshingStatusSaver>();

    widget?.save(status);

    return widget != null;
  }

  static void registerOf(BuildContext context, void Function(int?, bool) f) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<RefreshingStatusSaver>();

    widget?.register(f);
  }

  static void resetOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<RefreshingStatusSaver>();

    widget?.reset();
  }

  static void unregisterOf(BuildContext context, void Function(int?, bool) f) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<RefreshingStatusSaver>();

    widget?.unregister(f);
  }

  @override
  bool updateShouldNotify(RefreshingStatusSaver oldWidget) =>
      register != oldWidget.register ||
      save != oldWidget.save ||
      reset != oldWidget.reset ||
      unregister != oldWidget.unregister;
}
