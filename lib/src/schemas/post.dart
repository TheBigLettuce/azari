// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../booru/interface.dart';
import '../cell/contentable.dart';
import '../widgets/make_tags.dart';
import '../widgets/notifiers/booru_api.dart';
import '../widgets/notifiers/filter.dart';
import '../widgets/notifiers/grid_tab.dart';
import '../widgets/search_text_field.dart';
import 'tags.dart';

part 'post.g.dart';

@collection
class Post implements Cell {
  @override
  Id? isarId;

  @Index(unique: true, replace: true)
  final int id;

  final String md5;
  final String tags;

  final int width;
  final int height;

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

  @ignore
  @override
  List<Widget>? Function(BuildContext context) get addButtons => (_) => [
        if (tags.contains("original"))
          IconButton(
            icon: Icon(FilteringMode.original.icon),
            onPressed: null,
          ),
        IconButton(
          icon: const Icon(Icons.public),
          onPressed: () {
            final booru = BooruAPI.fromSettings();
            launchUrl(booru.browserLink(id),
                mode: LaunchMode.externalApplication);
            booru.close();
          },
        ),
      ];

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo =>
          (BuildContext context, dynamic extra, AddInfoColorData colors) {
            final dUrl = fileDownloadUrl();
            final tab = GridTabNotifier.of(context);

            return wrapTagsSearch(
              context,
              extra,
              colors,
              [
                ListTile(
                  textColor: colors.foregroundColor,
                  title: Text(AppLocalizations.of(context)!.pathInfoPage),
                  subtitle: Text(dUrl),
                  onTap: () => launchUrl(Uri.parse(dUrl),
                      mode: LaunchMode.externalApplication),
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
              ],
              filename(),
              supplyTags: tags.split(" "),
              addExcluded: (t) {
                tab.excluded.add(Tag(tag: t, isExcluded: true));
              },
              launchGrid: (t) {
                tab.onTagPressed(
                    context,
                    Tag.string(tag: HtmlUnescape().convert(t)),
                    BooruAPINotifier.of(context));
              },
            );
          };

  @override
  String alias(bool isList) => isList ? tags : id.toString();

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
  CellData getCellData(bool isList) {
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
      if (content is NetVideo) FilteringMode.video.icon,
      if (content is NetGif) FilteringMode.gif.icon,
      if (tags.contains("original")) FilteringMode.original.icon
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
      postTags = PostTags().getTagsPost(filename);
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

  Post(
      {required this.height,
      required this.id,
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
      required this.createdAt});
}
