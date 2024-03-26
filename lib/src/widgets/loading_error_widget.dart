// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingErrorWidget extends StatefulWidget {
  final String error;
  final bool short;
  final void Function() refresh;

  const LoadingErrorWidget({
    super.key,
    required this.error,
    required this.refresh,
    this.short = true,
  });

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
    IconButton;
    if (widget.short) {
      return GestureDetector(
        onTap: () {
          controller.forward().then((value) => widget.refresh());
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
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

    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                widget.error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
