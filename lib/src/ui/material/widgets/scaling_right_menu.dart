// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class ScalingRightMenu extends StatefulWidget {
  const ScalingRightMenu({
    super.key,
    required this.menuContent,
    required this.child,
  });

  final Widget menuContent;
  final Widget child;

  static ScalingRightMenuState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ScalingRightMenuState>();
  }

  @override
  State<ScalingRightMenu> createState() => ScalingRightMenuState();
}

class ScalingRightMenuState extends State<ScalingRightMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  Key _dismissableKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      value: 1,
      vsync: this,
      duration: Durations.medium1,
      reverseDuration: Durations.medium4,
    );
  }

  bool get isOpenned => controller.value != 1;

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void open() {
    controller.reverse();
  }

  void close() {
    controller.forward();
  }

  final Tween<double> _tweenOpacity = Tween(begin: 0.75, end: 1);
  final Tween<double> _tweenShadow = Tween(begin: 0.15, end: 0);
  final Tween<double> _tweenBorderRadius = Tween(begin: 25, end: 0);
  final Tween<double> _tweenScale = Tween(begin: 0.90, end: 1);

  final Tween<Offset> _tweenSlideMenu = Tween(
    begin: Offset.zero,
    end: const Offset(1, -0),
  );

  final Tween<Offset> _tweenPaddingRight = Tween(
    begin: const Offset(-280, 40),
    end: Offset.zero,
  );

  final CurveTween _tweenEasingForward = CurveTween(
    curve: Easing.emphasizedDecelerate,
  );
  final CurveTween _tweenEasingBackward = CurveTween(
    curve: Easing.emphasizedAccelerate,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: controller.view,
          builder: (context, child) => IgnorePointer(
            ignoring: controller.value != 1,
            child: Opacity(
              opacity: _tweenOpacity.evaluate(controller.view),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Transform.translate(
                  offset: controller.view
                      .drive(switch (controller.status) {
                        AnimationStatus.dismissed ||
                        AnimationStatus.completed ||
                        AnimationStatus.forward => _tweenEasingForward,
                        AnimationStatus.reverse => _tweenEasingBackward,
                      })
                      .drive(_tweenPaddingRight)
                      .value,
                  child: Transform.scale(
                    scale: _tweenScale.evaluate(controller.view),
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            _tweenBorderRadius.evaluate(controller.view),
                          ),
                        ),
                        color: theme.colorScheme.shadow.withValues(
                          alpha: _tweenShadow.evaluate(controller.view),
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Dismissible(
          key: _dismissableKey,
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) {
            if (controller.value > 0.6 && !controller.isAnimating) {
              controller.forward().then((_) {
                if (context.mounted) {
                  setState(() {
                    _dismissableKey = UniqueKey();
                  });
                }
              });

              return Future.value(true);
            }

            return Future.value(false);
          },
          onUpdate: (details) {
            controller.value = details.progress;
          },
          child: AnimatedBuilder(
            animation: controller.view,
            builder: (context, child) => Opacity(
              opacity: 1 - controller.value,
              child: SlideTransition(
                position: controller.view
                    .drive(switch (controller.status) {
                      AnimationStatus.dismissed ||
                      AnimationStatus.completed ||
                      AnimationStatus.forward => _tweenEasingForward,
                      AnimationStatus.reverse => _tweenEasingBackward,
                    })
                    .drive(_tweenSlideMenu),
                child: controller.value != 1 ? child : const SizedBox.shrink(),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Builder(
                builder: (context) {
                  final viewPadding = MediaQuery.viewPaddingOf(context);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: close,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 320,
                              minHeight: double.infinity,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(25),
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 25,
                                      ) +
                                      EdgeInsets.only(
                                        top: 25,
                                        bottom: viewPadding.bottom,
                                      ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                    child: widget.menuContent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
