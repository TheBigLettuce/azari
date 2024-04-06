// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/booru_post_functionality_mixin.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/pages/anime/info_pages/discover_anime_info_page.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:isar/isar.dart';

import 'anime_api.dart';

class AnimeEntry
    with BooruPostFunctionalityMixin
    implements
        AnimeCell,
        Pressable<AnimeEntry>,
        Thumbnailable,
        Downloadable,
        Stickerable {
  const AnimeEntry({
    required this.site,
    required this.type,
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
    required this.explicit,
    required this.staff,
  });

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
  final String type;

  final List<String> titleSynonyms;
  final List<AnimeGenre> genres;
  final List<Relation> relations;
  final List<Relation> staff;

  final double score;

  final int year;
  final int episodes;

  final bool isAiring;
  @enumerated
  final AnimeSafeMode explicit;

  @override
  CellStaticData description() => const CellStaticData(
        ignoreSwipeSelectGesture: true,
      );

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((thumbUrl, id));

  @override
  Contentable openImage(BuildContext context) => NetImage(
        this,
        ContentWidgets.empty(uniqueKey),
        CachedNetworkImageProvider(thumbUrl),
      );

  @override
  String alias(bool isList) => title;

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final (watching, inBacklog) = SavedAnimeEntry.isWatchingBacklog(id, site);

    return [
      if (this is! SavedAnimeEntry && watching)
        !inBacklog
            ? const Sticker(Icons.play_arrow_rounded)
            : const Sticker(Icons.library_add_check),
      if (this is! WatchedAnimeEntry && WatchedAnimeEntry.watched(id, site))
        const Sticker(Icons.check, important: true),
    ];
  }

  @override
  void onPress(BuildContext context,
      GridFunctionality<AnimeEntry> functionality, AnimeEntry cell, int idx) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return DiscoverAnimeInfoPage(
          entry: cell,
        );
      },
    ));
  }
}
