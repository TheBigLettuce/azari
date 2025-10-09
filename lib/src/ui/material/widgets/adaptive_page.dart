// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class AdaptivePage extends StatefulWidget {
  const AdaptivePage({super.key, required this.child});

  final Widget child;

  static AdaptivePageSize size(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageSizeNotifier>()!.size;

  @override
  State<AdaptivePage> createState() => _AdaptivePageState();
}

class _AdaptivePageState extends State<AdaptivePage> {
  AdaptivePageSize _size = AdaptivePageSize.small;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _size = AdaptivePageSize.fromWidth(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    return _PageSizeNotifier(size: _size, child: widget.child);
  }
}

enum AdaptivePageSize {
  extraSmall,
  small,
  medium,
  large,
  extraLarge;

  static AdaptivePageSize fromWidth(Size size) => switch (size.width) {
    >= 1536 => extraLarge,
    >= 1200 => large,
    >= 900 => medium,
    >= 600 => small,
    double() => extraSmall,
  };

  static AdaptivePageSize of(BuildContext context) =>
      AdaptivePage.size(context);
}

class _PageSizeNotifier extends InheritedNotifier {
  const _PageSizeNotifier({required this.size, required super.child});

  final AdaptivePageSize size;

  @override
  bool updateShouldNotify(_PageSizeNotifier oldWidget) {
    return size != oldWidget.size;
  }
}
