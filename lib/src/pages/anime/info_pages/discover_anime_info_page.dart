// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_info_body.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DiscoverAnimeInfoPage extends StatefulWidget {
  final AnimeEntry entry;

  const DiscoverAnimeInfoPage({super.key, required this.entry});

  @override
  State<DiscoverAnimeInfoPage> createState() => _DiscoverAnimeInfoPageState();
}

class _DiscoverAnimeInfoPageState extends State<DiscoverAnimeInfoPage>
    with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();

  late final StreamSubscription<void> entriesWatcher;

  late (bool, bool) _isWatchingBacklog =
      SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.entry.site);

  late bool _watched =
      WatchedAnimeEntry.watched(widget.entry.id, widget.entry.site);

  @override
  void initState() {
    super.initState();

    entriesWatcher = SavedAnimeEntry.watchAll((_) {
      _isWatchingBacklog =
          SavedAnimeEntry.isWatchingBacklog(widget.entry.id, widget.entry.site);

      _watched = WatchedAnimeEntry.watched(widget.entry.id, widget.entry.site);

      setState(() {});
    });

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
    entriesWatcher.cancel();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.background;

    return AnimeInfoTheme(
      mode: widget.entry.explicit,
      overlayColor: overlayColor,
      child: SettingsSkeleton(
        AppLocalizations.of(context)!.discoverTab,
        state,
        fab: FloatingActionButton(
          onPressed: _watched
              ? null
              : () {
                  if (_isWatchingBacklog.$2) {
                    SavedAnimeEntry.deleteAll([
                      SavedAnimeEntry.maybeGet(
                              widget.entry.id, widget.entry.site)!
                          .isarId!
                    ]);
                  } else {
                    SavedAnimeEntry.addAll([widget.entry]);
                  }
                },
          child: _watched
              ? const Icon(Icons.check_rounded)
              : _isWatchingBacklog.$1
                  ? const Icon(Icons.library_add_check)
                  : const Icon(Icons.add_rounded),
        ),
        bottomAppBar: BottomAppBar(
          child: Row(
            children: CardPanel.defaultButtons(
              context,
              widget.entry,
              isWatching: _isWatchingBacklog.$1,
              inBacklog: _isWatchingBacklog.$2,
              watched: _watched,
            ),
          ),
        ),
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AnimeInfoAppBar(
                cell: widget.entry, scrollController: scrollController)),
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: Stack(
              children: [
                BackgroundImage(image: widget.entry.thumbnail()!),
                Column(
                  children: [
                    CardPanel(
                      viewPadding: MediaQuery.viewPaddingOf(context),
                      entry: widget.entry,
                    ),
                    AnimeInfoBody(
                      overlayColor: overlayColor,
                      entry: widget.entry,
                      viewPadding: MediaQuery.viewPaddingOf(context),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
