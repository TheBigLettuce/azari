// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key, required this.image});
  final ImageProvider<Object> image;

  @override
  Widget build(BuildContext context) {
    return BackgroundImageBase(
      image: image,
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height * 0.3 +
          kToolbarHeight +
          MediaQuery.viewPaddingOf(context).top,
    );
  }
}

class BackgroundImageBase extends StatelessWidget {
  const BackgroundImageBase({
    super.key,
    this.height,
    required this.image,
    this.width,
    this.gradient,
    this.child,
  });
  final ImageProvider<Object> image;
  final Widget? child;
  final double? width;
  final double? height;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      width: width,
      height: height,
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: gradient ??
              [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.background.withOpacity(0.8),
                Theme.of(context).colorScheme.background.withOpacity(0.6),
                Theme.of(context).colorScheme.background.withOpacity(0.4),
              ],
        ),
      ),
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          opacity: 0.4,
          filterQuality: FilterQuality.high,
          alignment: Alignment.topCenter,
          colorFilter:
              const ColorFilter.mode(Colors.black87, BlendMode.softLight),
          image: image,
        ),
      ),
      child: child,
    );
  }
}
