// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'android_gallery_directory_file.g.dart';

class SystemGalleryDirectoryFileShrinked {
  final int id;
  final String originalUri;
  final bool isVideo;

  const SystemGalleryDirectoryFileShrinked(
      this.id, this.originalUri, this.isVideo);
}

@collection
class SystemGalleryDirectoryFile
    implements Cell<SystemGalleryDirectoryFileShrinked> {
  @override
  Id? isarId;

  @Index(unique: true)
  final int id;
  final String bucketId;
  @Index()
  final String name;
  @Index()
  final int lastModified;
  final String originalUri;

  final int height;
  final int width;

  final bool isVideo;
  final bool isGif;

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.height,
    required this.width,
    required this.isOriginal,
    required this.lastModified,
    required this.originalUri,
  });

  bool isDuplicate() {
    return RegExp(r'[(][0-9].*[)][.][a-zA-Z].*').hasMatch(name);
  }

  @ignore
  @override
  List<Widget>? Function(BuildContext context) get addButtons => (_) {
        return [
          if (isDuplicate()) Icon(FilteringMode.duplicate.icon),
          if (isOriginal) Icon(FilteringMode.original.icon),
          IconButton(
              onPressed: () {
                PlatformFunctions.share(originalUri);
              },
              icon: const Icon(Icons.share))
        ];
      };

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (
            context,
            extra,
            colors,
          ) {
            return [
              addInfoTile(
                  colors: colors,
                  title: AppLocalizations.of(context)!.nameTitle,
                  subtitle: name),
              addInfoTile(
                  colors: colors,
                  title: AppLocalizations.of(context)!.dateModified,
                  subtitle: lastModified.toString()),
              addInfoTile(
                  colors: colors,
                  title: AppLocalizations.of(context)!.widthInfoPage,
                  subtitle: "${width}px"),
              addInfoTile(
                  colors: colors,
                  title: AppLocalizations.of(context)!.heightInfoPage,
                  subtitle: "${height}px"),
              ...makeTags(
                  context, extra, colors, PostTags().getTagsPost(name), null)
            ];
          };

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay() {
    final size = Size(width.toDouble(), height.toDouble());

    if (isVideo) {
      return AndroidVideo(uri: originalUri, size: size);
    }

    if (isGif) {
      return AndroidGif(
          uri: originalUri, size: Size(width.toDouble(), height.toDouble()));
    }

    return AndroidImage(
        uri: originalUri, size: Size(width.toDouble(), height.toDouble()));
  }

  final bool isOriginal;

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    var record = androidThumbnail(id);

    return CellData(
        thumb: KeyMemoryImage(
            id.toString() + record.$1.length.toString(), record.$1),
        name: name,
        stickers: [
          if (isVideo) FilteringMode.video.icon,
          if (isGif) FilteringMode.gif.icon,
          if (isOriginal) FilteringMode.original.icon,
          if (isDuplicate()) FilteringMode.duplicate.icon,
        ],
        loaded: record.$2);
  }

  @override
  SystemGalleryDirectoryFileShrinked shrinkedData() {
    return SystemGalleryDirectoryFileShrinked(id, originalUri, isVideo);
  }
}

(Uint8List, bool) androidThumbnail(int id) {
  var thumb = thumbnailIsar().thumbnails.getSync(id);
  return thumb == null
      ? (kTransparentImage, false)
      : (thumb.data as Uint8List, true);
}

class KeyMemoryImage extends ImageProvider<MemoryImage> {
  final String key;
  final Uint8List bytes;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(MemoryImage(bytes));
  }

  @override
  ImageStreamCompleter loadBuffer(
      ImageProvider key,
      // ignore: deprecated_member_use
      DecoderBufferCallback decode) {
    // ignore: deprecated_member_use
    return key.loadBuffer(key, decode);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is KeyMemoryImage && other.key == key;
  }

  const KeyMemoryImage(this.key, this.bytes);

  @override
  int get hashCode => key.hashCode;
}
