// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:isar/isar.dart';

part 'compact_manga_data.g.dart';

@collection
class CompactMangaData extends CompactMangaDataBase {
  CompactMangaData({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });

  static void addAll(List<CompactMangaData> l) {
    Dbs.g.anime.writeTxnSync(
        () => Dbs.g.anime.compactMangaDatas.putAllByMangaIdSiteSync(l));
  }

  static CompactMangaData? get(String mangaId, MangaMeta site) {
    return Dbs.g.anime.compactMangaDatas.getByMangaIdSiteSync(mangaId, site);
  }
}

class CompactMangaDataBase implements Cell {
  CompactMangaDataBase({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
  });

  @override
  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("site")])
  final String mangaId;

  @enumerated
  final MangaMeta site;

  final String title;
  final String thumbUrl;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Widget>? addInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => title;

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(thumbUrl));

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) => const [];

  @override
  ImageProvider<Object>? thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(thumbUrl);
}
