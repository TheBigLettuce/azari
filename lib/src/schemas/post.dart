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
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/isar.dart';

part 'post.g.dart';

Iterable<Widget> makeTags(
    BuildContext context,
    dynamic extra,
    Color dividerColor,
    Color foregroundColor,
    Color systemOverlayColor,
    List<String> tags) {
  if (tags.isEmpty) {
    return [];
  }

  var plug = choosePlatformFullscreenPlug(systemOverlayColor);

  return [
    ListTile(
      textColor: foregroundColor,
      title: Text(AppLocalizations.of(context)!.tagsInfoPage),
    ),
    ...ListTile.divideTiles(
        color: dividerColor,
        tiles: tags.map((e) => ListTile(
              textColor: foregroundColor,
              title: Text(HtmlUnescape().convert(e)),
              onLongPress: () {
                Navigator.push(
                    context,
                    DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                                AppLocalizations.of(context)!.addTagToExcluded),
                            content: Text(e),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.no)),
                              TextButton(
                                  onPressed: () {
                                    BooruTags().excluded.add(e);
                                    Navigator.pop(context);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.yes))
                            ],
                          );
                        }));
              },
              onTap: () {
                BooruTags().onPressed(context, HtmlUnescape().convert(e));
                plug.unFullscreen();
                extra();
              },
            )))
  ];
}

String _fileDownloadUrl(String sampleUrl, String originalUrl) {
  if (path_util.extension(originalUrl) == ".zip") {
    return sampleUrl;
  } else {
    return originalUrl;
  }
}

@collection
class Post implements Cell {
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

  String downloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  /*BooruCell booruCell(void Function(String tag) onTagPressed) => BooruCell(
      post: id,
      sampleUrl: sampleUrl,
      path: previewUrl,
      originalUrl: fileUrl,
      tags: tags,
      onTagPressed: onTagPressed);*/

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

  @ignore
  @override
  List<Widget>? Function() get addButtons => () => [
        if (tags.contains("original"))
          const IconButton(
            icon: Icon(IconData(79)),
            onPressed: null,
          ),
        IconButton(
          icon: const Icon(Icons.public),
          onPressed: () {
            var booru = getBooru();
            launchUrl(booru.browserLink(id),
                mode: LaunchMode.externalApplication);
            booru.close();
          },
        ),
      ];

  @ignore
  @override
  List<Widget>? Function(
      BuildContext context,
      dynamic extra,
      Color borderColor,
      Color foregroundColor,
      Color systemOverlayColor) get addInfo => (BuildContext context,
          dynamic extra,
          Color dividerColor,
          Color foregroundColor,
          Color systemOverlayColor) {
        var downloadUrl = _fileDownloadUrl(sampleUrl, fileUrl);
        List<Widget> list = [
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.pathInfoPage),
            subtitle: Text(downloadUrl),
            onTap: () => launchUrl(Uri.parse(downloadUrl),
                mode: LaunchMode.externalApplication),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.widthInfoPage),
            subtitle: Text("${width}px"),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.heightInfoPage),
            subtitle: Text("${height}px"),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.createdAtInfoPage),
            subtitle: Text(AppLocalizations.of(context)!.date(createdAt)),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.sourceFileInfoPage),
            subtitle: Text(sourceUrl),
            onTap: sourceUrl.isEmpty
                ? null
                : () => launchUrl(Uri.parse(sourceUrl),
                    mode: LaunchMode.externalApplication),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.ratingInfoPage),
            subtitle: Text(rating),
          ),
          ListTile(
            textColor: foregroundColor,
            title: Text(AppLocalizations.of(context)!.scoreInfoPage),
            subtitle: Text(score.toString()),
          ),
          ...makeTags(context, extra, dividerColor, foregroundColor,
              systemOverlayColor, tags.split(' ')),
        ];

        return [
          ListBody(
            children: list,
          )
        ];
      };

  @override
  String alias(bool isList) => isList ? tags : id.toString();

  @override
  Content fileDisplay() {
    var settings = isar().settings.getSync(0);
    String url;
    if (settings!.quality == DisplayQuality.original) {
      url = fileUrl;
    } else if (settings.quality == DisplayQuality.sample) {
      url = sampleUrl;
    } else {
      throw "invalid display quality";
    }

    var type = lookupMimeType(url);
    if (type == null) {
      return Content("", false);
    }

    var typeHalf = type.split("/")[0];

    if (typeHalf == "image") {
      return Content(typeHalf, false, image: NetworkImage(url));
    } else if (typeHalf == "video") {
      return Content(typeHalf, false, videoPath: url);
    } else {
      return Content(typeHalf, false);
    }
  }

  @override
  String fileDownloadUrl() => _fileDownloadUrl(sampleUrl, fileUrl);

  @override
  CellData getCellData(bool isList) => CellData(
      thumb: CachedNetworkImageProvider(previewUrl, headers: {
        "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
      }),
      name: alias(isList));
}
