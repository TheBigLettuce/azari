// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:flutter/material.dart";

class ImageViewFab extends StatefulWidget {
  const ImageViewFab({
    super.key,
    required this.openBottomSheet,
  });

  final Future<void> Function(BuildContext context) openBottomSheet;

  @override
  State<ImageViewFab> createState() => _ImageViewFabState();
}

class _ImageViewFabState extends State<ImageViewFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  bool iconClosedMenu = true;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Durations.medium1,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      elevation: 0,
      heroTag: null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor:
          theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
      foregroundColor:
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.95),
      onPressed: () {
        AppBarVisibilityNotifier.maybeToggleOf(context, true);

        controller.forward();
        widget.openBottomSheet(context).whenComplete(() {
          controller.reverse();
        });
      },
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: controller.view,
      ),
    );
  }
}

// class _IgnoringPointer extends StatefulWidget {
//   const _IgnoringPointer({
//     // super.key,
//     required this.widgets,
//     required this.bottomSheetController,
//     required this.viewPadding,
//     required this.child,
//   });

//   final ContentWidgets widgets;
//   final DraggableScrollableController bottomSheetController;
//   final EdgeInsets viewPadding;

//   final Widget child;

//   @override
//   State<_IgnoringPointer> createState() => __IgnoringPointerState();
// }

// class __IgnoringPointerState extends State<_IgnoringPointer> {
//   DraggableScrollableController get bottomSheetController =>
//       widget.bottomSheetController;

//   bool ignorePointer = true;

//   @override
//   void initState() {
//     super.initState();

//     bottomSheetController.addListener(listener);
//   }

//   @override
//   void dispose() {
//     bottomSheetController.removeListener(listener);

//     super.dispose();
//   }

//   void listener() {
//     final newIgnorePointer = widget.bottomSheetController.size <= 0;

//     if (newIgnorePointer != ignorePointer) {
//       ignorePointer = newIgnorePointer;

//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SliverIgnorePointer(
//       ignoring: ignorePointer,
//       sliver: widget.child,
//     );
//   }
// }
