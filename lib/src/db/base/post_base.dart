// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/cell_data.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/notifiers/filter.dart';
import 'package:gallery/src/widgets/notifiers/tag_manager.dart';
import 'package:gallery/src/widgets/search_bar/search_text_field.dart';
import 'package:gallery/src/widgets/translation_notes.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/booru/booru_api_state.dart';
import '../../interfaces/cell/contentable.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../plugs/platform_functions.dart';
import '../../interfaces/booru/display_quality.dart';
import '../schemas/tags/tags.dart';

class PostBase implements Cell {
  @override
  Id? isarId;

  @Index()
  final int id;

  final String md5;

  @Index(caseSensitive: false, type: IndexType.hashElements)
  final List<String> tags;

  final int width;
  final int height;

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  @Index(unique: true, replace: true)
  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;
  final String sourceUrl;

  final String ext;

  final String rating;
  final int score;
  final DateTime createdAt;
  final String prefix;

  String filename() =>
      "${prefix.isNotEmpty ? '${prefix}_' : ''}$id - $md5${ext != '.zip' ? ext : path_util.extension(sampleUrl)}";

  static void showQr(BuildContext context, String prefix, int id) {
    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                width: 320,
                height: 320,
                clipBehavior: Clip.antiAlias,
                child: QrImageView(
                  data: "${prefix}_$id",
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  version: QrVersions.auto,
                  size: 320,
                ),
              ),
            );
          },
        ));
  }

  static Widget openInBrowserButton(Uri uri,
          [void Function()? overrideOnPressed]) =>
      IconButton(
        icon: const Icon(Icons.public),
        onPressed: overrideOnPressed ??
            () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );

  static Widget shareButton(BuildContext context, String url,
          [void Function()? onLongPress]) =>
      GestureDetector(
        onLongPress: onLongPress,
        child: IconButton(
            onPressed: () {
              PlatformFunctions.shareMedia(url, url: true);
            },
            icon: const Icon(Icons.share)),
      );

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      openInBrowserButton(Uri.base, () {
        final booru =
            BooruAPIState.fromEnum(Booru.fromPrefix(prefix)!, page: null);

        launchUrl(booru.browserLink(id), mode: LaunchMode.externalApplication);

        booru.close();
      }),
      if (Platform.isAndroid)
        shareButton(context, fileUrl, () {
          showQr(context, prefix, id);
        })
      else
        IconButton(
            onPressed: () {
              showQr(context, prefix, id);
            },
            icon: const Icon(Icons.qr_code_rounded))
    ];
  }

  List<(IconData, void Function()?)> _stickers(
      Contentable content, BuildContext? context) {
    return [
      if (content is NetVideo) (FilteringMode.video.icon, null),
      if (content is NetGif) (FilteringMode.gif.icon, null),
      if (tags.contains("original")) (FilteringMode.original.icon, null),
      if (tags.contains("translated"))
        (
          Icons.translate_outlined,
          context == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) {
                        return TranslationNotes(
                          postId: id,
                          api: BooruAPIState.fromEnum(Booru.fromPrefix(prefix)!,
                              page: null),
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
    final icons = _stickers(fileDisplay(), context);

    return icons.isEmpty ? null : icons;
  }

  @override
  List<Widget>? addInfo(
      BuildContext context, dynamic extra, AddInfoColorData colors) {
    final dUrl = fileDownloadUrl();
    final tagManager = TagManagerNotifier.maybeOfRestorable(context) ??
        TagManager.fromEnum(Booru.fromPrefix(prefix)!);

    return wrapTagsSearch(
      context,
      extra,
      colors,
      [
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.pathInfoPage),
          subtitle: Text(dUrl),
          onTap: () =>
              launchUrl(Uri.parse(dUrl), mode: LaunchMode.externalApplication),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.widthInfoPage),
          subtitle: Text("${width}px"),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.heightInfoPage),
          subtitle: Text("${height}px"),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.createdAtInfoPage),
          subtitle: Text(AppLocalizations.of(context)!.date(createdAt)),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.sourceFileInfoPage),
          subtitle: Text(sourceUrl),
          onTap: sourceUrl.isEmpty
              ? null
              : () => launchUrl(Uri.parse(sourceUrl),
                  mode: LaunchMode.externalApplication),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.ratingInfoPage),
          subtitle: Text(rating),
        ),
        ListTile(
          textColor: colors.foregroundColor,
          title: Text(AppLocalizations.of(context)!.scoreInfoPage),
          subtitle: Text(score.toString()),
        ),
        if (tags.contains("translated"))
          TranslationNotes.tile(
              context,
              colors.foregroundColor,
              id,
              () => BooruAPIState.fromEnum(Booru.fromPrefix(prefix)!,
                  page: null)),
      ],
      filename(),
      supplyTags: tags,
      addExcluded: (t) {
        tagManager.excluded
            .add(Tag(tag: t, isExcluded: true, time: DateTime.now()));
      },
      launchGrid: (t) {
        tagManager.onTagPressed(
            context,
            Tag.string(tag: HtmlUnescape().convert(t)),
            Booru.fromPrefix(prefix)!,
            true);
      },
    );
  }

  @override
  String alias(bool isList) => isList ? tags.join(" ") : id.toString();

  @override
  Contentable fileDisplay() {
    String url = switch (Settings.fromDb().quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    var type = lookupMimeType(url);
    if (type == null) {
      return const EmptyContent();
    }

    var typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      ImageProvider provider;
      try {
        provider = NetworkImage(url);
      } catch (e) {
        provider = MemoryImage(kTransparentImage);
      }

      return typeHalf[1] == "gif" ? NetGif(provider) : NetImage(provider);
    } else if (typeHalf[0] == "video") {
      return NetVideo(path_util.extension(url) == ".zip" ? sampleUrl : url);
    } else {
      return const EmptyContent();
    }
  }

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    ImageProvider provider;
    final isHidden = HiddenBooruPost.isHidden(id, Booru.fromPrefix(prefix)!);

    if (isHidden) {
      provider = MemoryImage(kTransparentImage);
    } else {
      try {
        provider = CachedNetworkImageProvider(
          previewUrl,
        );
      } catch (_) {
        provider = MemoryImage(kTransparentImage);
      }
    }

    final content = fileDisplay();

    return CellData(thumb: provider, name: alias(isList), stickers: [
      if (isHidden) const Sticker(Icons.hide_image_rounded, right: true),
      if (Settings.isFavorite(fileUrl))
        Sticker(Icons.favorite_rounded,
            color: Colors.red.shade900
                .harmonizeWith(Theme.of(context).colorScheme.primary),
            backgroundColor: Colors.redAccent.shade100
                .harmonizeWith(Theme.of(context).colorScheme.primary),
            right: true),
      if (NoteBooru.hasNotes(id, Booru.fromPrefix(prefix)!))
        const Sticker(Icons.sticky_note_2_outlined, right: true),
      ..._stickers(content, context).map((e) => Sticker(e.$1))
    ]);
  }

  static List<Widget> wrapTagsSearch(
    BuildContext context,
    dynamic extra,
    AddInfoColorData colors,
    List<Widget> lists,
    String filename, {
    bool temporary = false,
    bool showDeleteButton = false,
    List<String>? supplyTags,
    void Function(String)? launchGrid,
    void Function(String)? addExcluded,
  }) {
    final data = FilterNotifier.maybeOf(context);
    final List<String> postTags;
    if (supplyTags == null) {
      postTags = PostTags.g.getTagsPost(filename);
    } else {
      postTags = supplyTags;
    }

    return [
      if (!(data?.searchFocus.hasFocus ?? false))
        ListBody(
          children: lists,
        ),
      if (postTags.isNotEmpty && data != null)
        SearchTextField(data, filename, showDeleteButton, colors),
      ...makeTags(context, extra, colors, postTags, temporary ? "" : filename,
          launchGrid: launchGrid, addExcluded: addExcluded)
    ];
  }

  PostBase(
      {required this.id,
      required this.height,
      required this.md5,
      required this.tags,
      required this.width,
      required this.fileUrl,
      required this.prefix,
      required this.previewUrl,
      required this.sampleUrl,
      required this.ext,
      required this.sourceUrl,
      required this.rating,
      required this.score,
      required this.createdAt,
      this.isarId});
}
