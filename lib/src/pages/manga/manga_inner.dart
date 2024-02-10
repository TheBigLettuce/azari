// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_genres.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_padding.dart';
import 'package:gallery/src/pages/anime/info_base/body/synopsis_background.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/more/dashboard/dashboard_card.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class MangaInnerPage extends StatefulWidget {
  final MangaEntry entry;
  final MangaAPI api;

  const MangaInnerPage({
    super.key,
    required this.entry,
    required this.api,
  });

  @override
  State<MangaInnerPage> createState() => _MangaInnerPageState();
}

class _MangaInnerPageState extends State<MangaInnerPage>
    with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();
  double? score;

  @override
  void initState() {
    super.initState();

    widget.api.score(widget.entry).then((value) {
      score = value;

      setState(() {});
    });
  }

  @override
  void dispose() {
    scrollController.dispose();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.background;

    return AnimeInfoTheme(
      mode: widget.entry.safety,
      overlayColor: overlayColor,
      child: SkeletonSettings(
        "Manga info",
        state,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimeInfoAppBar(
            cell: widget.entry,
            scrollController: scrollController,
          ),
        ),
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: Stack(
              children: [
                BackgroundImage(image: widget.entry.thumbnail()!),
                CardShell(
                  viewPadding: MediaQuery.viewPaddingOf(context),
                  title: widget.entry.title,
                  titleEnglish: widget.entry.titleEnglish,
                  titleJapanese: widget.entry.titleJapanese,
                  titleSynonyms: widget.entry.titleSynonyms,
                  safeMode: widget.entry.safety,
                  info: [
                    if (score != null)
                      UnsizedCard(
                        subtitle: Text("score"),
                        title: Text(score!.toString()),
                        tooltip: "score",
                        transparentBackground: true,
                      )
                    else
                      const Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                  ],
                  buttons: [],
                ),
                MangaInfoBody(
                  api: widget.api,
                  overlayColor: overlayColor,
                  entry: widget.entry,
                  viewPadding: MediaQuery.viewPaddingOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MangaInfoBody extends StatelessWidget {
  final MangaEntry entry;
  final MangaAPI api;
  final EdgeInsets viewPadding;
  final Color? overlayColor;

  const MangaInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: viewPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimeGenres<MangaGenre>(
              genres: entry.genres.map((e) => (e, false)).toList(),
              title: (e) => e.name,
              onPressed: (e) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return SearchAnimePage<MangaEntry, MangaId, MangaGenre>(
                      initalGenreId: e.id,
                      explicit: entry.safety,
                      search: (text, page, id, safeMode) {
                        return api.search(text,
                            page: page,
                            includesTag: id != null ? [id] : null,
                            safeMode: safeMode);
                      },
                      idFromGenre: (genre) {
                        return (genre.id, genre.name);
                      },
                      onPressed: (entry) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return MangaInnerPage(
                              entry: entry,
                              api: api,
                            );
                          },
                        ));
                      },
                      genres: (safeMode) {
                        return api.tags().then((value) {
                          final m = <MangaId, MangaGenre>{};

                          for (final e in value) {
                            m[e.id] = e;
                          }

                          return m;
                        });
                      },
                    );
                  },
                ));
              },
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            SynopsisBackground(
              background: "",
              synopsis: entry.description,
              search: (_) {},
              constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width - 16 - 16,
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
          ],
        ),
      ),
    );
  }
}
