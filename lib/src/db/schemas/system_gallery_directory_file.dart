// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:typed_data';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/grid/cell_data.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_channel.dart';
import 'package:gallery/src/db/schemas/download_file.dart';
import 'package:gallery/src/db/schemas/favorite_media.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:gallery/src/db/schemas/thumbnail.dart';
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

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.size,
    required this.height,
    required this.notesFlat,
    required this.width,
    required this.isOriginal,
    required this.lastModified,
    required this.originalUri,
  });

  @override
  String alias(bool isList) => name;

  bool isDuplicate() {
    return RegExp(r'[(][0-9].*[)][.][a-zA-Z0-9].*').hasMatch(name);
  }

  bool isFavorite() {
    return Dbs.g.blacklisted.favoriteMedias.getSync(id) != null;
  }

  List<(IconData, void Function()?)> _stickers(BuildContext? context) {
    return [
      if (isVideo) (FilteringMode.video.icon, null),
      if (isGif) (FilteringMode.gif.icon, null),
      if (isOriginal) (FilteringMode.original.icon, null),
      if (isDuplicate()) (FilteringMode.duplicate.icon, null),
      if (PostTags.g.containsTag(name, "translated"))
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
        if (res != null && PostTags.g.containsTag(name, "translated"))
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
      if (isFavorite())
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
        thumb: ThumbnailProvider(id, isVideo ? name : null),
        name: name,
        stickers: stickers);
  }

  Thumbnail? getThumbnail() {
    return Dbs.g.thumbnail!.thumbnails.getSync(id);
  }
}

(Uint8List, bool) androidThumbnail(int id) {
  final thumb = Dbs.g.thumbnail!.thumbnails.getSync(id);
  return thumb == null
      ? (kTransparentImage, false)
      : (thumb.data as Uint8List, true);
}

class ThumbnailProvider extends ImageProvider<MemoryImage> {
  final int id;
  final String? fileName;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) async {
    final (thumb, loaded) = androidThumbnail(id);
    if (loaded) {
      return MemoryImage(thumb);
    }

    final directThumb = await PlatformFunctions.getThumbDirectly(id);
    if (directThumb.differenceHash == 0 && fileName != null) {
      try {
        final res = PostTags.g.dissassembleFilename(fileName!);
        final api = BooruAPI.fromEnum(res.booru, page: null);
        MemoryImage? image;

        try {
          final post = await api.singlePost(res.id);

          final t =
              await PlatformFunctions.getThumbNetwork(post.previewUrl, id);

          ThumbId.addThumbnailsToDb([t]);

          image = MemoryImage(t.thumb);
        } catch (e) {
          log("video thumb 2", level: Level.WARNING.value, error: e);
        }

        api.close();

        return image ?? MemoryImage(kTransparentImage);
      } catch (_) {
        ThumbId.addThumbnailsToDb([directThumb]);

        return MemoryImage(directThumb.thumb);
      }
    } else {
      ThumbId.addThumbnailsToDb([directThumb]);

      return MemoryImage(directThumb.thumb);
    }
  }

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return key.loadImage(key, decode);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is ThumbnailProvider && other.id == id;
  }

  const ThumbnailProvider(this.id, this.fileName);

  @override
  int get hashCode => id.hashCode;
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
