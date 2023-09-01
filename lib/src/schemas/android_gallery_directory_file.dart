// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'android_gallery_directory_file.g.dart';

@collection
class SystemGalleryDirectoryFile implements Cell {
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

  @Index()
  final int size;

  final bool isVideo;
  final bool isGif;

  final bool isOriginal;

  @ignore
  final List<IconData> injectedStickers = [];

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.size,
    required this.height,
    required this.width,
    required this.isOriginal,
    required this.lastModified,
    required this.originalUri,
  });

  bool isDuplicate() {
    return RegExp(r'[(][0-9].*[)][.][a-zA-Z].*').hasMatch(name);
  }

  bool isFavorite() {
    return blacklistedDirIsar().favoriteMedias.getSync(id) != null;
  }

  @ignore
  @override
  List<Widget>? Function(BuildContext context) get addButtons => (_) {
        DissolveResult? res;
        try {
          res = PostTags().dissassembleFilename(name);
        } catch (_) {}

        return [
          if (size == 0 && res != null)
            IconButton(
                onPressed: () {
                  final api = booruApiFromPrefix(res!.booru);

                  api.singlePost(res.id).then((post) {
                    PlatformFunctions.deleteFiles([this]);

                    PostTags().addTagsPost(
                        post.filename(), post.tags.split(" "), true);

                    Downloader().add(File.d(
                        post.fileDownloadUrl(), api.domain, post.filename()));
                  }).onError((error, stackTrace) {
                    log("loading post for download",
                        level: Level.SEVERE.value,
                        error: error,
                        stackTrace: stackTrace);
                  }).whenComplete(() {
                    api.close();
                  });
                },
                icon: const Icon(Icons.download_outlined)),
          if (isDuplicate()) Icon(FilteringMode.duplicate.icon),
          if (isFavorite()) Icon(FilteringMode.favorite.icon),
          if (isOriginal) Icon(FilteringMode.original.icon),
          IconButton(
              onPressed: () {
                PlatformFunctions.share(originalUri);
              },
              icon: const Icon(Icons.share))
        ];
      };

  IconData sizeSticker() {
    if (size == 0) {
      return const IconData(0x4B);
    }

    final kb = (size / 1000);
    if (kb < 1000) {
      if (kb > 500) {
        return const IconData(0x4B);
      } else {
        return const IconData(0x6B);
      }
    } else {
      final mb = kb / 1000;
      if (mb > 2) {
        return const IconData(0x4D);
      } else {
        return const IconData(0x6D);
      }
    }
  }

  String kbMbSize(int bytes) {
    if (bytes == 0) {
      return "0";
    }
    final res = bytes / 1000;
    if (res > 1000) {
      return "${(res / 1000).toStringAsFixed(1)} MB";
    }

    return "${res.toStringAsFixed(1)} KB";
  }

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (
            context,
            extra,
            colors,
          ) {
            return wrapTagsSearch(
                context,
                extra,
                colors,
                [
                  addInfoTile(
                      colors: colors,
                      title: AppLocalizations.of(context)!.nameTitle,
                      subtitle: name,
                      trailing: GalleryImpl.instance().temporary
                          ? null
                          : IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    DialogRoute(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .enterNewNameTitle),
                                          content: TextFormField(
                                            initialValue: name,
                                            autovalidateMode:
                                                AutovalidateMode.always,
                                            maxLines: 2,
                                            minLines: 1,
                                            decoration: const InputDecoration(
                                                errorMaxLines: 2),
                                            validator: (value) {
                                              if (value == null) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .valueIsNull;
                                              }
                                              try {
                                                PostTags().dissassembleFilename(
                                                    value);
                                                return null;
                                              } catch (e) {
                                                return e.toString();
                                              }
                                            },
                                            onFieldSubmitted: (value) {
                                              PlatformFunctions.rename(
                                                  originalUri, value);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      },
                                    ));
                              },
                              icon: const Icon(Icons.edit))),
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
                  addInfoTile(
                      colors: colors, title: "Size", subtitle: kbMbSize(size))
                ],
                name,
                null,
                temporary: GalleryImpl.instance().temporary,
                showDeleteButton: true);
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

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    final stickers = [
      ...injectedStickers,
      if (isVideo) FilteringMode.video.icon,
      if (isGif) FilteringMode.gif.icon,
      if (isOriginal) FilteringMode.original.icon,
      if (isDuplicate()) FilteringMode.duplicate.icon,
      if (isFavorite()) FilteringMode.favorite.icon,
    ];

    final record = androidThumbnail(id);

    return CellData(
        thumb: KeyMemoryImage(
            id.toString() + record.$1.length.toString(), record.$1),
        name: name,
        stickers: stickers,
        loaded: record.$2);
  }

  Thumbnail? getThumbnail() {
    return thumbnailIsar().thumbnails.getSync(id);
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
