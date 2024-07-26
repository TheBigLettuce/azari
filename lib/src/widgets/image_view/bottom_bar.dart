// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/widgets/focus_notifier.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart";

class ImageViewBottomAppBar extends StatefulWidget {
  const ImageViewBottomAppBar({
    super.key,
    required this.addInfoFab,
    required this.bottomSheetController,
    required this.viewPadding,
  });

  final bool addInfoFab;
  final DraggableScrollableController bottomSheetController;
  final EdgeInsets viewPadding;

  @override
  State<ImageViewBottomAppBar> createState() => _ImageViewBottomAppBarState();
}

class _ImageViewBottomAppBarState extends State<ImageViewBottomAppBar>
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
    final widgets = CurrentContentNotifier.of(context).widgets;
    final actions = widgets.tryAsActionable(context);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.passthrough,
      children: [
        const SizedBox(
          height: 80,
          child: AbsorbPointer(
            child: SizedBox.shrink(),
          ),
        ),
        if (widget.addInfoFab)
          Animate(
            value: 0,
            autoPlay: false,
            controller: controller,
            effects: const [
              FadeEffect(
                curve: Easing.standard,
                duration: Durations.long1,
                begin: 0,
                end: 1,
              ),
            ],
            child: ImageViewSlidingInfoDrawer(
              widgets: widgets,
              bottomSheetController: widget.bottomSheetController,
              viewPadding: widget.viewPadding,
            ),
          ),
        BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  key: widgets.uniqueKey(),
                  spacing: 4,
                  children: actions
                      .map(
                        (e) => WrapGridActionButton(
                          e.icon,
                          () {
                            e.onPress(CurrentContentNotifier.of(context));
                          },
                          play: e.play,
                          color: e.color,
                          onLongPress: null,
                          animation: e.animation,
                          animate: e.animate,
                          whenSingleContext: null,
                          watch: e.watch,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (widget.addInfoFab)
                ImageViewFab(
                  visibilityController: controller,
                  widgets: widgets,
                  viewPadding: widget.viewPadding,
                  bottomSheetController: widget.bottomSheetController,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ImageViewFab extends StatefulWidget {
  const ImageViewFab({
    // super.key,
    required this.widgets,
    required this.bottomSheetController,
    required this.viewPadding,
    required this.visibilityController,
  });

  final ContentWidgets widgets;
  final DraggableScrollableController bottomSheetController;
  final EdgeInsets viewPadding;
  final AnimationController visibilityController;

  @override
  State<ImageViewFab> createState() => _ImageViewFabState();
}

class _ImageViewFabState extends State<ImageViewFab>
    with SingleTickerProviderStateMixin {
  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  late final AnimationController controller;

  bool iconClosedMenu = true;

  // double minSize = 0;

  @override
  void initState() {
    super.initState();

    bottomSheetController.addListener(listener);
    controller = AnimationController(vsync: this, duration: Durations.medium1);
  }

  @override
  void dispose() {
    bottomSheetController.removeListener(listener);
    controller.dispose();

    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   final min = MediaQuery.sizeOf(context);

  //   minSize =
  //       (WrapImageViewSkeleton.minPixels(widget.widgets, widget.viewPadding)) /
  //           min.height;
  // }

  void listener() {
    final newIcon = !(widget.bottomSheetController.size > 0);

    if (newIcon != iconClosedMenu) {
      iconClosedMenu = newIcon;

      if (iconClosedMenu) {
        controller.reverse();
        widget.visibilityController.reverse();
      } else {
        controller.forward();
        widget.visibilityController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: theme.colorScheme.surfaceContainerHigh.withOpacity(0.9),
      foregroundColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.95),
      onPressed: () {
        if (widget.bottomSheetController.size > 0) {
          widget.bottomSheetController.animateTo(
            0,
            duration: Durations.medium2,
            curve: Easing.standard,
          );
        } else {
          widget.bottomSheetController.animateTo(
            1,
            duration: Durations.medium2,
            curve: Easing.standard,
          );
        }
      },
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: controller.view,
      ),
    );
  }
}

class _IgnoringPointer extends StatefulWidget {
  const _IgnoringPointer(
      {super.key,
      required this.widgets,
      required this.bottomSheetController,
      required this.viewPadding,
      required this.child});

  final ContentWidgets widgets;
  final DraggableScrollableController bottomSheetController;
  final EdgeInsets viewPadding;

  final Widget child;

  @override
  State<_IgnoringPointer> createState() => __IgnoringPointerState();
}

class __IgnoringPointerState extends State<_IgnoringPointer> {
  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  // double minSize = 0;

  bool ignorePointer = true;

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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   final min = MediaQuery.sizeOf(context);

  //   minSize =
  //       (WrapImageViewSkeleton.minPixels(widget.widgets, widget.viewPadding)) /
  //           min.height;
  // }

  void listener() {
    final newIgnorePointer = widget.bottomSheetController.size <= 0;

    if (newIgnorePointer != ignorePointer) {
      ignorePointer = newIgnorePointer;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverIgnorePointer(
      ignoring: ignorePointer,
      sliver: widget.child,
    );
  }
}

class ImageViewSlidingInfoDrawer extends StatefulWidget {
  const ImageViewSlidingInfoDrawer({
    // super.key,
    required this.widgets,
    required this.bottomSheetController,
    required this.viewPadding,
    // required this.min,
  });

  final ContentWidgets widgets;
  final DraggableScrollableController bottomSheetController;
  final EdgeInsets viewPadding;

  @override
  State<ImageViewSlidingInfoDrawer> createState() =>
      _ImageViewSlidingInfoDrawerState();
}

class _ImageViewSlidingInfoDrawerState
    extends State<ImageViewSlidingInfoDrawer> {
  ContentWidgets get widgets => widget.widgets;
  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  @override
  Widget build(BuildContext context) {
    final min = MediaQuery.sizeOf(context);

    // final minSize =
    //     (WrapImageViewSkeleton.minPixels(widgets, widget.viewPadding)) /
    //         min.height;

    return DraggableScrollableSheet(
      controller: bottomSheetController,
      expand: false,
      snap: true,
      shouldCloseOnMinExtent: false,
      maxChildSize:
          1 - ((kToolbarHeight + widget.viewPadding.top + 8) / min.height),
      minChildSize: 0,
      initialChildSize: 0,
      builder: (context, scrollController) {
        return GestureDeadZones(
          left: true,
          right: true,
          child: CustomScrollView(
            key: ValueKey((widget.viewPadding.bottom, min)),
            controller: scrollController,
            slivers: [
              Builder(
                builder: (context) {
                  FocusNotifier.of(context);
                  ImageViewInfoTilesRefreshNotifier.of(
                    context,
                  );

                  return _IgnoringPointer(
                    bottomSheetController: bottomSheetController,
                    viewPadding: widget.viewPadding,
                    widgets: widget.widgets,
                    child: widgets.tryAsInfoable(context)!,
                  );
                },
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 80,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedBottomPadding extends StatefulWidget {
  const _AnimatedBottomPadding({
    required this.bottomSheetController,
    required this.minPixels,
  });
  final DraggableScrollableController bottomSheetController;
  final double minPixels;

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
