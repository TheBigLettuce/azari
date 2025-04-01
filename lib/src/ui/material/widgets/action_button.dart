// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";

class ActionButton extends StatefulWidget {
  const ActionButton(
    this.icon,
    this.onPressed, {
    super.key,
    this.color,
    required this.onLongPress,
    required this.play,
    required this.animate,
    required this.taskTag,
    this.watch,
    required this.animation,
    this.iconOnly = false,
    this.addBorder = true,
  });

  final bool addBorder;
  final bool animate;
  final bool iconOnly;
  final bool play;

  final IconData icon;

  final Color? color;

  final List<Effect<dynamic>> animation;

  final Type? taskTag;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  final WatchFire<(IconData?, Color?, bool?)>? watch;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  StreamSubscription<(IconData?, Color?, bool?)>? _subscr;

  late (IconData, Color?, bool) data = (widget.icon, widget.color, widget.play);

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Durations.medium2);

    _subscr = widget.watch?.call(
      (d) {
        data = (d.$1 ?? data.$1, d.$2, d.$3 ?? data.$3);

        setState(() {});
      },
      true,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _subscr?.cancel();

    super.dispose();
  }

  void onPressed() {
    if (widget.animate && data.$3) {
      controller.reset();
      controller.animateTo(1).then((value) => controller.animateBack(0));
    }
    HapticFeedback.selectionClick();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tag = widget.taskTag != null
        ? const TasksService().statusUnsafe(context, widget.taskTag!)
        : TaskStatus.done;

    final icon = tag.isWaiting
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : TweenAnimationBuilder(
            tween: ColorTween(end: data.$2 ?? theme.colorScheme.onSurface),
            duration: Durations.medium1,
            curve: Easing.linear,
            builder: (context, color, _) {
              return Icon(
                data.$1,
                color: widget.onPressed == null || widget.onPressed == null
                    ? theme.disabledColor.withValues(alpha: 0.5)
                    : color,
              );
            },
          );

    if (widget.iconOnly) {
      return GestureDetector(
        onTap: widget.onPressed == null ? null : onPressed,
        child: widget.animate
            ? Animate(
                effects: widget.animation,
                controller: controller,
                autoPlay: false,
                child: icon,
              )
            : icon,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: GestureDetector(
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                widget.onLongPress!();
                HapticFeedback.lightImpact();
              },
        child: IconButton(
          style: !widget.addBorder
              ? null
              : ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerLow
                        .withValues(alpha: 0.9),
                  ),
                  shape: const WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
                    ),
                  ),
                ),
          onPressed: widget.onPressed == null ? null : onPressed,
          icon: widget.animate
              ? Animate(
                  effects: widget.animation,
                  controller: controller,
                  autoPlay: false,
                  child: icon,
                )
              : icon,
        ),
      ),
    );
  }
}
