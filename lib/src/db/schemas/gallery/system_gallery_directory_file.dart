// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/system_gallery_directory_file_functionality_mixin.dart';
import 'package:gallery/src/db/base/system_gallery_thumbnail_provider.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/pages/booru/booru_page.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';
import 'package:gallery/src/widgets/notifiers/filter.dart';
import 'package:gallery/src/widgets/search_bar/search_text_field.dart';
import 'package:gallery/src/widgets/set_wallpaper_tile.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../interfaces/cell/contentable.dart';
import '../../../interfaces/cell/sticker.dart';
import '../../../widgets/translation_notes.dart';
import '../settings/settings.dart';

part 'system_gallery_directory_file.g.dart';

@collection
class SystemGalleryDirectoryFile
    with SystemGalleryDirectoryFileFunctionalityMixin
    implements Cell {
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
  Contentable content() {
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
  ImageProvider<Object>? thumbnail() =>
      SystemGalleryThumbnailProvider(id, isVideo);

  @override
  Key uniqueKey() => ValueKey(id);

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
  final String tagsFlat;
  final bool isDuplicate;
  final bool isFavorite;

  @override
  String alias(bool isList) => name;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    final stickers = [
      ...injectedStickers.map((e) => e.icon).map((e) => (e, null)),
      ...defaultStickers(context, this),
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
      if (res != null && MiscSettings.current.filesExtendedActions)
        IconButton(
            onPressed: () {
              final dio = BooruAPI.defaultClientForBooru(res!.booru);
              final api = BooruAPI.fromEnum(res.booru, dio, EmptyPageSaver());

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
                dio.close(force: true);
              });
            },
            icon: const Icon(Icons.download_outlined)),
      if (res != null)
        IconButton(
            onPressed: () {
              launchUrl(
                res!.booru.browserLink(res.id),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.public)),
      IconButton(
          onPressed: () {
            PlatformFunctions.shareMedia(originalUri);
          },
          icon: const Icon(Icons.share))
    ];
  }

  @override
  Widget? contentInfo(BuildContext context) => GalleryFileInfo(file: this);

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) {
    return [
      ...injectedStickers,
      ...defaultStickers(context, this).map((e) => Sticker(e.$1)),
      if (isFavorite) const Sticker(Icons.star_rounded, important: true),
      if (notesFlat.isNotEmpty) const Sticker(Icons.sticky_note_2_outlined)
    ];
  }
}

class GalleryFileInfo extends StatefulWidget {
  final SystemGalleryDirectoryFile file;
  const GalleryFileInfo({super.key, required this.file});

  @override
  State<GalleryFileInfo> createState() => _GalleryFileInfoState();
}

class _GalleryFileInfoState extends State<GalleryFileInfo>
    with SystemGalleryDirectoryFileFunctionalityMixin {
  late final StreamSubscription<void> watcher;

  SystemGalleryDirectoryFile get file => widget.file;

  final List<String> postTags = [];
  final plug = chooseGalleryPlug();
  late final TagManager? tagManager;

  DisassembleResult? res;

  @override
  void initState() {
    super.initState();

    try {
      res = PostTags.g.dissassembleFilename(file.name);
    } catch (_) {}

    if (res != null) {
      tagManager = TagManager.fromEnum(res!.booru);
    } else {
      tagManager = null;
    }

    postTags.addAll(PostTags.g.getTagsPost(file.name));

    watcher = PostTags.g.watch(file.name, (l) {
      postTags.clear();

      if (l.isEmpty) {
        setState(() {});
        return;
      }

      final t = l.first.tags;

      if (t.isNotEmpty) {
        postTags.addAll(t);
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(
      context,
      t,
      res!.booru,
      overrideSafeMode: safeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterData = FilterNotifier.maybeOf(context);

    final pinnedTags = <String>[];

    final tags = <String>[];

    for (final e in postTags) {
      if (PinnedTag.isPinned(e)) {
        pinnedTags.add(e);
      } else {
        tags.add(e);
      }
    }

    final filename = file.name;

    return SliverMainAxisGroup(slivers: [
      if (!(filterData?.searchFocus.hasFocus ?? false))
        SliverList.list(
          children: [
            MenuWrapper(
              title: filename,
              child: addInfoTile(
                  title: AppLocalizations.of(context)!.nameTitle,
                  subtitle: filename,
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
                                        autofocus: true,
                                        initialValue: filename,
                                        autovalidateMode:
                                            AutovalidateMode.always,
                                        decoration: const InputDecoration(
                                            errorMaxLines: 2),
                                        validator: (value) {
                                          if (value == null) {
                                            return AppLocalizations.of(context)!
                                                .valueIsNull;
                                          }
                                          try {
                                            PostTags.g
                                                .dissassembleFilename(value);
                                            return null;
                                          } catch (e) {
                                            return e.toString();
                                          }
                                        },
                                        onFieldSubmitted: (value) {
                                          PlatformFunctions.rename(
                                              file.originalUri, value);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
                                ));
                          },
                          icon: const Icon(Icons.edit))),
            ),
            addInfoTile(
              title: AppLocalizations.of(context)!.dateModified,
              subtitle: AppLocalizations.of(context)!.date(
                DateTime.fromMillisecondsSinceEpoch(file.lastModified * 1000),
              ),
            ),
            addInfoTile(
              title: AppLocalizations.of(context)!.widthInfoPage,
              subtitle: AppLocalizations.of(context)!.pixels(file.width),
            ),
            addInfoTile(
              title: AppLocalizations.of(context)!.heightInfoPage,
              subtitle: AppLocalizations.of(context)!.pixels(file.height),
            ),
            addInfoTile(
              title: AppLocalizations.of(context)!.sizeInfoPage,
              subtitle: kbMbSize(context, file.size),
            ),
            if (res != null && file.tagsFlat.contains("translated"))
              TranslationNotes.tile(context, res!.id, res!.booru),
            if (!file.isVideo && !file.isGif) SetWallpaperTile(id: file.id),
          ],
        ),
      if (tags.isNotEmpty && filterData != null)
        SliverToBoxAdapter(
          child: SearchTextField(
            filterData,
            filename,
            key: ValueKey(filename),
          ),
        ),
      DrawerTagsWidget(
        tags,
        filename,
        showTagButtons: true,
        launchGrid: _launchGrid,
        excluded: tagManager?.excluded,
        pinnedTags: pinnedTags,
        res: res,
      )
    ]);
  }
}
