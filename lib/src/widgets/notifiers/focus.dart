// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class FocusNotifier extends InheritedNotifier<FocusNode> {
  const FocusNotifier({
    super.key,
    required super.notifier,
    required this.focusMain,
    required super.child,
  });
  final void Function() focusMain;

  static FocusNotifierData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FocusNotifier>()!;

    return FocusNotifierData(
      hasFocus: widget.notifier?.hasFocus ?? false,
      unfocus: widget.focusMain,
    );
  }
}

class FocusNotifierData {
  const FocusNotifierData({required this.hasFocus, required this.unfocus});
  final void Function() unfocus;
  final bool hasFocus;
}
