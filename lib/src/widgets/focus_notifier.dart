// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class FocusNotifier extends InheritedNotifier<FocusNode> {
  const FocusNotifier({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ({VoidCallback unfocus, bool hasFocus}) of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FocusNotifier>()!;

    return (
      hasFocus: widget.notifier?.hasFocus ?? false,
      unfocus: widget.notifier?.previousFocus ?? () {},
    );
  }
}
