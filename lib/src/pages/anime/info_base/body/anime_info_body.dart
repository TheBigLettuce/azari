// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/pages/anime/info_base/body/anime_characters_widgets.dart";
import "package:gallery/src/pages/anime/info_base/body/anime_genres.dart";
import "package:gallery/src/pages/anime/info_base/body/anime_relations.dart";
import "package:gallery/src/pages/anime/info_base/body/body_padding.dart";
import "package:gallery/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:gallery/src/pages/anime/info_base/body/similar_anime.dart";
import "package:gallery/src/pages/anime/info_base/body/synopsis_background.dart";
import "package:gallery/src/pages/anime/search/search_anime.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";

class AnimeInfoBody extends StatelessWidget {
  const AnimeInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
  });
  final AnimeEntryData entry;
  final AnimeAPI api;
  final EdgeInsets viewPadding;

  @override
  Widget build(BuildContext context) {
    final db = DatabaseConnectionNotifier.of(context);

    return BodyPadding(
      viewPadding: viewPadding,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimeStaff(entry: entry),
            const Padding(padding: EdgeInsets.only(top: 8)),
            AnimeGenres<AnimeGenre>(
              genres: entry.genres.map((e) => (e, e.unpressable)).toList(),
              title: (e) => e.title,
              onPressed: (e) {
                SearchAnimePage.launchAnimeApi(
                  context,
                  entry.site.api,
                  safeMode: entry.explicit,
                  initalGenreId: e.id,
                );
              },
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            SynopsisBackground(
              search: (s) {
                SearchAnimePage.launchAnimeApi(
                  context,
                  entry.site.api,
                  search: s,
                );
              },
              background: entry.background,
              synopsis: entry.synopsis,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - 16 - 16,
              ),
            ),
            AnimeCharactersWidget(
              entry: entry,
              api: api,
              db: db.savedAnimeCharacters,
            ),
            AnimePicturesWidget(
              entry: entry,
              api: api,
            ),
            SimilarAnime(entry: entry, api: api),
            AnimeRelations(entry: entry),
          ],
        ),
      ),
    );
  }
}

class AnimeStaff extends StatelessWidget {
  const AnimeStaff({super.key, required this.entry});
  final AnimeEntryData entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return entry.staff.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              entry.staff.join(", "),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          );
  }
}

class AnimePicturesWidget extends StatefulWidget {
  const AnimePicturesWidget({
    super.key,
    required this.entry,
    required this.api,
  });

  final AnimeEntryData entry;
  final AnimeAPI api;

  @override
  State<AnimePicturesWidget> createState() => _AnimePicturesWidgetState();
}

class _AnimePicturesWidgetState extends State<AnimePicturesWidget> {
  Future<List<AnimePicture>>? _future;

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BodySegmentLabel(
                text: l8n.animePicturesLabel,
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).longestSide *
                    0.2 *
                    GridAspectRatio.zeroSeven.value,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: snapshot.data!.indexed
                      .map(
                        (e) => SizedBox(
                          width: MediaQuery.sizeOf(context).longestSide * 0.2,
                          child: CustomGridCellWrapper(
                            onPressed: (context) {
                              ImageView.launchWrapped(
                                context,
                                snapshot.data!.length,
                                (i) => snapshot.data![i].openImage(),
                                startingCell: e.$1,
                              );
                            },
                            child: GridCell(
                              cell: e.$2,
                              hideTitle: false,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        } else {
          return _future != null
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Center(
                  child: FilledButton(
                    onPressed: () {
                      _future = widget.api.pictures(widget.entry);

                      setState(() {});
                    },
                    child: Text(l8n.animeLoadPictures),
                  ),
                );
        }
      },
    );
  }
}
