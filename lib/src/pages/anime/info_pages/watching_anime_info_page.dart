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
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_info_body.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/anime/info_base/refresh_entry_icon.dart';
import 'package:gallery/src/pages/anime/info_pages/finished_anime_info_page.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WatchingAnimeInfoPage extends StatefulWidget {
  final SavedAnimeEntry entry;

  const WatchingAnimeInfoPage({super.key, required this.entry});

  @override
  State<WatchingAnimeInfoPage> createState() => _WatchingAnimeInfoPageState();
}

class _WatchingAnimeInfoPageState extends State<WatchingAnimeInfoPage>
    with AlwaysLoadingAnimeMixin {
  late final StreamSubscription<SavedAnimeEntry?> watcher;

  late SavedAnimeEntry entry = widget.entry;
  final state = SkeletonState();
  final scrollController = ScrollController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    watcher = entry.watch((e) {
      if (e == null) {
        return;
      }

      entry = e;

      setState(() {});
    }, true);
  }

  @override
  void dispose() {
    watcher.cancel();
    textController.dispose();

    state.dispose();
    scrollController.dispose();

    super.dispose();
  }

  void _addToWatched() {
    WatchedAnimeEntry.moveAll([entry]);

    final newEntry = WatchedAnimeEntry.maybeGet(entry.id, entry.site)!;
    Navigator.of(context, rootNavigator: true)
        .pushReplacement(MaterialPageRoute(
      builder: (context) {
        return FinishedAnimeInfoPage(
          entry: newEntry,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.background;

    return AnimeInfoTheme(
      mode: entry.explicit,
      overlayColor: overlayColor,
      child: WrapFutureRestartable(
        builder: (context, value) {
          return SettingsSkeleton(
            AppLocalizations.of(context)!.watchingTab,
            state,
            fab: FloatingActionButton(
              onPressed: _addToWatched,
              child: const Icon(Icons.check_rounded),
            ),
            bottomAppBar: BottomAppBar(
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        if (!entry.inBacklog) {
                          entry.unsetIsWatching();
                          return;
                        }

                        if (!entry.setCurrentlyWatching()) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .cantWatchThree)));
                        }
                      },
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        color: entry.inBacklog
                            ? null
                            : Theme.of(context).colorScheme.primary,
                      )),
                  ...CardPanel.defaultButtons(
                    context,
                    entry,
                    isWatching: true,
                    inBacklog: entry.inBacklog,
                    watched: false,
                  ),
                  IconButton(
                    onPressed: () {
                      SavedAnimeEntry.deleteAll([entry]);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.removedFromWatching),
                        action: SnackBarAction(
                            label: AppLocalizations.of(context)!.undoLabel,
                            onPressed: () {
                              SavedAnimeEntry.addAll([entry]);
                            }),
                      ));
                    },
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ],
              ),
            ),
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AnimeInfoAppBar(
                  cell: entry,
                  scrollController: scrollController,
                  appBarActions: [
                    RefreshEntryIcon(
                      entry,
                      (e) => entry.copySuper(e).save(),
                    )
                  ],
                )),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom),
                child: Stack(children: [
                  BackgroundImage(image: entry.thumbnail()),
                  Column(
                    children: [
                      CardShell(
                        title: entry.title,
                        titleEnglish: entry.titleEnglish,
                        titleJapanese: entry.titleJapanese,
                        titleSynonyms: entry.titleSynonyms,
                        safeMode: entry.explicit,
                        viewPadding: MediaQuery.viewPaddingOf(context),
                        info: [
                          ...CardPanel.defaultInfo(
                            context,
                            entry,
                          ),
                        ],
                      ),
                      AnimeInfoBody(
                        overlayColor: overlayColor,
                        entry: entry,
                        viewPadding: MediaQuery.viewPaddingOf(context),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          );
        },
        newStatus: () => maybeFetchInfo(entry).then((value) {
          entry.copySuper(value).save();

          return value;
        }),
      ),
    );
  }
}
