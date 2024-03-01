// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_characters.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import '../cell/sticker.dart';
import 'anime_entry.dart';

abstract class AnimeAPI {
  Future<AnimeEntry?> info(int id);
  Future<List<AnimeCharacter>> characters(AnimeEntry entry);
  Future<List<AnimeEntry>> search(
      String title, int page, int? genreId, AnimeSafeMode? mode);
  Future<Map<int, AnimeGenre>> genres(AnimeSafeMode mode);
  Future<List<AnimeEntry>> top(int page);
  Future<List<AnimeNewsEntry>> animeNews(AnimeEntry entry, int page);
  Future<List<AnimeRecommendations>> recommendations(AnimeEntry entry);
  Future<List<AnimePicture>> pictures(AnimeEntry entry);

  AnimeMetadata get site;

  bool get charactersIsSync;
}

enum AnimeMetadata {
  jikan;

  AnimeAPI get api => switch (this) {
        AnimeMetadata.jikan => const Jikan(),
      };
}

enum AnimeSafeMode {
  safe,
  ecchi,
  h;
}

class AnimePicture extends Cell {
  final String imageUrl;
  final String thumbUrl;

  AnimePicture({
    required this.imageUrl,
    required this.thumbUrl,
  });

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(imageUrl));

  @override
  ImageProvider<Object>? thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => (ValueKey(thumbUrl));

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Widget>? addInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => "";

  @override
  String fileDownloadUrl() => imageUrl;

  @override
  List<Sticker> stickers(BuildContext context) => const [];
}

class AnimeRecommendations extends Cell {
  AnimeRecommendations({
    required this.id,
    required this.thumbUrl,
    required this.title,
  });

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(thumbUrl));

  @override
  ImageProvider<Object>? thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((thumbUrl, id));

  final String thumbUrl;
  final String title;
  final int id;

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Widget>? addInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => title;

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  List<Sticker> stickers(BuildContext context) => const [];
}

class AnimeNewsEntry {
  final String title;
  final String content;
  final String? thumbUrl;
  final String date;

  const AnimeNewsEntry({
    required this.content,
    required this.date,
    required this.thumbUrl,
    required this.title,
  });
}
