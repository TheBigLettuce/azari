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
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/refreshing_status_interface.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/finished_inner/finished_page.dart';
import 'package:gallery/src/pages/anime/inner/anime_inner.dart';
import 'package:gallery/src/pages/anime/watching_inner/watching_page.dart';
import 'package:gallery/src/pages/notes/tab_with_count.dart';
import 'package:gallery/src/widgets/dashboard_card.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/segment_label.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import 'search/search_anime.dart';

part 'tabs/discover_tab.dart';
part 'tabs/watching_tab.dart';
part 'tabs/finished_tab.dart';

class AnimePage extends StatefulWidget {
  final void Function(bool) procPop;
  final EdgeInsets viewPadding;

  const AnimePage(
      {super.key, required this.procPop, required this.viewPadding});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  final state = SkeletonState();
  late final StreamSubscription<void> watcher;
  late final StreamSubscription<void> watcherWatched;
  late final tabController =
      TabController(initialIndex: 1, length: 4, vsync: this);

  final List<AnimeEntry> _discoverEntries = [];

  int _discoverPage = 0;

  int savedCount = 0;

  double discoverScrollOffset = 0;

  Future<int>? status;

  final Map<void Function(int?, bool), Null> m = {};

  late final discoverInterface = RefreshingStatusInterface(
    isRefreshing: () => status != null,
    save: (s) {
      status?.ignore();
      status = s;

      status?.then((value) {
        for (final f in m.keys) {
          f(value, false);
        }
      }).onError((error, stackTrace) {
        for (final f in m.keys) {
          f(null, false);
        }
      }).whenComplete(() => status = null);
    },
    register: (f) {
      if (status != null) {
        f(null, true);
      }

      m[f] = null;
    },
    unregister: (f) => m.remove(f),
    reset: () {
      status?.ignore();
      status = null;
    },
  );

  @override
  void initState() {
    super.initState();

    tabController.addListener(() {
      GlueProvider.of<AnimeEntry>(context).close();

      setState(() {});
    });

    savedCount = SavedAnimeEntry.count();

    watcher = SavedAnimeEntry.watchAll((_) {
      savedCount = SavedAnimeEntry.count();

      setState(() {});
    });

    watcherWatched = WatchedAnimeEntry.watchAll((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    state.dispose();
    watcher.cancel();
    watcherWatched.cancel();
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
        padding: const EdgeInsets.only(right: 24),
        tabAlignment: TabAlignment.center,
        isScrollable: true,
        controller: tabController,
        tabs: [
          const Tab(text: "News"), // TODO: change
          TabWithCount("Watching", savedCount),
          const Tab(text: "Discover"), // TODO: change
          TabWithCount("Finished", WatchedAnimeEntry.count()),
        ]);

    return PopScope(
      canPop: false,
      onPopInvoked: tabController.index == 2 ? null : widget.procPop,
      child: SkeletonSettings(
        "Anime",
        state,
        // extendBody: true,
        appBar: PreferredSize(
            preferredSize:
                tabBar.preferredSize + Offset(0, widget.viewPadding.top),
            child: Padding(
              padding: EdgeInsets.only(top: widget.viewPadding.top),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  tabBar,
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                          Theme.of(context).colorScheme.background,
                          Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.7),
                          Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.5),
                          Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.3),
                          Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0)
                        ])),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, right: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return const SearchAnimePage(api: Jikan());
                          },
                        ));
                      },
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceTint
                            .withOpacity(0.8),
                      ),
                    ),
                  )
                ],
              ),
            )),
        child: TabBarView(
          controller: tabController,
          children: [
            const EmptyWidget(),
            _WatchingTab(widget.viewPadding),
            _DiscoverTab(
              procPop: widget.procPop,
              entries: _discoverEntries,
              viewInsets: widget.viewPadding,
              refreshingInterface: discoverInterface,
              initalPage: () => _discoverPage,
              initalScrollOffset: () => discoverScrollOffset,
              updateScrollPosition: (offset, {infoPos, selectedCell}) =>
                  discoverScrollOffset = offset,
              savePage: (p) => _discoverPage = p,
            ),
            _FinishedTab(widget.viewPadding),
          ],
        ),
      ),
    );
  }
}
