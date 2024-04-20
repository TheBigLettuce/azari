// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';
import 'package:gallery/src/widgets/image_view/bottom_bar.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../notifiers/current_content.dart';
import '../app_bar/app_bar.dart';

class WrapImageViewSkeleton extends StatelessWidget {
  final FocusNode mainFocus;
  final ScrollController scrollController;
  final PaletteGenerator? currentPalette;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;

  final Widget child;

  const WrapImageViewSkeleton({
    super.key,
    required this.mainFocus,
    required this.controller,
    required this.scaffoldKey,
    required this.currentPalette,
    required this.bottomSheetController,
    required this.scrollController,
    required this.child,
  });

  static double minPixelsFor(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return minPixels(widgets, viewPadding);
  }

  static double minPixels(ContentWidgets widgets, EdgeInsets viewPadding) =>
      widgets is! Infoable
          ? 80 + viewPadding.bottom
          : (80 + 18 + 8 + viewPadding.bottom);

  @override
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final b = widgets.tryAsAppBarButtonable(context);
    final min = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    final minSize = (minPixels(widgets, viewPadding)) / min.height;

    final surface = Theme.of(context).colorScheme.surface;
    final hsl = HSLColor.fromColor(surface);
    final newHsl = hsl
        .withHue(clampDouble(hsl.hue - 8, 0, 360))
        .withSaturation(clampDouble(hsl.saturation + 0.08, 0, 1))
        .withLightness(clampDouble(hsl.lightness + 0.02, 0, 1));

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Builder(
        builder: (context) {
          return Animate(
            effects: const [
              SlideEffect(
                duration: Duration(milliseconds: 500),
                curve: Easing.emphasizedAccelerate,
                begin: Offset(0, 0),
                end: Offset(0, 1),
              )
            ],
            autoPlay: false,
            target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: surface.withOpacity(0.98)),
                child: IgnorePointer(
                  ignoring: !AppBarVisibilityNotifier.of(context),
                  child: DraggableScrollableSheet(
                    controller: bottomSheetController,
                    expand: false,
                    snap: true,
                    shouldCloseOnMinExtent: false,
                    maxChildSize: 1 -
                        ((kToolbarHeight + viewPadding.top + 8) / min.height),
                    minChildSize: minSize,
                    initialChildSize: minSize,
                    builder: (context, scrollController) {
                      if (widgets is! Infoable) {
                        return const ImageViewBottomAppBar();
                      }

                      return GestureDeadZones(
                        left: true,
                        right: true,
                        child: CustomScrollView(
                          key: ValueKey((viewPadding.bottom, min)),
                          clipBehavior: Clip.antiAlias,
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: newHsl.toColor().withOpacity(0.8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox(
                                    height: 18,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _BottomSheetButton(
                                        bottomSheetController:
                                            bottomSheetController,
                                        minSize: minSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SliverAppBar(
                              automaticallyImplyLeading: false,
                              titleSpacing: 0,
                              toolbarHeight: 80,
                              title: ImageViewBottomAppBar(),
                              pinned: true,
                            ),
                            _AnimatedBottomPadding(
                              bottomSheetController: bottomSheetController,
                              minPixels: minPixels(widgets, viewPadding),
                            ),
                            Builder(
                              builder: (context) {
                                FocusNotifier.of(context);
                                ImageViewInfoTilesRefreshNotifier.of(context);

                                return widgets.tryAsInfoable(context)!;
                              },
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.viewPaddingOf(context).bottom,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: ImageViewAppBar(
          actions: b,
          controller: controller,
        ),
      ),
      body: child,
    );
  }
}

class _AnimatedBottomPadding extends StatefulWidget {
  final DraggableScrollableController bottomSheetController;
  final double minPixels;

  const _AnimatedBottomPadding({
    super.key,
    required this.bottomSheetController,
    required this.minPixels,
  });

  @override
  State<_AnimatedBottomPadding> createState() => _AnimatedBottomPaddingState();
}

class _AnimatedBottomPaddingState extends State<_AnimatedBottomPadding>
    with SingleTickerProviderStateMixin {
  bool shrink = false;
  late final AnimationController controller;

  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  late final tween = Tween<double>(begin: widget.minPixels, end: 0);

  @override
  void initState() {
    bottomSheetController.addListener(listener);
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    controller.addListener(listenerAnimation);

    super.initState();
  }

  @override
  void dispose() {
    bottomSheetController.removeListener(listener);
    controller.removeListener(listenerAnimation);

    controller.dispose();

    super.dispose();
  }

  void listenerAnimation() {
    setState(() {});
  }

  void listener() {
    if (bottomSheetController.pixels > widget.minPixels && shrink == false) {
      setState(() {
        shrink = true;
        controller.forward();
      });
    } else if (bottomSheetController.pixels <= widget.minPixels &&
        shrink == true) {
      setState(() {
        shrink = false;
        controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverIgnorePointer(
      sliver: SliverPadding(
        padding: EdgeInsets.only(
          bottom: tween.transform(Easing.standard.transform(controller.value)),
        ),
      ),
    );
  }
}

class _BottomSheetButton extends StatefulWidget {
  final DraggableScrollableController bottomSheetController;
  final double minSize;

  const _BottomSheetButton({
    super.key,
    required this.bottomSheetController,
    required this.minSize,
  });

  @override
  State<_BottomSheetButton> createState() => __BottomSheetButtonState();
}

class __BottomSheetButtonState extends State<_BottomSheetButton> {
  bool facingUpward = true;

  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  @override
  void initState() {
    super.initState();

    bottomSheetController.addListener(listener);
  }

  @override
  void dispose() {
    bottomSheetController.removeListener(listener);

    super.dispose();
  }

  void listener() {
    if (bottomSheetController.size > widget.minSize && facingUpward == true) {
      setState(() {
        facingUpward = false;
      });
    } else if (bottomSheetController.size <= widget.minSize &&
        facingUpward == false) {
      setState(() {
        facingUpward = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (bottomSheetController.size > widget.minSize) {
          bottomSheetController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Easing.emphasizedAccelerate,
          );
        } else {
          bottomSheetController.animateTo(
            1,
            duration: const Duration(milliseconds: 200),
            curve: Easing.emphasizedDecelerate,
          );
        }
      },
      icon: Animate(
        autoPlay: false,
        target: facingUpward ? 0 : 1,
        effects: [
          const FadeEffect(
            begin: 1,
            end: 0,
            curve: Easing.standard,
          ),
          SwapEffect(
            builder: (_, __) {
              return const Icon(
                size: 18,
                Icons.keyboard_arrow_down_rounded,
              ).animate().fadeIn(curve: Easing.standard);
            },
          )
        ],
        child: const Icon(
          size: 18,
          Icons.keyboard_arrow_up_rounded,
        ),
      ),
    );
  }
}
