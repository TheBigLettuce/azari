// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/db/schemas/gallery/pinned_thumbnail.dart";
import "package:gallery/src/db/schemas/gallery/thumbnail.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:transparent_image/transparent_image.dart";

final _thumbLoadingStatus = <int, Future<ThumbId>>{};

ListTile addInfoTile({
  required String title,
  required String? subtitle,
  void Function()? onPressed,
  Widget? trailing,
}) =>
    ListTile(
      // textColor: colors.foregroundColor,
      title: Text(title),
      trailing: trailing,
      onTap: onPressed,
      subtitle: subtitle != null ? Text(subtitle) : null,
    );

class SystemGalleryThumbnailProvider
    extends ImageProvider<SystemGalleryThumbnailProvider> {
  const SystemGalleryThumbnailProvider(this.id, this.tryPinned);

  final int id;
  final bool tryPinned;

  @override
  Future<SystemGalleryThumbnailProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SystemGalleryThumbnailProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
    );
  }

  Future<Codec> _loadAsync(
    SystemGalleryThumbnailProvider key,
    ImageDecoderCallback decode,
  ) async {
    Future<File?> setFile() async {
      final future = _thumbLoadingStatus[id];
      if (future != null) {
        final cachedThumb = await future;

        if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
          return null;
        }

        return File(cachedThumb.path);
      }

      final thumb = Dbs.g.thumbnail!.thumbnails.getSync(id);
      if (thumb != null) {
        if (thumb.path.isEmpty || thumb.differenceHash == 0) {
          return null;
        }

        return File(thumb.path);
      }

      if (tryPinned) {
        final thumb = Dbs.g.thumbnail!.pinnedThumbnails.getSync(id);
        if (thumb != null &&
            thumb.differenceHash != 0 &&
            thumb.path.isNotEmpty) {
          return File(thumb.path);
        }
      }

      final future2 = _thumbLoadingStatus[id];
      if (future2 != null) {
        final cachedThumb = await future2;

        if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
          return null;
        }

        return File(cachedThumb.path);
      }

      _thumbLoadingStatus[id] =
          PlatformFunctions.getCachedThumb(id).whenComplete(() {
        _thumbLoadingStatus.remove(id);
      });

      final cachedThumb = await _thumbLoadingStatus[id]!;
      Thumbnail.addAll([cachedThumb]);

      if (cachedThumb.path.isEmpty || cachedThumb.differenceHash == 0) {
        return null;
      }

      return File(cachedThumb.path);
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
    return (file.runtimeType == File)
        ? decode(await ImmutableBuffer.fromFilePath(file.path))
        : decode(await ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SystemGalleryThumbnailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
