// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class WrapGridActionButton extends StatefulWidget {
  const WrapGridActionButton(
    this.icon,
    this.onPressed, {
    super.key,
    this.color,
    required this.onLongPress,
    required this.whenSingleContext,
    required this.play,
    required this.animate,
    this.watch,
    required this.animation,
    this.iconOnly = false,
  });

  final IconData icon;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final Color? color;
  final bool animate;
  final bool play;
  final BuildContext? whenSingleContext;
  final List<Effect<dynamic>> animation;

  final WatchFire<(IconData?, Color?, bool?)>? watch;

  final bool iconOnly;

  @override
  State<WrapGridActionButton> createState() => _WrapGridActionButtonState();
}

class _WrapGridActionButtonState extends State<WrapGridActionButton>
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

    final icon = TweenAnimationBuilder(
        tween: ColorTween(end: data.$2 ?? theme.colorScheme.onSurface),
        duration: Durations.medium1,
        curve: Easing.linear,
        builder: (context, color, _) {
          return Icon(
            data.$1,
            color: color,
          );
        });

    if (widget.iconOnly) {
      return GestureDetector(
        onTap: widget.whenSingleContext != null &&
                SelectionCountNotifier.countOf(widget.whenSingleContext!) != 1
            ? null
            : widget.onPressed == null
                ? null
                : onPressed,
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
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
                theme.colorScheme.surfaceContainerLow.withOpacity(0.9)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
              ),
            ),
          ),
          onPressed: widget.whenSingleContext != null &&
                  SelectionCountNotifier.countOf(widget.whenSingleContext!) != 1
              ? null
              : widget.onPressed == null
                  ? null
                  : onPressed,
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
