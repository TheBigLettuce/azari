// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/notifiers/loading_progress.dart";

mixin ImageViewLoadingBuilderMixin on State<ImageView> {
  Widget loadingBuilder(
    BuildContext context,
    ImageChunkEvent? event,
    int idx,
    int currentPage,
    GlobalKey<WrapImageViewNotifiersState> key,
    Contentable Function(int) drawCell,
  ) {
    final t = drawCell(idx).widgets.tryAsThumbnailable();
    if (t == null) {
      return const SizedBox.shrink();
    }

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

    return _Image(
      t: t,
      reset: () {
        key.currentState?.setLoadingProgress(1);
      },
    );
  }
}

class _Image extends StatefulWidget {
  const _Image({required this.t, required this.reset});
  final ImageProvider t;
  final void Function() reset;

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
