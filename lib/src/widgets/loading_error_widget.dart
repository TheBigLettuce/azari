// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class LoadingErrorWidget extends StatefulWidget {
  const LoadingErrorWidget({
    super.key,
    required this.error,
    required this.refresh,
    this.short = true,
  });

  final bool short;

  final String error;

  final VoidCallback refresh;

  @override
  State<LoadingErrorWidget> createState() => _LoadingErrorWidgetState();
}

class _LoadingErrorWidgetState extends State<LoadingErrorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.short) {
      return GestureDetector(
        onTap: () {
          controller.forward().then((value) => widget.refresh());
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.2),
          ),
          child: SizedBox.expand(
            child: Center(
              child: Animate(
                autoPlay: false,
                effects: [
                  FadeEffect(
                    duration: 200.ms,
                    curve: Easing.standard,
                    begin: 1,
                    end: 0,
                  ),
                  RotateEffect(
                    duration: 200.ms,
                    curve: Easing.standard,
                  ),
                ],
                controller: controller,
                child: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      child: Center(
        child: InkWell(
          onTap: widget.refresh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(padding: EdgeInsets.only(top: 20)),
              Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 4),
                child: Text(
                  widget.error,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    overflow: TextOverflow.ellipsis,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
