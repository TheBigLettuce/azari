// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_segment_label.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'anime_characters_widgets.dart';
import 'anime_genres.dart';
import 'anime_relations.dart';
import 'body_padding.dart';
import 'similar_anime.dart';
import 'synopsis_background.dart';

class AnimeInfoBody extends StatelessWidget {
  final AnimeEntry entry;
  final EdgeInsets viewPadding;
  final Color? overlayColor;

  const AnimeInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
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
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
            AnimeCharactersWidget(entry: entry, overlayColor: overlayColor),
            AnimePicturesWidget(entry: entry, overlayColor: overlayColor),
            SimilarAnime(entry: entry),
            AnimeRelations(entry: entry),
          ],
        ),
      ),
    );
  }
}

class AnimeStaff extends StatelessWidget {
  final AnimeEntry entry;

  const AnimeStaff({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return entry.staff.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              entry.staff.join(", "),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
          );
  }
}

class AnimePicturesWidget extends StatefulWidget {
  final AnimeEntry entry;
  final Color? overlayColor;

  const AnimePicturesWidget({
    super.key,
    required this.entry,
    required this.overlayColor,
  });

  @override
  State<AnimePicturesWidget> createState() => _AnimePicturesWidgetState();
}

class _AnimePicturesWidgetState extends State<AnimePicturesWidget> {
  Future<List<AnimePicture>>? _future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BodySegmentLabel(
                  text: AppLocalizations.of(context)!.animePicturesLabel),
              SizedBox(
                height: MediaQuery.sizeOf(context).longestSide *
                    0.2 *
                    GridAspectRatio.zeroSeven.value,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: snapshot.data!.indexed
                      .map((e) => SizedBox(
                            width: MediaQuery.sizeOf(context).longestSide * 0.2,
                            child: GridCell(
                              cell: e.$2,
                              indx: e.$1,
                              onPressed: (context) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) {
                                    return ImageView(
                                      updateTagScrollPos:
                                          (pos, selectedCell) {},
                                      cellCount: snapshot.data!.length,
                                      scrollUntill: (_) {},
                                      startingCell: e.$1,
                                      onExit: () {},
                                      getCell: (i) => snapshot.data![i],
                                      onNearEnd: null,
                                      focusMain: () {},
                                      systemOverlayRestoreColor:
                                          widget.overlayColor ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .background,
                                    );
                                  },
                                ));
                              },
                              tight: false,
                              download: null,
                              isList: false,
                            ),
                          ))
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
                      _future = widget.entry.site.api.pictures(widget.entry);

                      setState(() {});
                    },
                    child:
                        Text(AppLocalizations.of(context)!.animeLoadPictures),
                  ),
                );
        }
      },
    );
  }
}
