// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _BottomWidget extends PreferredSize {
  const _BottomWidget({
    required super.preferredSize,
    this.routeChanger,
    required this.isRefreshing,
    required super.child,
  });
  final bool isRefreshing;
  final Widget? routeChanger;

  @override
  Widget build(BuildContext context) {
    return routeChanger != null
        ? Column(
            children: [
              routeChanger!,
              super.build(context),
            ],
          )
        : !isRefreshing
            ? super.build(context)
            : const LinearProgressIndicator();
  }
}
