// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class BodySegmentLabel extends StatelessWidget {
  final String text;
  final bool sliver;

  const BodySegmentLabel({
    super.key,
    required this.text,
    this.sliver = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      // textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
          ),
    );

    const padding = EdgeInsets.only(bottom: 8, top: 12);

    return sliver
        ? SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: child,
            ),
          )
        : Padding(
            padding: padding,
            child: child,
          );
  }
}
