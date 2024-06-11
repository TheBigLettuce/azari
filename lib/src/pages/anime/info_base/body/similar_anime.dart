// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";

class SimilarAnime extends StatefulWidget {
  const SimilarAnime({
    super.key,
    required this.entry,
    required this.api,
  });
  final AnimeEntryData entry;
  final AnimeAPI api;

  @override
  State<SimilarAnime> createState() => _SimilarAnimeState();
}

class _SimilarAnimeState extends State<SimilarAnime> {
  Future<List<AnimeRecommendations>>? _future;

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
                text: AppLocalizations.of(context)!.animeSimilar,
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).longestSide * 0.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ListView(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    children: snapshot.data!.indexed
                        .map(
                          (e) => SizedBox(
                            width: MediaQuery.sizeOf(context).longestSide *
                                0.2 *
                                GridAspectRatio.zeroFive.value,
                            child: CustomGridCellWrapper(
                              onPressed: (context) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) {
                                      return AnimeInfoPage(
                                        id: e.$2.id,
                                        apiFactory: widget.entry.site.api,
                                        db: DatabaseConnectionNotifier.of(
                                          context,
                                        ),
                                      );
                                    },
                                  ),
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
                      _future = widget.api.recommendations(widget.entry);

                      setState(() {});
                    },
                    child: Text(AppLocalizations.of(context)!.animeLoadSimilar),
                  ),
                );
        }
      },
    );
  }
}
