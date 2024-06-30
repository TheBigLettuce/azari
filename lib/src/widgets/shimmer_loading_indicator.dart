// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class ShimmerLoadingIndicator extends StatelessWidget {
  const ShimmerLoadingIndicator({
    super.key,
    this.delay = const Duration(seconds: 1),
    this.duration = const Duration(milliseconds: 500),
  });

  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Animate(
      onComplete: (controller) => controller.repeat(),
      effects: [
        ShimmerEffect(
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          delay: delay,
          duration: duration,
        ),
      ],
      child: Container(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
    );
  }
}
