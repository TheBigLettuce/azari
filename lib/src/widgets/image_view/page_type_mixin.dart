// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/interfaces/contentable.dart';
import 'package:gallery/src/widgets/choose_kaomoji.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/loading_error_widget.dart';
import 'package:gallery/src/widgets/notifiers/reload_image.dart';
import 'package:gallery/src/widgets/video/photo_gallery_page_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../interfaces/cell.dart';
import '../../pages/image_view.dart';

mixin ImageViewPageTypeMixin<T extends Cell> on State<ImageView<T>> {
  ImageProvider? fakeProvider;

  PhotoViewGalleryPageOptions galleryBuilder(BuildContext context, int indx) {
    final fileContent = widget.predefinedIndexes != null
        ? widget.getCell(widget.predefinedIndexes![indx]).fileDisplay()
        : widget.getCell(indx).fileDisplay();

    return switch (fileContent) {
      AndroidImage() =>
        _makeAndroidImage(context, fileContent.size, fileContent.uri, false),
      AndroidGif() =>
        _makeAndroidImage(context, fileContent.size, fileContent.uri, true),
      NetGif() => _makeNetImage(fileContent.provider),
      NetImage() => _makeNetImage(fileContent.provider),
      AndroidVideo() => _makeVideo(context, fileContent.uri, true),
      NetVideo() => _makeVideo(context, fileContent.uri, false),
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
