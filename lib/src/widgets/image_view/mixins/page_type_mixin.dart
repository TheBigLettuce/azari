// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/widgets/loading_error_widget.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:photo_view/photo_view.dart";
import "package:photo_view/photo_view_gallery.dart";

mixin ImageViewPageTypeMixin on State<ImageView> {
  int refreshTries = 0;

  (Contentable, int)? _currentCell;
  // ignore: use_late_for_private_fields_and_variables
  (Contentable, int)? _previousCell;
  (Contentable, int)? _nextCell;

  (Contentable, int) currentCell() => _currentCell!;

  Contentable drawCell(int i, [bool currentCellOnly = false]) {
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
    _currentCell = (widget.getContent(i)!, i);

    if (i != 0 && !i.isNegative) {
      final c2 = widget.getContent(i - 1);

      if (c2 != null) {
        _previousCell = (c2, i - 1);

        final content = c2;
        if (widget.preloadNextPictures && content is NetImage) {
          WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
            precacheImage(content.provider, context);
            final thumb = content.widgets.tryAsThumbnailable(context);
            if (thumb != null) {
              precacheImage(thumb, context);
            }
          });
        }
      }
    }

    if (maxCells != i + 1) {
      final c3 = widget.getContent(i + 1);

      if (c3 != null) {
        _nextCell = (c3, i + 1);

        final content = c3;
        if (widget.preloadNextPictures && content is NetImage) {
          WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
            precacheImage(content.provider, context);
            final thumb = content.widgets.tryAsThumbnailable(context);
            if (thumb != null) {
              precacheImage(thumb, context);
            }
          });
        }
      }
    }
  }

  PhotoViewGalleryPageOptions galleryBuilder(BuildContext context, int i) {
    final cell = drawCell(i);
    final content = cell;
    final key = cell.widgets.uniqueKey();

    return switch (content) {
      AndroidImage() =>
        _makeAndroidImage(context, key, i, content.size, content.uri, false),
      AndroidGif() =>
        _makeAndroidImage(context, key, i, content.size, content.uri, true),
      NetGif() => _makeNetImage(key, content.provider),
      NetImage() => _makeNetImage(key, content.provider),
      AndroidVideo() => _makeVideo(
          context,
          key,
          content.uri,
          cell.widgets.tryAsThumbnailable(context),
          true,
        ),
      NetVideo() => _makeVideo(
          context,
          key,
          content.uri,
          cell.widgets.tryAsThumbnailable(context),
          false,
        ),
      EmptyContent() =>
        PhotoViewGalleryPageOptions.customChild(child: const SizedBox.shrink())
    };
  }

  PhotoViewGalleryPageOptions _makeVideo(
    BuildContext context,
    Key key,
    String uri,
    ImageProvider? networkThumb,
    bool local,
  ) =>
      PhotoViewGalleryPageOptions.customChild(
        disableGestures: true,
        tightMode: true,
        child: PhotoGalleryPageVideo(
          key: key,
          url: uri,
          networkThumb: networkThumb,
          localVideo: local,
          db: DatabaseConnectionNotifier.of(context).videoSettings,
        ),
      );

  PhotoViewGalleryPageOptions _makeNetImage(Key key, ImageProvider provider) {
    final options = PhotoViewGalleryPageOptions(
      key: ValueKey((key, refreshTries)),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 1.8,
      initialScale: PhotoViewComputedScale.contained,
      filterQuality: FilterQuality.high,
      imageProvider: provider,
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
    BuildContext context,
    Key key,
    int idx,
    Size size,
    String uri,
    bool isGif,
  ) =>
      PhotoViewGalleryPageOptions.customChild(
        gestureDetectorBehavior: HitTestBehavior.translucent,
        disableGestures: true,
        child: KeyedSubtree(
          key: ValueKey((key, idx)),
          child: Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: AndroidView(
                viewType: "imageview",
                hitTestBehavior: PlatformViewHitTestBehavior.translucent,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                creationParams: {
                  "uri": uri,
                  if (isGif) "gif": "",
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          ),
        ),
      );
}
