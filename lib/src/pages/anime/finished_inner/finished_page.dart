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
      if (e == null) {
        Navigator.pop(context);
        return;
      }

      entry = e;

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
                ...CardPanel.defaultCards(
                  context,
                  entry,
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
                  ),
                ),
                UnsizedCard(
                  subtitle: Text("Remove"),
                  title: const Icon(Icons.close_rounded),
                  tooltip: "Remove",
                  transparentBackground: true,
                  onPressed: () {
                    WatchedAnimeEntry.delete(
                        widget.entry.id, widget.entry.site);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Removed from watched"),
                      action: SnackBarAction(
                          label: "Undo",
                          onPressed: () {
                            WatchedAnimeEntry.readd(widget.entry);
                          }),
                    ));
                  },
                )
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
