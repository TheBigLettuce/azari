// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../gesture_dead_zones.dart';

class ImageViewBody extends StatelessWidget {
  final void Function(int idx) onPageChanged;
  final PageController pageController;
  final void Function() onTap;
  final PhotoViewGalleryPageOptions Function(BuildContext, int) builder;
  final Widget? notes;
  final void Function() onLongPress;
  final int itemCount;
  final BoxDecoration decoration;
  final Widget Function(BuildContext, ImageChunkEvent?, int)? loadingBuilder;

  final bool switchPageOnTapEdges;

  const ImageViewBody({
    super.key,
    required this.onPageChanged,
    required this.pageController,
    required this.builder,
    required this.notes,
    required this.loadingBuilder,
    required this.decoration,
    required this.itemCount,
    required this.onLongPress,
    required this.onTap,
    required this.switchPageOnTapEdges,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GestureDeadZones(
        left: true,
        right: true,
        onPressedRight: switchPageOnTapEdges
            ? () {
                pageController.nextPage(
                    duration: 200.ms, curve: Easing.standard);
              }
            : null,
        onPressedLeft: switchPageOnTapEdges
            ? () {
                pageController.previousPage(
                    duration: 200.ms, curve: Easing.standard);
              }
            : null,
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onTap,
          child: PhotoViewGallery.builder(
            loadingBuilder: loadingBuilder,
            enableRotation: true,
            backgroundDecoration: decoration,
            onPageChanged: onPageChanged,
            pageController: pageController,
            itemCount: itemCount,
            builder: builder,
          ),
        ),
      ),
      if (notes != null) notes!
    ]);
  }
}
