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
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_info_body.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnimeInfoIdPage extends StatefulWidget {
  final int id;
  final AnimeMetadata site;

  const AnimeInfoIdPage({
    super.key,
    required this.id,
    required this.site,
  });

  @override
  State<AnimeInfoIdPage> createState() => _AnimeInfoIdPageState();
}

class _AnimeInfoIdPageState extends State<AnimeInfoIdPage>
    with TickerProviderStateMixin {
  final state = SkeletonState();
  final scrollController = ScrollController();

  late final StreamSubscription<void> entriesWatcher;

  late Future<AnimeEntry?> _future;

  @override
  void initState() {
    super.initState();

    entriesWatcher = SavedAnimeEntry.watchAll((_) {
      setState(() {});
    });

    _future = widget.site.api.info(widget.id).then((value) {
      if (value != null) {
        SavedAnimeEntry.maybeGet(widget.id, widget.site)
            ?.copySuper(value, true)
            .save();

        WatchedAnimeEntry.maybeGet(
          value.id,
          value.site,
        )?.copySuper(value, true).save();
      }

      return value;
    });
  }

  @override
  void dispose() {
    entriesWatcher.cancel();

    _future.ignore();

    scrollController.dispose();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget errorW(String str) => Scaffold(
          appBar: AppBar(actions: const [BackButton()]),
          body: Center(
            child: Text(str),
          ),
        );

    final overlayColor = Theme.of(context).colorScheme.background;

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == null) {
          return errorW(AppLocalizations.of(context)!.invalidAnimeEntry);
        }

        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return errorW(snapshot.error!.toString());
        } else {
          final entry = snapshot.data!;

          late (bool, bool) isWatchingBacklog =
              SavedAnimeEntry.isWatchingBacklog(entry.id, entry.site);

          late bool watched = WatchedAnimeEntry.watched(entry.id, entry.site);

          return AnimeInfoTheme(
            overlayColor: overlayColor,
            mode: snapshot.data!.explicit,
            child: Builder(
              builder: (context) {
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SettingsSkeleton(
                    AppLocalizations.of(context)!.discoverTab,
                    state,
                    appBar: PreferredSize(
                        preferredSize: const Size.fromHeight(kToolbarHeight),
                        child: AnimeInfoAppBar(
                            cell: entry, scrollController: scrollController)),
                    fab: FloatingActionButton(
                      onPressed: watched
                          ? null
                          : () {
                              if (isWatchingBacklog.$2) {
                                SavedAnimeEntry.deleteAll([
                                  SavedAnimeEntry.maybeGet(
                                          entry.id, entry.site)!
                                      .isarId!
                                ]);
                              } else {
                                SavedAnimeEntry.addAll([entry], entry.site);
                              }
                            },
                      child: watched
                          ? const Icon(Icons.check_rounded)
                          : isWatchingBacklog.$1
                              ? const Icon(Icons.library_add_check)
                              : const Icon(Icons.add_rounded),
                    ),
                    bottomAppBar: BottomAppBar(
                      child: Row(
                        children: CardPanel.defaultButtons(
                          context,
                          entry,
                          isWatching: isWatchingBacklog.$1,
                          inBacklog: isWatchingBacklog.$2,
                          watched: watched,
                        ),
                      ),
                    ),
                    expectSliverBody: false,
                    extendBodyBehindAppBar: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.viewPaddingOf(context).bottom),
                        child: Stack(
                          children: [
                            BackgroundImage(image: snapshot.data!.thumbnail()!),
                            Column(
                              children: [
                                CardPanel(
                                  viewPadding:
                                      MediaQuery.viewPaddingOf(context),
                                  entry: snapshot.data!,
                                ),
                                AnimeInfoBody(
                                  overlayColor: overlayColor,
                                  entry: snapshot.data!,
                                  viewPadding:
                                      MediaQuery.viewPaddingOf(context),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(),
                );
              },
            ),
          );
        }
      },
    );
  }
}
