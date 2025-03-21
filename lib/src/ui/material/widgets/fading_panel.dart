// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/resource_source/resource_source.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class FadingPanel extends StatefulWidget {
  const FadingPanel({
    super.key,
    required this.label,
    this.trailing,
    required this.source,
    required this.childSize,
    this.enableHide = true,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 18),
    required this.child,
  });

  final String label;
  final (IconData, void Function())? trailing;

  final ResourceSource<dynamic, dynamic> source;
  final Size childSize;

  final bool enableHide;

  final EdgeInsets horizontalPadding;

  final Widget child;

  @override
  State<FadingPanel> createState() => _FadingPanelState();
}

class _FadingPanelState extends State<FadingPanel>
    with SingleTickerProviderStateMixin {
  bool shrink = false;

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  final tween = Tween<double>(begin: -1.570796, end: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    final textSize =
        MediaQuery.textScalerOf(context).scale(textStyle?.fontSize ?? 28);

    final double labelSize = widget.label.isEmpty ? 0 : 18 + 18 + 6 + textSize;

    final body = Animate(
      value: 1,
      autoPlay: false,
      controller: controller,
      effects: const [
        FadeEffect(
          begin: 0,
          end: 1,
        ),
      ],
      child: shrink ? const SizedBox.shrink() : widget.child,
    );

    return FadingController(
      source: widget.source,
      childSize: Size(
        widget.childSize.width,
        (shrink ? 0 : widget.childSize.height) + labelSize,
      ),
      child: widget.label.isEmpty
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FadingPanelLabel(
                  horizontalPadding: widget.horizontalPadding,
                  label: widget.label,
                  controller: controller,
                  onPressed: widget.enableHide
                      ? () {
                          if (shrink) {
                            controller.forward().then((_) {
                              setState(() {
                                shrink = false;
                              });
                            });
                          } else {
                            controller.reverse().then((_) {
                              setState(() {
                                shrink = true;
                              });
                            });
                          }
                        }
                      : null,
                  icon: widget.enableHide
                      ? Icons.keyboard_arrow_down_rounded
                      : null,
                  trailing: widget.trailing,
                ),
                body,
              ],
            ),
    );
  }
}

class FadingPanelLabel extends StatelessWidget {
  const FadingPanelLabel({
    super.key,
    required this.horizontalPadding,
    this.onPressed,
    required this.label,
    this.icon,
    this.controller,
    this.trailing,
    this.tween,
  });

  final EdgeInsets horizontalPadding;

  final void Function()? onPressed;

  final String label;
  final IconData? icon;

  final AnimationController? controller;

  final (IconData, void Function())? trailing;

  final Tween<double>? tween;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    final t = tween ?? Tween<double>(begin: -1.570796, end: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18) + horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: icon == null
                  ? Text(
                      label,
                      style: textStyle,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: textStyle,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: controller == null
                              ? Icon(
                                  icon,
                                  size: 24,
                                  color:
                                      textStyle?.color?.withValues(alpha: 0.9),
                                )
                              : AnimatedBuilder(
                                  animation: controller!.view,
                                  builder: (context, _) {
                                    return Transform.rotate(
                                      angle: t.transform(
                                        Easing.standard
                                            .transform(controller!.value),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 24,
                                        color: textStyle?.color
                                            ?.withValues(alpha: 0.9),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ),
          if (trailing != null)
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: trailing!.$2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      trailing!.$1,
                      size: 24,
                      color: textStyle?.color?.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FadingController extends StatefulWidget {
  const FadingController({
    super.key,
    required this.source,
    required this.childSize,
    required this.child,
  });

  final ResourceSource<dynamic, dynamic> source;

  final Size childSize;
  final Widget child;

  @override
  State<FadingController> createState() => _FadingControllerState();
}

class _FadingControllerState extends State<FadingController>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<bool> subscription;
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, value: 1);
    subscription = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      value: 1,
      autoPlay: false,
      target: !widget.source.progress.inRefreshing &&
              widget.source.backingStorage.isEmpty
          ? 0
          : 1,
      effects: const [
        FadeEffect(
          curve: Easing.standardDecelerate,
          duration: Durations.medium1,
          begin: 0,
          end: 1,
        ),
      ],
      controller: controller,
      child: AnimatedSize(
        alignment: Alignment.topLeft,
        duration: Durations.medium1,
        curve: Easing.standard,
        reverseDuration: Durations.short3,
        child: SizedBox(
          height: !widget.source.progress.inRefreshing &&
                  widget.source.backingStorage.isEmpty
              ? 0
              : widget.childSize.height,
          child: widget.child,
        ),
      ),
    );
  }
}
