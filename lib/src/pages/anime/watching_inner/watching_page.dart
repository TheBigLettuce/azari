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
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/finished_inner/finished_page.dart';
import 'package:gallery/src/pages/anime/inner/anime_inner.dart';
import 'package:gallery/src/widgets/dashboard_card.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class WatchingPage extends StatefulWidget {
  final SavedAnimeEntry entry;

  const WatchingPage({super.key, required this.entry});

  @override
  State<WatchingPage> createState() => _WatchingPageState();
}

class _WatchingPageState extends State<WatchingPage>
    with AlwaysLoadingAnimeMixin {
  late final StreamSubscription<SavedAnimeEntry?> watcher;

  late SavedAnimeEntry entry = widget.entry;
  final state = SkeletonState();
  final scrollController = ScrollController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    maybeFetchInfo(entry, (e) => entry.copySuper(e).save());

    watcher = entry.watch((e) {
      if (e == null) {
        Navigator.pop(context);
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

    loadingFuture?.ignore();

    super.dispose();
  }

  void _addToWatched() {
    WatchedAnimeEntry.move(entry);
  }

  @override
  Widget build(BuildContext context) {
    return wrapLoading(
      context,
      SkeletonSettings(
        "Watching Page", // TODO: change
        state,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AnimeInnerAppBar(
              entry: entry,
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
              BackgroundImage(
                entry: entry,
              ),
              CardShell(
                entry: entry,
                viewPadding: MediaQuery.viewPaddingOf(context),
                buttons: [
                  ...CardPanel.defaultButtons(
                    context,
                    entry,
                    isWatching: true,
                    inBacklog: entry.inBacklog,
                    watched: false,
                    replaceWatchCard: UnsizedCard(
                      subtitle: const Text("Watching"), // TODO: change
                      title: Icon(
                        Icons.play_arrow_rounded,
                        color: entry.inBacklog
                            ? null
                            : Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: "Watching",
                      onPressed: () {
                        if (!entry.inBacklog) {
                          entry.unsetIsWatching();
                          return;
                        }

                        if (!entry.setCurrentlyWatching()) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Can't watch more than 3 at a time"))); // TODO: change
                        }
                      },
                      transparentBackground: true,
                    ),
                  ),
                  UnsizedCard(
                    subtitle: const Text("Done"), // TODO: change
                    title: const Icon(Icons.check_rounded),
                    tooltip: "Done",
                    transparentBackground: true,
                    onPressed: _addToWatched,
                  ),
                  UnsizedCard(
                    subtitle: const Text("Remove"), // TODO: change
                    title: const Icon(Icons.close),
                    tooltip: "Remove",
                    transparentBackground: true,
                    onPressed: () {
                      SavedAnimeEntry.deleteAll([widget.entry.isarId!]);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            const Text("Removed from watching"), // TODO: change
                        action: SnackBarAction(
                            label: "Undo",
                            onPressed: () {
                              SavedAnimeEntry.addAll(
                                  [widget.entry], widget.entry.site);
                            }),
                      ));
                    },
                  )
                ],
                info: [
                  ...CardPanel.defaultInfo(
                    context,
                    entry,
                  ),
                ],
              ),
              AnimeInnerBody(
                api: const Jikan(),
                entry: entry,
                viewPadding: MediaQuery.viewPaddingOf(context),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
