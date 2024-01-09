// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/inner/anime_inner.dart';
import 'package:gallery/src/widgets/dashboard_card.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class RefreshEntryIcon extends StatefulWidget {
  final AnimeEntry entry;
  final void Function(AnimeEntry) save;

  const RefreshEntryIcon(this.entry, this.save, {super.key});

  @override
  State<RefreshEntryIcon> createState() => _RefreshEntryIconState();
}

class _RefreshEntryIconState extends State<RefreshEntryIcon> {
  Future? _refreshingProgress;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: _refreshingProgress != null
            ? null
            : () {
                _refreshingProgress = const Jikan().info(widget.entry.id)
                  ..then((value) {
                    if (value != null) {
                      widget.save(value);
                    }
                  }).whenComplete(() {
                    _refreshingProgress = null;

                    try {
                      setState(() {});
                    } catch (_) {}
                  });

                setState(() {});
              },
        icon: const Icon(Icons.refresh_rounded));
  }
}

class FinishedPage extends StatefulWidget {
  final WatchedAnimeEntry entry;

  const FinishedPage({super.key, required this.entry});

  @override
  State<FinishedPage> createState() => _FinishedPageState();
}

class _FinishedPageState extends State<FinishedPage> {
  late final StreamSubscription<WatchedAnimeEntry?> watcher;
  late WatchedAnimeEntry entry = widget.entry;
  final state = SkeletonState();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    watcher = entry.watch((e) {
      entry = e!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();
    scrollController.dispose();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonSettings(
      "Finished page",
      state,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimeInnerAppBar(
            entry: entry,
            scrollController: scrollController,
            appBarActions: [
              RefreshEntryIcon(entry, (e) => entry.copySuper(e).save())
            ],
          )),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          child: Stack(children: [
            BackgroundImage(
              entry: entry,
            ),
            CardShell(
              entry: entry,
              viewPadding: MediaQuery.viewPaddingOf(context),
              children: [
                ...CardPanel.defaultCards(context, entry,
                    isWatching: false,
                    inBacklog: false,
                    watched: true,
                    replaceWatchCard: UnsizedCard(
                      subtitle: Text("Watched"),
                      title: Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: "Watched",
                      transparentBackground: true,
                    )
                    // UnsizedCard(
                    //   subtitle: Text("Watching"),
                    //   title: Icon(
                    //     Icons.play_arrow_rounded,
                    //     color: entry.inBacklog
                    //         ? null
                    //         : Theme.of(context).colorScheme.primary,
                    //   ),
                    //   tooltip: "Watching",
                    //   onPressed: () {
                    //     if (!entry.inBacklog) {
                    //       entry.unsetIsWatching();
                    //       return;
                    //     }

                    //     if (!entry.setCurrentlyWatching()) {
                    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //           content:
                    //               Text("Can't watch more than 3 at a time")));
                    //     }
                    //   },
                    //   transparentBackground: true,
                    // ),
                    ),
                // UnsizedCard(
                //   subtitle: Text("Done"),
                //   title: Icon(Icons.check_rounded),
                //   tooltip: "Done",
                //   transparentBackground: true,
                //   onPressed: () {
                //     Navigator.push(
                //         context,
                //         DialogRoute(
                //           context: context,
                //           builder: (context) {
                //             return AlertDialog(
                //               actions: [
                //                 TextButton(
                //                     onPressed: _addToWatched, child: Text("ok"))
                //               ],
                //               title: Text("Closing words"),
                //               content: Column(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: [
                //                   TextField(
                //                     controller: textController,
                //                     autofocus: true,
                //                     onSubmitted: (_) => _addToWatched(),
                //                   ),
                //                   Wrap(
                //                     children: [
                //                       ActionChip(
                //                         label: Text("I prefer Jojo"),
                //                         onPressed: () {
                //                           textController.text = "I prefer Jojo";
                //                         },
                //                       )
                //                     ],
                //                   )
                //                 ],
                //               ),
                //             );
                //           },
                //         )).then((value) => textController.text = "");
                //   },
                // )
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
    );
  }
}
