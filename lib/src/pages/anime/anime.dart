// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/anime/saved_anime_entry.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/db/schemas/manga/compact_manga_data.dart';
import 'package:gallery/src/db/schemas/manga/pinned_manga.dart';
import 'package:gallery/src/db/schemas/manga/read_manga_chapter.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/net/manga/manga_dex.dart';
import 'package:gallery/src/pages/anime/info_pages/finished_anime_info_page.dart';
import 'package:gallery/src/pages/anime/info_pages/discover_anime_info_page.dart';
import 'package:gallery/src/pages/anime/info_pages/watching_anime_info_page.dart';
import 'package:gallery/src/pages/anime/manga/manga_info_page.dart';
import 'package:gallery/src/pages/anime/paging_container.dart';
import 'package:gallery/src/pages/anime/tab_bar_count.dart';
import 'package:gallery/src/pages/anime/tabs/manga_tab.dart';
import 'package:gallery/src/pages/more/notes/tab_with_count.dart';
import 'package:gallery/src/pages/more/dashboard/dashboard_card.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_quilted.dart';
import 'package:gallery/src/widgets/grid/parts/segment_label.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'search/search_anime.dart';

part 'tabs/discover_tab.dart';
part 'tabs/watching_tab.dart';
part 'tabs/finished_tab.dart';
part 'tabs/reading_tab.dart';
part 'tab_bar_wrapper.dart';

// const int kReadTabIndx = 0;
// const int kMangaTabIndx = 1;
const int kWatchingTabIndx = 0;
const int kDiscoverTabIndx = 1;
const int kWatchedTabIndx = 2;

class AnimePage extends StatefulWidget {
  final void Function(bool) procPop;
  final EdgeInsets viewPadding;

  const AnimePage({
    super.key,
    required this.procPop,
    required this.viewPadding,
  });

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  final watchingKey = GlobalKey<__WatchingTabState>();
  final tabKey = GlobalKey<_TabBarWrapperState>();
  final finishedKey = GlobalKey<__FinishedTabState>();
  // final readKey = GlobalKey<_ReadingTabState>();

  final _textController = TextEditingController();
  final state = SkeletonState();
  late final StreamSubscription<void> watcher;
  late final StreamSubscription<void> watcherWatched;
  // late final StreamSubscription<void> watcherReading;
  late final tabController =
      TabController(initialIndex: kWatchingTabIndx, length: 3, vsync: this);

  final List<AnimeEntry> _discoverEntries = [];
  // final List<MangaEntry> mangaEntries = [];

  int savedCount = 0;

  int readingCount = ReadMangaChapter.countDistinct();

  // final Dio client = Dio();
  final api = const Jikan();
  // late final mangaApi = MangaDex(client);

  final discoverContainer = PagingContainer();
  // final mangaContainer = PagingContainer();

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
    _textController.dispose();
    // client.close(force: true);

    super.dispose();
  }

  bool _launchSearch(bool force) {
    final offsetIndex = tabController.index + tabController.offset;

    // if (force ||
    //     (tabController.offset.isNegative
    //         ? offsetIndex <= 3.5 && offsetIndex > 2.5
    //         : offsetIndex >= 2.5 && offsetIndex < 3.5)) {

    //   return true;
    // }

    if (tabController.offset.isNegative
        ? offsetIndex <= 1.5 && offsetIndex > 0.5
        : offsetIndex >= 0.5 && offsetIndex < 1.5) {
      SearchAnimePage.launchAnimeApi(context, api);

      // SearchAnimePage.launchMangaApi(context, mangaApi);

      return true;
    }

    if (offsetIndex <= 0.5) {
      return false;
    }

    return false;
  }

  void _filter(String? value) {
    setState(() {});

    if (value == null) {
      return;
    }

    watchingKey.currentState?.filter(value);
    finishedKey.currentState?.filter(value);
  }

  void _procHideTab(bool b) {
    if (tabKey.currentState?.clearOrHide() == true) {
      setState(() {});
    }
  }

  void _hideResetSelection() {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      tabKey.currentState?.hideAndClear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
        padding: const EdgeInsets.only(right: 24),
        tabAlignment: TabAlignment.center,
        isScrollable: true,
        controller: tabController,
        tabs: [
          // const WatchingTabCount(
          //   "Reading",
          //   createWatcher: ReadMangaChapter.watchReading, // TODO: change
          // ),
          // const Tab(text: "Manga"), // TODO: change
          TabWithCount(AppLocalizations.of(context)!.watchingTab, savedCount),
          Tab(text: AppLocalizations.of(context)!.discoverTab),
          TabWithCount(AppLocalizations.of(context)!.finishedTab,
              WatchedAnimeEntry.count()),
        ]);

    return PopScope(
      canPop: false,
      onPopInvoked: tabKey.currentState?._showSearchField == true
          ? _procHideTab
          : tabController.index == kDiscoverTabIndx
              ? null
              : widget.procPop,
      child: SkeletonSettings(
        AppLocalizations.of(context)!.animePage,
        state,
        appBar: PreferredSize(
          preferredSize:
              tabBar.preferredSize + Offset(0, widget.viewPadding.top),
          child: TabBarWrapper(
            key: tabKey,
            tabBar: tabBar,
            viewPadding: widget.viewPadding,
            controller: _textController,
            onPressed: _launchSearch,
            filter: _filter,
          ),
        ),
        child: TabBarView(
          controller: tabController,
          children: [
            // ReadingTab(
            //   widget.viewPadding,
            //   key: readKey,
            //   api: mangaApi,
            //   onDispose: _hideResetSelection,
            // ),
            // MangaTab(
            //   container: mangaContainer,
            //   api: mangaApi,
            //   elems: mangaEntries,
            //   viewInsets: widget.viewPadding,
            // ),
            _WatchingTab(
              widget.viewPadding,
              key: watchingKey,
              onDispose: _hideResetSelection,
            ),
            _DiscoverTab(
              api: api,
              procPop: widget.procPop,
              entries: _discoverEntries,
              viewInsets: widget.viewPadding,
              pagingContainer: discoverContainer,
            ),
            _FinishedTab(
              widget.viewPadding,
              key: finishedKey,
              onDispose: _hideResetSelection,
            ),
          ],
        ),
      ),
    );
  }
}
