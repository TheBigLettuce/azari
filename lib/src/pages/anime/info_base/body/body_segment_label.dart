// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class BodySegmentLabel extends StatelessWidget {
  const BodySegmentLabel({
    super.key,
    required this.text,
    this.sliver = false,
    this.onLongPress,
  });

  final String text;
  final bool sliver;

  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = Text(
      text,
      style: theme.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: theme.colorScheme.onSurface.withOpacity(0.75),
      ),
    );

    const padding = EdgeInsets.only(bottom: 8, top: 12);

    return GestureDetector(
      onLongPress: onLongPress,
      child: sliver
          ? SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: child,
              ),
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );
  }
}
