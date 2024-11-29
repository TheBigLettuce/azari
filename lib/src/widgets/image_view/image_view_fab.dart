// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:flutter/material.dart";

class ImageViewFab extends StatefulWidget {
  const ImageViewFab({
    super.key,
    required this.widgets,
    required this.bottomSheetController,
    required this.viewPadding,
    required this.visibilityController,
    required this.wrapNotifiers,
    required this.pauseVideoState,
  });

  final ContentWidgets widgets;
  final DraggableScrollableController bottomSheetController;
  final EdgeInsets viewPadding;
  final AnimationController visibilityController;
  final NotifierWrapper? wrapNotifiers;
  final PauseVideoState pauseVideoState;

  @override
  State<ImageViewFab> createState() => _ImageViewFabState();
}

class _ImageViewFabState extends State<ImageViewFab>
    with SingleTickerProviderStateMixin {
  DraggableScrollableController get bottomSheetController =>
      widget.bottomSheetController;

  late final AnimationController controller;

  bool iconClosedMenu = true;

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
    final cellStream = CurrentContentNotifier.streamOf(context);

    return FloatingActionButton(
      elevation: 0,
      heroTag: null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor:
          theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
      foregroundColor:
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.95),
      onPressed: () {
        AppBarVisibilityNotifier.toggleOf(context, true);

        showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) {
            final child = ExitOnPressRoute(
              exit: () {
                Navigator.of(sheetContext)
                  ..pop()
                  ..pop();
              },
              child: PauseVideoNotifierHolder(
                state: widget.pauseVideoState,
                child: ImageTagsNotifier(
                  tags: ImageTagsNotifier.of(context),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(sheetContext).width,
                      child: _CellContent(
                        firstContent: CurrentContentNotifier.of(context),
                        stream: cellStream,
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (widget.wrapNotifiers != null) {
              return widget.wrapNotifiers!(child);
            }

            return child;
          },
        );
      },
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: controller.view,
      ),
    );
  }
}

class _CellContent extends StatefulWidget {
  const _CellContent({
    // super.key,
    required this.stream,
    required this.firstContent,
  });

  final Contentable firstContent;
  final Stream<Contentable> stream;

  @override
  State<_CellContent> createState() => __CellContentState();
}

class __CellContentState extends State<_CellContent> {
  late final StreamSubscription<Contentable> events;

  late Contentable content;

  @override
  void initState() {
    super.initState();

    content = widget.firstContent;

    events = widget.stream.listen((newContent) {
      setState(() {
        content = newContent;
      });
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return content.widgets.tryAsInfoable(context) ?? const SizedBox.shrink();
  }
}

class _IgnoringPointer extends StatefulWidget {
  const _IgnoringPointer({
    // super.key,
    required this.widgets,
    required this.bottomSheetController,
    required this.viewPadding,
    required this.child,
  });

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
