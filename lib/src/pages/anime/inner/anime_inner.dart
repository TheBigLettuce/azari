// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/dashboard_card.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'anime_characters_widgets.dart';
import 'anime_name_widget.dart';
import 'anime_relations.dart';
import 'body_padding.dart';

part 'label.dart';
part 'app_bar.dart';
part 'segment.dart';
part 'segment_constrained.dart';
part 'body.dart';
part 'background_image.dart';
part 'card_panel.dart';

class AnimeInner extends StatefulWidget {
  final AnimeEntry entry;

  const AnimeInner({super.key, required this.entry});

  @override
  State<AnimeInner> createState() => _AnimeInnerState();
}

class _AnimeInnerState extends State<AnimeInner> with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    SavedAnimeEntry.maybeGet(widget.entry.id, widget.entry.site)
        ?.copySuper(widget.entry, true)
        .save();

    WatchedAnimeEntry.maybeGet(
      widget.entry.id,
      widget.entry.site,
    )?.copySuper(widget.entry, true).save();
  }

  @override
  void dispose() {
    scrollController.dispose();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonSettings(
      AppLocalizations.of(context)!.discoverTab,
      state,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimeInnerAppBar(
              entry: widget.entry, scrollController: scrollController)),
      extendBodyBehindAppBar: true,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          child: Stack(
            children: [
              BackgroundImage(entry: widget.entry),
              CardPanel(
                  viewPadding: MediaQuery.viewPaddingOf(context),
                  entry: widget.entry,
                  site: AnimeMetadata.jikan),
              AnimeInnerBody(
                api: const Jikan(),
                entry: widget.entry,
                viewPadding: MediaQuery.viewPaddingOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
