// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/net/anime/impl/jikan.dart";
import "package:gallery/src/pages/anime/anime_info_page.dart";
import "package:gallery/src/pages/anime/search/search_anime.dart";
import "package:gallery/src/pages/anime/tab_with_count.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/dashboard/dashboard_card.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/grid_frame/parts/segment_label.dart";
import "package:gallery/src/widgets/skeletons/settings.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

part "tab_bar_wrapper.dart";
part "tabs/discover_tab.dart";
part "tabs/finished_tab.dart";
part "tabs/watching_tab.dart";

const int kWatchingTabIndx = 0;
const int kDiscoverTabIndx = 1;
const int kWatchedTabIndx = 2;

abstract interface class AnimeCell implements CellBase {
  Contentable openImage();
}

class AnimePage extends StatefulWidget {
  const AnimePage({
    super.key,
    required this.procPop,
    required this.db,
  });

  final void Function(bool) procPop;

  final DbConn db;

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  final watchingKey = GlobalKey<__WatchingTabState>();
  final tabKey = GlobalKey<_TabBarWrapperState>();
  final finishedKey = GlobalKey<__FinishedTabState>();
  final discoverKey = GlobalKey<_DiscoverTabState>();

  final _textController = TextEditingController();
  final state = SkeletonState();
  late final StreamSubscription<void> watcherWatched;

  late final tabController = TabController(length: 3, vsync: this);

  final api = const Jikan();

  final registry = PagingStateRegistry();

  @override
  void initState() {
    super.initState();

    tabController.addListener(() {
      GlueProvider.generateOf(context)().updateCount(0);

      setState(() {});
    });

    // savedCount = savedAnimeEntries.count;

    // watcher = savedAnimeEntries.watchAll((_) {
    //   savedCount = savedAnimeEntries.count;

    //   setState(() {});
    // });

    watcherWatched = watchedAnimeEntries.watchAll((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    registry.dispose();

    state.dispose();
    // watcher.cancel();
    watcherWatched.cancel();
    tabController.dispose();
    _textController.dispose();

    super.dispose();
  }

  bool _launchSearch(bool force) {
    final offsetIndex = tabController.index + tabController.offset;

    if (tabController.offset.isNegative
        ? offsetIndex <= 1.5 && offsetIndex > 0.5
        : offsetIndex >= 0.5 && offsetIndex < 1.5) {
      discoverKey.currentState?.openSearchSheet();

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

    watchingKey.currentState?.doFilter(value);
    finishedKey.currentState?.doFilter(value);
  }

  void _procHideTab(bool b, Object? _) {
    if (tabKey.currentState?.clearOrHide() ?? false) {
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
    final l10n = AppLocalizations.of(context)!;

    final tabBar = TabBar(
      padding: const EdgeInsets.only(right: 24),
      tabAlignment: TabAlignment.center,
      isScrollable: true,
      controller: tabController,
      tabs: [
        TabWithCount(
          l10n.watchingTab,
          savedAnimeEntries.watchCount,
        ),
        Tab(text: l10n.discoverTab),
        TabWithCount(
          l10n.finishedTab,
          watchedAnimeEntries.watchCount,
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          tabKey.currentState?._showSearchField ?? false ? _procHideTab : null,
      child: SettingsSkeleton(
        l10n.animePage,
        state,
        appBar: PreferredSize(
          preferredSize: tabBar.preferredSize +
              Offset(0, MediaQuery.viewPaddingOf(context).top),
          child: TabBarWrapper(
            key: tabKey,
            tabBar: tabBar,
            controller: _textController,
            onPressed: _launchSearch,
            filter: _filter,
          ),
        ),
        child: TabBarView(
          controller: tabController,
          children: [
            _WatchingTab(
              procPop: widget.procPop,
              key: watchingKey,
              onDispose: _hideResetSelection,
              db: widget.db,
            ),
            DiscoverTab(
              api: api,
              key: discoverKey,
              procPop: widget.procPop,
              db: widget.db,
              registry: registry,
            ),
            _FinishedTab(
              key: finishedKey,
              onDispose: _hideResetSelection,
              procPop: widget.procPop,
              db: widget.db,
            ),
          ],
        ),
      ),
    );
  }
}
