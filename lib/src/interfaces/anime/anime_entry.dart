// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/cell_data.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:isar/isar.dart';

import 'anime_api.dart';

class AnimeEntry implements Cell {
  AnimeEntry({
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.year,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.genres,
    required this.relations,
    required this.trailerUrl,
    required this.episodes,
    required this.background,
  });

  @override
  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("id")])
  @enumerated
  final AnimeMetadata site;

  final int id;

  @Index(unique: true, replace: true)
  final String thumbUrl;
  final String siteUrl;
  final String trailerUrl;
  final String title;
  final String titleJapanese;
  final String titleEnglish;
  final String synopsis;
  final String background;

  final List<String> titleSynonyms;
  final List<String> genres;
  final List<Relation> relations;

  final double score;

  final int year;
  final int episodes;

  final bool isAiring;

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      PostBase.openInBrowserButton(Uri.parse(thumbUrl)),
      PostBase.shareButton(context, thumbUrl),
    ];
  }

  @override
  List<Widget>? addInfo(BuildContext context, extra, AddInfoColorData colors) {
    return [
      addInfoTile(colors: colors, title: "Url", subtitle: thumbUrl),
    ];
  }

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => title;

  @override
  Contentable fileDisplay() {
    return NetImage(CachedNetworkImageProvider(thumbUrl));
  }

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    final (watching, inBacklog) = SavedAnimeEntry.isWatchingBacklog(id, site);

    return CellData(
      thumb: CachedNetworkImageProvider(thumbUrl),
      name: title,
      stickers: [
        if (this is! SavedAnimeEntry && watching)
          !inBacklog
              ? const Sticker(Icons.play_arrow_rounded, right: true)
              : const Sticker(Icons.library_add_check, right: true),
        if (this is! WatchedAnimeEntry && WatchedAnimeEntry.watched(id, site))
          const Sticker(Icons.check, right: true),
      ],
    );
  }

  @override
  Key uniqueKey() => ValueKey(thumbUrl);
}
