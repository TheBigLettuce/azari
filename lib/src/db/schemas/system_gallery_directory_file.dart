// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/thumbnail.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/grid/cell_data.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/db/schemas/download_file.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../interfaces/contentable.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../widgets/grid/sticker.dart';
import '../state_restoration.dart';
import '../../widgets/translation_notes.dart';
import 'settings.dart';

part 'system_gallery_directory_file.g.dart';

@collection
class SystemGalleryDirectoryFile implements Cell {
  @override
  Id? isarId;

  @override
  Key uniqueKey() => ValueKey(id);

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
  final List<Sticker> injectedStickers = [];

  final String notesFlat;
  final String tagsFlat;
  final bool isDuplicate;
  final bool isFavorite;

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.size,
    required this.height,
    required this.notesFlat,
    required this.isDuplicate,
    required this.isFavorite,
    required this.width,
    required this.tagsFlat,
    required this.isOriginal,
    required this.lastModified,
    required this.originalUri,
  });

  @override
  String alias(bool isList) => name;

  List<(IconData, void Function()?)> _stickers(BuildContext? context) {
    return [
      if (isVideo) (FilteringMode.video.icon, null),
      if (isGif) (FilteringMode.gif.icon, null),
      if (isOriginal) (FilteringMode.original.icon, null),
      if (isDuplicate) (FilteringMode.duplicate.icon, null),
      if (tagsFlat.contains("translated"))
        (
          Icons.translate_outlined,
          context == null
              ? null
              : () {
                  DisassembleResult? res;
                  try {
                    res = PostTags.g.dissassembleFilename(name);
                  } catch (_) {
                    return;
                  }

                  Navigator.push(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) {
                        return TranslationNotes(
                          postId: res!.id,
                          api: BooruAPI.fromEnum(res.booru, page: null),
                        );
                      },
                    ),
                  );
                }
        )
    ];
  }

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    final stickers = [
      ...injectedStickers.map((e) => e.icon).map((e) => (e, null)),
      ..._stickers(context),
    ];

    return stickers.isEmpty ? null : stickers;
  }

  @override
  List<Widget>? addButtons(BuildContext context) {
    DisassembleResult? res;
    try {
      res = PostTags.g.dissassembleFilename(name);
    } catch (_) {}

    return [
      if (size == 0 && res != null)
        IconButton(
            onPressed: () {
              final api = BooruAPI.fromEnum(res!.booru, page: null);

              api.singlePost(res.id).then((post) {
                PlatformFunctions.deleteFiles([this]);

                PostTags.g.addTagsPost(post.filename(), post.tags, true);

                Downloader.g.add(
                    DownloadFile.d(
                        url: post.fileDownloadUrl(),
                        site: api.booru.url,
                        name: post.filename(),
                        thumbUrl: post.previewUrl),
                    Settings.fromDb());
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
      if (res != null)
        IconButton(
            onPressed: () {
              final api = BooruAPI.fromEnum(res!.booru, page: null);

              launchUrl(api.browserLink(res.id),
                  mode: LaunchMode.externalApplication);

              api.close();
            },
            icon: const Icon(Icons.public)),
      IconButton(
          onPressed: () {
            PlatformFunctions.shareMedia(originalUri);
          },
          icon: const Icon(Icons.share))
    ];
  }

  Sticker sizeSticker() {
    if (size == 0) {
      return const Sticker(IconData(0x4B));
    }

    final kb = (size / 1000);
    if (kb < 1000) {
      if (kb > 500) {
        return const Sticker(IconData(0x4B));
      } else {
        return const Sticker(IconData(0x6B));
      }
    } else {
      final mb = kb / 1000;
      if (mb > 2) {
        return const Sticker(IconData(0x4D));
      } else {
        return const Sticker(IconData(0x6D));
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

  @override
  List<Widget>? addInfo(
      BuildContext context, dynamic extra, AddInfoColorData colors) {
    DisassembleResult? res;
    try {
      res = PostTags.g.dissassembleFilename(name);
    } catch (_) {}

    final plug = chooseGalleryPlug();

    return PostBase.wrapTagsSearch(
      context,
      extra,
      colors,
      [
        addInfoTile(
            colors: colors,
            title: AppLocalizations.of(context)!.nameTitle,
            subtitle: name,
            trailing: plug.temporary
                ? null
                : IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          DialogRoute(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .enterNewNameTitle),
                                content: TextFormField(
                                  initialValue: name,
                                  autovalidateMode: AutovalidateMode.always,
                                  decoration:
                                      const InputDecoration(errorMaxLines: 2),
                                  validator: (value) {
                                    if (value == null) {
                                      return AppLocalizations.of(context)!
                                          .valueIsNull;
                                    }
                                    try {
                                      PostTags.g.dissassembleFilename(value);
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
        addInfoTile(colors: colors, title: "Size", subtitle: kbMbSize(size)),
        if (res != null && tagsFlat.contains("translated"))
          TranslationNotes.tile(context, colors.foregroundColor, res.id,
              () => BooruAPI.fromEnum(res!.booru, page: null)),
      ],
      name,
      temporary: plug.temporary,
      showDeleteButton: true,
      launchGrid: plug.temporary
          ? null
          : (t) {
              try {
                final res = PostTags.g.dissassembleFilename(name);
                final tagManager = TagManager.fromEnum(res.booru, true);

                tagManager.onTagPressed(
                    context,
                    Tag(tag: t, isExcluded: false, time: DateTime.now()),
                    res.booru,
                    false);
              } catch (e) {
                log("launching local tag random booru",
                    level: Level.SEVERE.value, error: e);
              }
            },
    );
  }

  @override
  Contentable fileDisplay() {
    final size = Size(width.toDouble(), height.toDouble());

    if (isVideo) {
      return AndroidVideo(uri: originalUri, size: size);
    }

    if (isGif) {
      return AndroidGif(uri: originalUri, size: size);
    }

    return AndroidImage(uri: originalUri, size: size);
  }

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    final stickers = <Sticker>[
      ...injectedStickers,
      ..._stickers(context).map((e) => Sticker(e.$1)),
      if (isFavorite)
        Sticker(Icons.star_rounded,
            right: true,
            color: Colors.yellow.shade900
                .harmonizeWith(Theme.of(context).colorScheme.primary),
            backgroundColor: Colors.yellowAccent.shade100
                .harmonizeWith(Theme.of(context).colorScheme.primary)),
      if (notesFlat.isNotEmpty)
        const Sticker(Icons.sticky_note_2_outlined, right: true)
    ];

    return CellData(
        thumb: ThumbnailProvider(id), name: name, stickers: stickers);
  }

  Thumbnail? getThumbnail() {
    return Dbs.g.thumbnail!.thumbnails.getSync(id);
  }
}

class ThumbnailProvider extends ImageProvider {
  final int id;

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) async {
    final thumb = Dbs.g.thumbnail!.thumbnails.getSync(id);
    if (thumb != null) {
      if (thumb.path.isEmpty || thumb.differenceHash == 0) {
        return MemoryImage(kTransparentImage);
      }
      return FileImage(File(thumb.path));
    }

    final cachedThumb = await PlatformFunctions.getCachedThumb(id);
    ThumbId.addThumbnailsToDb([cachedThumb]);

    return FileImage(File(cachedThumb.path));
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    if (key is MemoryImage) {
      return key.loadImage(key, decode);
    } else if (key is FileImage) {
      return key.loadImage(key, decode);
    }

    throw "invalid key: $key";
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is ThumbnailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  const ThumbnailProvider(this.id);
}

ListTile addInfoTile(
        {required AddInfoColorData colors,
        required String title,
        required String subtitle,
        Widget? trailing}) =>
    ListTile(
      textColor: colors.foregroundColor,
      title: Text(title),
      trailing: trailing,
      subtitle: Text(subtitle),
    );
