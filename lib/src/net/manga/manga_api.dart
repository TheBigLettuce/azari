// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/manga/impl/manga_dex.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";

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

  const MangaMeta({
    required this.url,
    required this.name,
  });
  final String url;
  final String name;

  String browserUrl() => switch (this) {
        MangaMeta.mangaDex => "mangadex.org",
      };

  MangaAPI api(Dio client) => switch (this) {
        MangaMeta.mangaDex => MangaDex(client),
      };
}

enum MangaChapterOrder {
  desc,
  asc;
}

class MangaImage
    implements
        CellBase,
        ImageViewContentable,
        ContentWidgets,
        Thumbnailable,
        AppBarButtonable {
  const MangaImage(
    this.url,
    this.order,
    this.maxPages,
  );

  final int maxPages;
  final int order;
  final String url;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(url);

  @override
  Contentable content() => NetImage(
        this,
        thumbnail(),
      );

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    // final data = MangaReaderNotifier.maybeOf(context);

    // if (data == null) {
    //   return const [];
    // }

    // final db = DatabaseConnectionNotifier.of(context);

    return [
      // NavigationAction()
      // SkipChapterButton(
      //   mangaTitle: data.mangaTitle,
      //   key: data.prevChaterKey,
      //   mangaId: data.mangaId.toString(),
      //   startingChapterId: data.chapterId,
      //   api: data.api,
      //   reloadChapters: data.reloadChapters,
      //   onNextPage: data.onNextPage,
      //   direction: SkipDirection.left,
      //   db: db,
      // ),
      // SkipChapterButton(
      //   mangaTitle: data.mangaTitle,
      //   key: data.nextChapterKey,
      //   mangaId: data.mangaId.toString(),
      //   startingChapterId: data.chapterId,
      //   api: data.api,
      //   reloadChapters: data.reloadChapters,
      //   onNextPage: data.onNextPage,
      //   direction: SkipDirection.right,
      //   db: db,
      // ),
    ];
  }

  @override
  String alias(bool isList) => "${order + 1} / $maxPages";

  @override
  Key uniqueKey() => ValueKey(url);
}

mixin MangaEntry
    implements
        MangaEntryBase,
        AnimeCell,
        Pressable<MangaEntry>,
        ContentWidgets,
        Stickerable,
        Thumbnailable {
  @override
  Contentable openImage() => NetImage(
        this,
        CachedNetworkImageProvider(imageUrl),
      );

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String alias(bool isList) => title;

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) => [
        // if (currentDb.pinnedManga.exist(id.toString(), site))
        //   const Sticker(Icons.push_pin_rounded),
      ];

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<MangaEntry> functionality,
    MangaEntry cell,
    int idx,
  ) {
    // final client = Dio();
    // final api = site.api(client);

    // Navigator.of(context, rootNavigator: true).push(
    //   MaterialPageRoute<void>(
    //     builder: (context) {
    //       return MangaInfoPage(
    //         id: id,
    //         api: api,
    //         entry: this,
    //         db: DatabaseConnectionNotifier.of(context),
    //       );
    //     },
    //   ),
    // ).whenComplete(client.close);
  }
}

class MangaEntryBase {
  const MangaEntryBase({
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
    required this.synopsis,
    required this.thumbUrl,
  });

  final String title;
  final String titleEnglish;
  final String titleJapanese;

  final String synopsis;
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
