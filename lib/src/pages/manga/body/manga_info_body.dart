// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_genres.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_padding.dart';
import 'package:gallery/src/pages/anime/info_base/body/synopsis_background.dart';
import 'package:gallery/src/pages/manga/body/manga_chapters.dart';
import 'package:gallery/src/pages/manga/body/manga_relations.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';

class MangaInfoBody extends StatelessWidget {
  final MangaEntry entry;
  final MangaAPI api;
  final EdgeInsets viewPadding;
  final Color? overlayColor;
  final ScrollController scrollController;

  const MangaInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
    required this.overlayColor,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: viewPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimeGenres<MangaGenre>(
            genres: entry.genres.map((e) => (e, false)).toList(),
            title: (e) => e.name,
            onPressed: (e) {
              SearchAnimePage.launchMangaApi(
                context,
                api,
                safeMode: entry.safety,
                initalGenreId: e.id,
              );
            },
          ),
          const Padding(padding: EdgeInsets.only(top: 8)),
          SynopsisBackground(
            markdown: true,
            background: "",
            synopsis: entry.description,
            search: (_) {},
            constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 16 - 16,
                maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
          ),
          MangaChapters(
            entry: entry,
            api: api,
            overlayColor: overlayColor,
            scrollController: scrollController,
          ),
          MangaRelations(
            entry: entry,
            api: api,
          ),
        ],
      ),
    );
  }
}
