// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/pages/anime/anime_info_page.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class AnimeSearchEntry extends AnimeEntryDataImpl implements AnimeEntryData {
  const AnimeSearchEntry({
    required this.imageUrl,
    required this.airedFrom,
    required this.airedTo,
    required this.genres,
    required this.relations,
    required this.staff,
    required this.site,
    required this.type,
    required this.thumbUrl,
    required this.title,
    required this.titleJapanese,
    required this.titleEnglish,
    required this.score,
    required this.synopsis,
    required this.id,
    required this.siteUrl,
    required this.isAiring,
    required this.titleSynonyms,
    required this.trailerUrl,
    required this.episodes,
    required this.background,
    required this.explicit,
  });

  @override
  final String background;
  @override
  final int episodes;
  @override
  final AnimeSafeMode explicit;
  @override
  final int id;
  @override
  final bool isAiring;
  @override
  final double score;
  @override
  final AnimeMetadata site;
  @override
  final String siteUrl;
  @override
  final String synopsis;
  @override
  final String thumbUrl;
  @override
  final String title;
  @override
  final String titleEnglish;
  @override
  final String titleJapanese;
  @override
  final List<String> titleSynonyms;
  @override
  final String trailerUrl;
  @override
  final String type;
  @override
  final List<AnimeGenre> genres;
  @override
  final List<AnimeRelation> relations;
  @override
  final List<AnimeRelation> staff;
  @override
  final DateTime? airedFrom;
  @override
  final DateTime? airedTo;
  @override
  final String imageUrl;

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<AnimeEntryData> functionality,
    AnimeEntryData cell,
    int idx,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AnimeInfoPage(
            entry: cell,
            id: cell.id,
            db: DatabaseConnectionNotifier.of(context),
            apiFactory: cell.site.api,
          );
        },
      ),
    );
  }

  @override
  dynamic properties() => null;

  @override
  AnimeSearchEntry copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? siteUrl,
    String? imageUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    double? score,
    String? thumbUrl,
    String? synopsis,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
    DateTime? airedFrom,
    DateTime? airedTo,
  }) {
    return AnimeSearchEntry(
      imageUrl: imageUrl ?? this.imageUrl,
      explicit: explicit ?? this.explicit,
      type: type ?? this.type,
      site: site ?? this.site,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      title: title ?? this.title,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      score: score ?? this.score,
      synopsis: synopsis ?? this.synopsis,
      id: id ?? this.id,
      relations: relations ?? this.relations,
      staff: staff ?? this.staff,
      genres: genres ?? this.genres,
      siteUrl: siteUrl ?? this.siteUrl,
      isAiring: isAiring ?? this.isAiring,
      titleSynonyms: titleSynonyms ?? this.titleSynonyms,
      background: background ?? this.background,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      episodes: episodes ?? this.episodes,
      airedFrom: airedFrom ?? this.airedFrom,
      airedTo: airedTo ?? this.airedTo,
    );
  }
}

@immutable
abstract class AnimeEntryDataImpl
    with DefaultBuildCellImpl
    implements AnimeEntryData {
  const AnimeEntryDataImpl();

  @override
  CellStaticData description() => const CellStaticData(titleLines: 2);

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((thumbUrl, id));

  @override
  Contentable openImage() => NetImage(
        this,
        CachedNetworkImageProvider(imageUrl),
      );

  @override
  String alias(bool isList) => title;

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final db = DatabaseConnectionNotifier.of(context);

    return [
      // if (score != 0.0)
      //   Sticker(
      //     Icons.thumb_up_alt_outlined,
      //     subtitle: score.toStringAsFixed(2),
      //   ),
      // if (inBacklog) const Sticker(Icons.library_add_check),
      // if (watching) const Sticker(Icons.play_arrow_rounded),
      if (db.savedAnimeEntries.watched.forIdx((id, site)) != null)
        const Sticker(Icons.check, important: true),
    ];
  }

  @override
  void openInfoPage(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AnimeInfoPage(
            entry: this,
            id: id,
            db: DatabaseConnectionNotifier.of(context),
            apiFactory: site.api,
          );
        },
      ),
    );
  }

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<AnimeEntryData> functionality,
    AnimeEntryData cell,
    int idx,
  ) {
    openInfoPage(context);
  }
}
