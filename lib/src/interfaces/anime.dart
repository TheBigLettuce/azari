// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/interfaces/cell/cell_data.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';

import 'cell/cell.dart';

abstract class AnimeAPI {
  Future<AnimeEntry?> info(int id);
  Future<List<AnimeSearchResult>> search(String title);
  Future<List<AnimeEntry>> top(int page);
}

@immutable
class AnimeSearchResult {}

// @immutable
class AnimeEntry implements Cell {
  AnimeEntry({
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.year,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.genres,
    required this.trailerUrl,
    required this.episodes,
  });

  final String thumbUrl;
  final String siteUrl;
  final String trailerUrl;
  final String title;
  final String titleJapanese;
  final String titleEnglish;
  final String synopsis;
  final List<String> titleSynonyms;
  final List<String> genres;

  final int year;
  final double score;
  final int episodes;

  final bool isAiring;

  @override
  int? isarId;

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
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    return null;
  }

  @override
  String alias(bool isList) {
    return title;
  }

  @override
  Contentable fileDisplay() {
    return NetImage(CachedNetworkImageProvider(thumbUrl));
  }

  @override
  String fileDownloadUrl() {
    return thumbUrl;
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    return CellData(
        thumb: CachedNetworkImageProvider(thumbUrl),
        name: title,
        stickers: const []);
  }

  @override
  Key uniqueKey() {
    return ValueKey(thumbUrl);
  }
}
