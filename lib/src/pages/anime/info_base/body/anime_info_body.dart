// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';

import 'anime_characters_widgets.dart';
import 'anime_genres.dart';
import 'anime_relations.dart';
import 'body_padding.dart';
import 'synopsis_background.dart';

class AnimeInfoBody extends StatelessWidget {
  final AnimeEntry entry;
  final EdgeInsets viewPadding;

  const AnimeInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
  });

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: viewPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimeGenres(entry: entry),
            const Padding(padding: EdgeInsets.only(top: 8)),
            SynopsisBackground(
              entry: entry,
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
            AnimeCharactersWidget(entry: entry),
            AnimeRelations(entry: entry),
          ],
        ),
      ),
    );
  }
}
