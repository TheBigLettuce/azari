// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:isar/isar.dart";

class AnimeSearchEntry extends AnimeEntryData
    implements Pressable<AnimeSearchEntry> {
  const AnimeSearchEntry({
    required this.genres,
    required this.relations,
    required this.staff,
    required super.site,
    required super.type,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.trailerUrl,
    required super.episodes,
    required super.background,
    required super.explicit,
  });

  @override
  final List<AnimeGenre> genres;

  @override
  final List<AnimeRelation> relations;

  @override
  final List<AnimeRelation> staff;

  @override
  CellStaticData description() => const CellStaticData();

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
}

abstract class AnimeGenre {
  const AnimeGenre({
    required this.id,
    required this.title,
    required this.unpressable,
    required this.explicit,
  });

  final String title;
  final int id;
  final bool unpressable;
  final bool explicit;
}

abstract class AnimeRelation {
  const AnimeRelation({
    required this.id,
    required this.thumbUrl,
    required this.title,
    required this.type,
  });

  final int id;
  final String thumbUrl;
  final String title;
  final String type;

  bool get idIsValid => id != 0 && type != "manga";

  @override
  String toString() => title;
}

abstract class SavedAnimeEntryData extends AnimeEntryData {
  const SavedAnimeEntryData({
    required this.inBacklog,
    required super.site,
    required super.type,
    required super.thumbUrl,
    required super.title,
    required super.titleJapanese,
    required super.titleEnglish,
    required super.score,
    required super.synopsis,
    required super.year,
    required super.id,
    required super.siteUrl,
    required super.isAiring,
    required super.titleSynonyms,
    required super.trailerUrl,
    required super.episodes,
    required super.background,
    required super.explicit,
  });

  final bool inBacklog;

  SavedAnimeEntryData copySuper(
    AnimeEntryData e, [
    bool ignoreRelations = false,
  ]);

  SavedAnimeEntryData copy({
    bool? inBacklog,
    AnimeMetadata? site,
    int? episodes,
    String? trailerUrl,
    String? siteUrl,
    String? title,
    String? titleJapanese,
    String? titleEnglish,
    String? background,
    int? id,
    List<AnimeGenre>? genres,
    List<String>? titleSynonyms,
    List<AnimeRelation>? relations,
    bool? isAiring,
    int? year,
    double? score,
    String? thumbUrl,
    String? synopsis,
    String? type,
    AnimeSafeMode? explicit,
    List<AnimeRelation>? staff,
  });
}

abstract class AnimeEntryData
    implements
        AnimeCell,
        ContentWidgets,
        Thumbnailable,
        Downloadable,
        Stickerable {
  const AnimeEntryData({
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
    required this.trailerUrl,
    required this.episodes,
    required this.background,
    required this.explicit,
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
  List<AnimeGenre> get genres;

  List<AnimeRelation> get relations;
  List<AnimeRelation> get staff;

  final double score;

  final int year;
  final int episodes;

  final bool isAiring;
  @enumerated
  final AnimeSafeMode explicit;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((thumbUrl, id));

  @override
  Contentable openImage() => NetImage(
        this,
        CachedNetworkImageProvider(thumbUrl),
      );

  @override
  String alias(bool isList) => title;

  @override
  String fileDownloadUrl() => thumbUrl;

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    final db = DatabaseConnectionNotifier.of(context);

    final (watching, inBacklog) =
        db.savedAnimeEntries.isWatchingBacklog(id, site);

    return [
      if (this is! SavedAnimeEntryData && watching)
        !inBacklog
            ? const Sticker(Icons.play_arrow_rounded)
            : const Sticker(Icons.library_add_check),
      if (this is! WatchedAnimeEntryData && db.watchedAnime.watched(id, site))
        const Sticker(Icons.check, important: true),
    ];
  }

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
}
