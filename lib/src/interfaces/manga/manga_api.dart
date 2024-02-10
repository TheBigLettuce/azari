// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/icon_data.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';

enum MangaMeta {
  mangaDex(name: "MangaDex", url: "api.mangadex.org");

  final String url;
  final String name;

  const MangaMeta({
    required this.url,
    required this.name,
  });
}

abstract class MangaAPI {
  MangaMeta get site;

  Future<List<MangaGenre>> tags();

  Future<double> score(MangaEntry e);

  Future<List<MangaEntry>> search(
    String s, {
    int page = 0,
    int count = 10,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    List<MangaId>? includesTag,
  });

  Future<List<MangaEntry>> top(int page);
}

class MangaEntry implements Cell {
  MangaEntry({
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

  final int year;

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
  List<Widget>? addInfo(BuildContext context, extra, AddInfoColorData colors) =>
      null;
  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => title;

  @override
  Contentable content() => NetImage(CachedNetworkImageProvider(imageUrl));

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) => const [];

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
}
