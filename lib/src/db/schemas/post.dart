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
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/grid/cell_data.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/widgets/translation_notes.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/booru.dart';
import '../../interfaces/contentable.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../plugs/platform_channel.dart';
import '../../widgets/grid/sticker.dart';
import '../../widgets/make_tags.dart';
import '../../widgets/notifiers/filter.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_bar/search_text_field.dart';
import 'tags.dart';

part 'post.g.dart';

@collection
class Post extends PostBase {
  Post(
      {required super.height,
      required super.id,
      required super.md5,
      required super.tags,
      required super.width,
      required super.fileUrl,
      required super.prefix,
      required super.previewUrl,
      required super.sampleUrl,
      required super.ext,
      required super.sourceUrl,
      required super.rating,
      required super.score,
      required super.createdAt});
}

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

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.public),
        onPressed: () {
          final booru =
              BooruAPI.fromEnum(Booru.fromPrefix(prefix)!, page: null);
          launchUrl(booru.browserLink(id),
              mode: LaunchMode.externalApplication);
          booru.close();
        },
      ),
      if (Platform.isAndroid)
        IconButton(
            onPressed: () {
              PlatformFunctions.shareMedia(fileUrl, url: true);
            },
            icon: const Icon(Icons.share))
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
                          api: BooruAPI.fromEnum(Booru.fromPrefix(prefix)!,
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
    late final TagManager tagManager;
    try {
      tagManager = TagManagerNotifier.of(context);
    } catch (_) {
      tagManager = TagManager.fromEnum(Booru.fromPrefix(prefix)!, true);
    }

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
          TranslationNotes.tile(context, colors.foregroundColor, id,
              () => BooruAPI.fromEnum(Booru.fromPrefix(prefix)!, page: null)),
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
      return NetVideo(url);
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
    try {
      provider = CachedNetworkImageProvider(
        previewUrl,
      );
    } catch (_) {
      provider = MemoryImage(kTransparentImage);
    }

    final content = fileDisplay();

    return CellData(thumb: provider, name: alias(isList), stickers: [
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
      data?.searchFocus.hasFocus ?? false
          ? Container()
          : ListBody(
              children: lists,
            ),
      if (postTags.isNotEmpty && data != null)
        searchTextField(context, data, filename, showDeleteButton),
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
