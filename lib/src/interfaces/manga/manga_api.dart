// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/manga/pinned_manga.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';

abstract interface class MangaAPI {
  MangaMeta get site;

  String browserUrl(MangaEntry e);

  Future<List<MangaGenre>> tags();

  Future<List<MangaImage>> imagesForChapter(MangaId id);

  Future<double> score(MangaEntry e);
  Future<MangaEntry> single(MangaId id);
  Future<List<MangaChapter>> chapters(
    MangaId id, {
    int page = 0,
    int count = 10,
    MangaChapterOrder order = MangaChapterOrder.desc,
  });

  Future<List<MangaEntry>> search(
    String s, {
    int page = 0,
    int count = 10,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    List<MangaId>? includesTag,
  });

  Future<List<MangaEntry>> top(int page, int count);
}

enum MangaMeta {
  mangaDex(name: "MangaDex", url: "api.mangadex.org");

  final String url;
  final String name;

  String browserUrl() => switch (this) {
        MangaMeta.mangaDex => "mangadex.org",
      };

  const MangaMeta({
    required this.url,
    required this.name,
  });
}

enum MangaChapterOrder {
  desc,
  asc;
}

class MangaImage implements Cell {
  MangaImage(
    this.url,
    this.order,
    this.maxPages,
  );

  final int maxPages;
  final int order;
  final String url;

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  Widget? contentInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => "${order + 1} / $maxPages";

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(url));

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) => const [];

  @override
  ImageProvider<Object>? thumbnail() => null;

  @override
  Key uniqueKey() => ValueKey(url);
}

class MangaEntry implements Cell {
  MangaEntry({
    required this.demographics,
    required this.volumes,
    required this.status,
    required this.imageUrl,
    required this.year,
    required this.safety,
    required this.genres,
    required this.relations,
    required this.titleSynonyms,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.site,
    required this.id,
    required this.animeIds,
    required this.description,
    required this.thumbUrl,
  });

  final String title;
  final String titleEnglish;
  final String titleJapanese;

  final String description;
  final String status;
  final String imageUrl;
  final String thumbUrl;
  final String demographics;

  final int year;
  final int volumes;

  final MangaMeta site;
  final MangaId id;
  final AnimeSafeMode safety;

  final List<AnimeId> animeIds;
  final List<MangaGenre> genres;
  final List<MangaRelation> relations;
  final List<String> titleSynonyms;

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  Widget? contentInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => title;

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(imageUrl));

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) => [
        if (PinnedManga.exist(id.toString(), site))
          const Sticker(Icons.push_pin_rounded),
      ];

  @override
  ImageProvider<Object>? thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(id);
}

class MangaGenre {
  const MangaGenre({
    required this.id,
    required this.name,
  });

  final MangaId id;
  final String name;
}

class MangaRelation {
  const MangaRelation({
    required this.id,
    required this.name,
  });

  final MangaId id;
  final String name;
}

sealed class AnimeId {}

class MalAnimeId implements AnimeId {
  const MalAnimeId(this.id);

  final int id;
}

sealed class MangaId {}

class MangaStringId implements MangaId {
  const MangaStringId(this.id);

  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (other is MangaStringId) {
      return other.id == id;
    }

    return false;
  }

  @override
  int get hashCode => id.hashCode;
}
