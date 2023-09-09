// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../booru/interface.dart';

class BooruNotifier extends InheritedWidget {
  final Booru booru;

  static Booru of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<BooruNotifier>();

    return widget!.booru;
  }

  @override
  bool updateShouldNotify(BooruNotifier oldWidget) {
    return booru != oldWidget.booru;
  }

  const BooruNotifier({super.key, required this.booru, required super.child});
}
