// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:azari/src/net/anime/impl/jikan.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";

abstract class AnimeAPI {
  Future<AnimeEntryData> info(int id);
  Future<List<AnimeCharacter>> characters(AnimeEntryData entry);
  Future<List<AnimeSearchEntry>> search(
    String title,
    int page,
    int? genreId,
    AnimeSafeMode? mode, {
    AnimeSortOrder sortOrder = AnimeSortOrder.normal,
  });
  Future<Map<int, AnimeGenre>> genres(AnimeSafeMode mode);
  Future<List<AnimeNewsEntry>> animeNews(AnimeEntryData entry, int page);
  Future<List<AnimeRecommendations>> recommendations(AnimeEntryData entry);
  Future<List<AnimePicture>> pictures(AnimeEntryData entry);

  AnimeMetadata get site;

  bool get charactersIsSync;
}

enum AnimeSortOrder {
  normal,
  upcoming,
}

enum AnimeMetadata {
  jikan("Jikan/MAL", "api.jikan.moe");

  const AnimeMetadata(this.name, this.apiUrl);

  final String name;
  final String apiUrl;

  AnimeAPI api(Dio client) => switch (this) {
        AnimeMetadata.jikan => Jikan(client),
      };

  String browserUrl() => switch (this) {
        AnimeMetadata.jikan => "myanimelist.net",
      };
}

enum AnimeSafeMode {
  safe,
  ecchi,
  h;
}

class AnimePicture
    implements AnimeCell, ContentWidgets, Thumbnailable, Downloadable {
  const AnimePicture({
    required this.imageUrl,
    required this.thumbUrl,
  });
  final String imageUrl;
  final String thumbUrl;

  @override
  Contentable openImage() => NetImage(
        this,
        CachedNetworkImageProvider(imageUrl),
      );

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(thumbUrl);

  @override
  String alias(bool isList) => "";

  @override
  String fileDownloadUrl() => imageUrl;
}

class AnimeRecommendations implements CellBase, Thumbnailable, Downloadable {
  const AnimeRecommendations({
    required this.id,
    required this.thumbUrl,
    required this.title,
  });

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((thumbUrl, id));

  final String thumbUrl;
  final String title;
  final int id;

  @override
  String alias(bool isList) => title;

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  CellStaticData description() => const CellStaticData(
        titleLines: 2,
        titleAtBottom: true,
      );
}

class AnimeNewsEntry {
  const AnimeNewsEntry({
    required this.content,
    required this.date,
    required this.thumbUrl,
    required this.browserUrl,
    required this.title,
  });
  final String title;
  final String content;
  final String? thumbUrl;
  final DateTime date;
  final String browserUrl;
}
