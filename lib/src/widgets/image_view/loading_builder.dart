// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/notifiers/loading_progress.dart';
import 'package:logging/logging.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../interfaces/cell/cell.dart';

mixin ImageViewLoadingBuilderMixin<T extends Cell> on State<ImageView<T>> {
  Widget loadingBuilder(
    BuildContext context,
    ImageChunkEvent? event,
    int idx,
    int currentPage,
    GlobalKey<WrapImageViewNotifiersState> key,
    PaletteGenerator? currentPalette,
  ) {
    final expectedBytes = event?.expectedTotalBytes;
    final loadedBytes = event?.cumulativeBytesLoaded;
    final value = loadedBytes != null && expectedBytes != null
        ? loadedBytes / expectedBytes
        : null;

    final loadingProgress = LoadingProgressNotifier.of(context);

    if (idx == currentPage) {
      if (event == null) {
        if (loadingProgress != null) {
          key.currentState?.setLoadingProgress(null);
        }
      } else if (value != loadingProgress) {
        key.currentState?.setLoadingProgress(value);
      }
    }

    try {
      final t = widget.getCell(idx).getCellData(false, context: context).thumb;
      if (t == null) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
              ColorTween(
                begin: Theme.of(context).colorScheme.background,
                end: currentPalette?.mutedColor?.color
                    .harmonizeWith(Theme.of(context).colorScheme.primary),
              ).lerp(value ?? 0)!,
              ColorTween(
                begin:
                    Theme.of(context).colorScheme.background.withOpacity(0.7),
                end: currentPalette?.mutedColor?.color
                    .harmonizeWith(Theme.of(context).colorScheme.primary)
                    .withOpacity(0.7),
              ).lerp(value ?? 0)!,
              ColorTween(
                begin:
                    Theme.of(context).colorScheme.background.withOpacity(0.5),
                end: currentPalette?.mutedColor?.color
                    .harmonizeWith(Theme.of(context).colorScheme.primary)
                    .withOpacity(0.5),
              ).lerp(value ?? 0)!,
              ColorTween(
                begin:
                    Theme.of(context).colorScheme.background.withOpacity(0.3),
                end: currentPalette?.mutedColor?.color
                    .harmonizeWith(Theme.of(context).colorScheme.primary)
                    .withOpacity(0.3),
              ).lerp(value ?? 0)!,
            ])),
        child: _Image(
            t: t,
            reset: () {
              key.currentState?.setLoadingProgress(1.0);
            }),
      );
    } catch (e, stackTrace) {
      log("_loadingBuilder",
          error: e, stackTrace: stackTrace, level: Level.WARNING.value);

      return const SizedBox.shrink();
    }
  }
}

class _Image extends StatefulWidget {
  final ImageProvider t;
  final void Function() reset;

  const _Image({required this.t, required this.reset});

  @override
  State<_Image> createState() => __ImageState();
}

class __ImageState extends State<_Image> {
  @override
  void dispose() {
    widget.reset();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: widget.t,
      filterQuality: FilterQuality.high,
      fit: BoxFit.contain,
    );
  }
}
