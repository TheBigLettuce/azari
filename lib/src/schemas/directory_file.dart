// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'directory_file.g.dart';

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

@collection
class DirectoryFile implements Cell {
  @override
  Id? isarId;

  final String dir;
  @Index(unique: true)
  final String name;
  final String thumbHash;
  final String origHash;
  final int type;
  final int time;
  final String host;
  final List<String> tags;

  @ignore
  @override
  List<Widget>? Function(BuildContext context) get addButtons => (_) => null;

  @ignore
  @override
  List<Widget>? Function(BuildContext context,
      dynamic extra, AddInfoColorData colors) get addInfo => (context, extra,
          colors) {
        return wrapTagsSearch(
            context,
            extra,
            colors,
            [
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.nameTitle),
                subtitle: Text(name),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.directoryTitle),
                subtitle: Text(dir),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.thumbnailHashTitle),
                subtitle: Text(thumbHash),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.originalHashTitle),
                subtitle: Text(origHash),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.typeTitle),
                subtitle: Text(type.toString()),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.timeTitle),
                subtitle: Text(time.toString()),
              ),
            ],
            name,
            null,
            supplyTags: tags);
      };

  @override
  String alias(bool isList) {
    return name;
  }

  @override
  Contentable fileDisplay() {
    if (type == 1) {
      return NetImage(CachedNetworkImageProvider(
          Uri.parse(host).replace(path: '/static/$origHash').toString()));
    } else if (type == 2) {
      return NetVideo(
          Uri.parse(host).replace(path: '/static/$origHash').toString());
    }
    throw "invalid image type";
  }

  @override
  String fileDownloadUrl() =>
      Uri.parse(host).replace(path: "/static/$origHash").toString();

  @override
  CellData getCellData(bool isList) {
    return CellData(
        thumb: NetworkImage(
            Uri.parse(host).replace(path: '/static/$thumbHash').toString()),
        name: name,
        stickers: [
          if (type == 2) FilteringMode.video.icon,
          if (tags.contains("original")) FilteringMode.original.icon,
        ]);
  }

  DirectoryFile(this.dir,
      {required this.host,
      required this.name,
      required this.origHash,
      required this.time,
      required this.thumbHash,
      required this.tags,
      required this.type});
}
