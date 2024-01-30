// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/widgets/loading_error_widget.dart';
import 'package:gallery/src/widgets/notifiers/reload_image.dart';
import 'package:gallery/src/widgets/video/photo_gallery_page_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../interfaces/cell/cell.dart';
import '../../pages/image_view.dart';

mixin ImageViewPageTypeMixin<T extends Cell> on State<ImageView<T>> {
  ImageProvider? fakeProvider;

  (T, int)? _currentCell;
  (T, int)? _previousCell;
  (T, int)? _nextCell;

  T drawCell(int i, [bool currentCellOnly = false]) {
    if (currentCellOnly) {
      return _currentCell!.$1;
    }

    if (_currentCell != null && _currentCell!.$2 == i) {
      return _currentCell!.$1;
    } else if (_nextCell != null && _nextCell!.$2 == i) {
      return _nextCell!.$1;
    } else {
      return _previousCell!.$1;
    }
  }

  void loadCells(int i, int maxCells) {
    _currentCell = (widget.getCell(i)!, i);

    if (i != 0 && !i.isNegative) {
      final c2 = widget.getCell(i - 1);

      if (c2 != null) {
        _previousCell = (c2, i - 1);
      }
    }

    if (maxCells != i + 1) {
      final c3 = widget.getCell(i + 1);

      if (c3 != null) {
        _nextCell = (c3, i + 1);
      }
    }
  }

  PhotoViewGalleryPageOptions galleryBuilder(BuildContext context, int i) {
    final content = drawCell(i).content();

    // final fileContent = widget.predefinedIndexes != null
    //     ? widget.getCell(widget.predefinedIndexes![indx]).fileDisplay()
    //     : widget.getCell(indx).fileDisplay();

    return switch (content) {
      AndroidImage() =>
        _makeAndroidImage(context, content.size, content.uri, false),
      AndroidGif() =>
        _makeAndroidImage(context, content.size, content.uri, true),
      NetGif() => _makeNetImage(content.provider),
      NetImage() => _makeNetImage(content.provider),
      AndroidVideo() => _makeVideo(context, content.uri, true),
      NetVideo() => _makeVideo(context, content.uri, false),
      EmptyContent() =>
        PhotoViewGalleryPageOptions.customChild(child: const SizedBox.shrink())
    };
  }

  PhotoViewGalleryPageOptions _makeVideo(
          BuildContext context, String uri, bool local) =>
      PhotoViewGalleryPageOptions.customChild(
          disableGestures: true,
          tightMode: true,
          child: !Platform.isAndroid
              ? const Center(child: Icon(Icons.error_outline))
              : PhotoGalleryPageVideo(
                  url: uri,
                  localVideo: local,
                  // loadingColor: ColorTween(
                  //             begin: previousPallete?.dominantColor?.color
                  //                 .harmonizeWith(
                  //                     Theme.of(context).colorScheme.primary),
                  //             end: currentPalette?.dominantColor?.color
                  //                 .harmonizeWith(
                  //                     Theme.of(context).colorScheme.primary))
                  //         .transform(_animationController.value) ??
                  //     Theme.of(context).colorScheme.background,
                  // backgroundColor: ColorTween(
                  //             begin: previousPallete?.mutedColor?.color
                  //                 .harmonizeWith(
                  //                     Theme.of(context).colorScheme.primary)
                  //                 .withOpacity(0.7),
                  //             end: currentPalette?.mutedColor?.color
                  //                 .harmonizeWith(
                  //                     Theme.of(context).colorScheme.primary)
                  //                 .withOpacity(0.7))
                  //         .transform(_animationController.value) ??
                  //     Theme.of(context).colorScheme.primary,
                ));

  PhotoViewGalleryPageOptions _makeNetImage(ImageProvider provider) {
    final options = PhotoViewGalleryPageOptions(
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 1.8,
      initialScale: PhotoViewComputedScale.contained,
      filterQuality: FilterQuality.high,
      imageProvider: fakeProvider ?? provider,
      errorBuilder: (context, error, stackTrace) {
        return LoadingErrorWidget(
          error: error.toString(),
          short: false,
          refresh: () {
            ReloadImageNotifier.of(context);
          },
        );
      },
    );

    return options;
  }

  PhotoViewGalleryPageOptions _makeAndroidImage(
          BuildContext context, Size size, String uri, bool isGif) =>
      PhotoViewGalleryPageOptions.customChild(
          gestureDetectorBehavior: HitTestBehavior.translucent,
          disableGestures: true,
          filterQuality: FilterQuality.high,
          child: Center(
            child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: AspectRatio(
                  aspectRatio: MediaQuery.of(context).size.aspectRatio,
                  child: InteractiveViewer(
                    trackpadScrollCausesScale: true,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: size.aspectRatio == 0
                            ? MediaQuery.of(context).size.aspectRatio
                            : size.aspectRatio,
                        child: fakeProvider != null
                            ? Image(image: fakeProvider!)
                            : AndroidView(
                                viewType: "imageview",
                                hitTestBehavior:
                                    PlatformViewHitTestBehavior.transparent,
                                creationParams: {
                                  "uri": uri,
                                  if (isGif) "gif": "",
                                },
                                creationParamsCodec:
                                    const StandardMessageCodec(),
                              ),
                      ),
                    ),
                  ),
                )),
          ));
}
