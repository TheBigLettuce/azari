// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;
import "dart:ui";

import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart" as gallery;
import "package:azari/src/platform/gallery_api.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:transparent_image/transparent_image.dart";

final _thumbLoadingStatus = <int, Future<ThumbId>>{};

ListTile addInfoTile({
  required String title,
  required String? subtitle,
  void Function()? onPressed,
  Widget? trailing,
}) =>
    ListTile(
      title: Center(
        child: Text(title),
      ),
      trailing: trailing,
      onTap: onPressed,
      subtitle: subtitle != null
          ? Center(
              child: Text(subtitle),
            )
          : null,
    );

class GalleryThumbnailProvider extends ImageProvider<GalleryThumbnailProvider> {
  const GalleryThumbnailProvider(
    this.id,
    this.tryPinned,
    // this.pinnedThumbnails,
    this.thumbnails,
  );

  final int id;
  final bool tryPinned;

  // final PinnedThumbnailService pinnedThumbnails;
  final ThumbnailService thumbnails;

  @override
  Future<GalleryThumbnailProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    GalleryThumbnailProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
    );
  }

  Future<Codec> _loadAsync(
    GalleryThumbnailProvider key,
    ImageDecoderCallback decode,
  ) async {
    Future<io.File?> setFile() async {
      final future = _thumbLoadingStatus[id];
      if (future != null) {
        final cachedThumb = await future;

        if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
          return null;
        }

        return io.File(cachedThumb.path);
      }

      final thumb = thumbnails.get(id);
      if (thumb != null) {
        if (thumb.path.isEmpty || thumb.differenceHash == 0) {
          return null;
        }

        return io.File(thumb.path);
      }

      // if (tryPinned) {
      //   final thumb = pinnedThumbnails.get(id);
      //   if (thumb != null &&
      //       thumb.differenceHash != 0 &&
      //       thumb.path.isNotEmpty) {
      //     return io.File(thumb.path);
      //   }
      // }

      final future2 = _thumbLoadingStatus[id];
      if (future2 != null) {
        final cachedThumb = await future2;

        if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
          return null;
        }

        return io.File(cachedThumb.path);
      }

      _thumbLoadingStatus[id] =
          gallery.GalleryApi().thumbs.get(id).whenComplete(() {
        _thumbLoadingStatus.remove(id);
      });

      final cachedThumb = await _thumbLoadingStatus[id]!;
      thumbnails.addAll([cachedThumb]);

      if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
        return null;
      }

      return io.File(cachedThumb.path);
    }

    final file = await setFile();

    if (file == null) {
      return decode(await ImmutableBuffer.fromUint8List(kTransparentImage));
    }

    // copied from Flutter source of FileImage

    final int lengthInBytes = await file.length();
    if (lengthInBytes == 0) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError("$file is empty and cannot be loaded as an image.");
    }
    return (file.runtimeType == io.File)
        ? decode(await ImmutableBuffer.fromFilePath(file.path))
        : decode(await ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is GalleryThumbnailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
