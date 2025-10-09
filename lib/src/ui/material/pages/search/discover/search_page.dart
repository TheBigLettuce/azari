// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/booru_search_mixin.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/discover/pool_page.dart";
import "package:azari/src/ui/material/pages/search/booru/booru_search_page.dart";
import "package:azari/src/ui/material/pages/search/fading_panel.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/list_tile_list_styled.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class DiscoverSearchPage extends StatefulWidget {
  const DiscoverSearchPage({
    super.key,
    required this.procPop,
    required this.favoritePools,
  });

  final void Function(bool)? procPop;

  final FavoritePoolServiceHandle favoritePools;

  static bool hasServicesRequired() => BooruCommunityAPI.supported(
    const SettingsService().current.selectedBooru,
  );

  static Future<void> open(
    BuildContext context, {
    void Function(bool)? procPop,
    required FavoritePoolServiceHandle favoritePools,
  }) {
    if (!hasServicesRequired()) {
      // TODO: change
      addAlert("GallerySearchPage", "Search functionality isn't available");

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            Opacity(opacity: animation.value, child: child),
        pageBuilder: (context, animation, _) =>
            DiscoverSearchPage(procPop: procPop, favoritePools: favoritePools),
      ),
    );
  }

  @override
  State<DiscoverSearchPage> createState() => _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends State<DiscoverSearchPage>
    with SettingsWatcherMixin {
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final _filteringEvents = StreamController<String>.broadcast();
  late final BooruCommunityAPI api;

  late final GenericListSource<BooruPool> state;

  final page = PageSaver.noPersist();

  @override
  void initState() {
    super.initState();

    api = BooruCommunityAPI.fromEnum(settings.selectedBooru)!;

    state = GenericListSource(() {
      final text = searchController.text.trim();
      if (text.isEmpty) {
        return Future.value([]);
      }

      return api.pools.search(page: 0, pageSaver: page, name: text);
    });
  }

  @override
  void dispose() {
    api.destroy();

    state.destroy();

    _filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SearchPagePopScope(
        searchController: searchController,
        sink: _filteringEvents.sink,
        searchFocus: focusNode,
        procPop: widget.procPop,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              forceMaterialTransparency: true,
              floating: true,
              automaticallyImplyLeading: false,
              centerTitle: true,
              toolbarHeight: 78,
              title: SizedBox(
                height: 48,
                child: Hero(
                  tag: "searchBarAnchor",
                  child: SearchPageSearchBar(
                    complete: null,
                    sink: _filteringEvents.sink,
                    searchTextController: searchController,
                    searchFocus: focusNode,
                  ),
                ),
              ),
            ),
            _PoolsList(
              searchController: searchController,
              state: state,
              api: api,
              filteringEvents: _filteringEvents,
              favoritePools: widget.favoritePools,
            ),
            Builder(
              builder: (context) => SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoolsList extends StatefulWidget {
  const _PoolsList({
    // super.key,
    required this.state,
    required this.filteringEvents,
    required this.searchController,
    required this.api,
    required this.favoritePools,
  });

  final GenericListSource<BooruPool> state;
  final TextEditingController searchController;

  final BooruCommunityAPI api;

  final FavoritePoolServiceHandle favoritePools;

  final StreamController<String> filteringEvents;

  @override
  State<_PoolsList> createState() => __PoolsListState();
}

class __PoolsListState extends State<_PoolsList> {
  GenericListSource<BooruPool> get state => widget.state;

  late final StreamSubscription<bool> _progressEvents;

  late final StreamSubscription<String> subscr;
  String searchStr = "";

  @override
  void initState() {
    super.initState();

    _progressEvents = state.progress.watch((_) {
      setState(() {});
    });

    subscr = widget.filteringEvents.stream.listen((_) async {
      final str_ = widget.searchController.text;

      final str = str_.isEmpty || str_.characters.last == " "
          ? ""
          : str_.trim().split(" ").lastOrNull ?? "";

      if (searchStr == str) {
        return;
      }

      await widget.api.cancelRequests();

      searchStr = str;

      await widget.state.clearRefresh();

      if (context.mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _progressEvents.cancel();
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18 + 4),
            label: l10n.poolsLabel,
          ),
        ),
        if (state.progress.inRefreshing)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: SizedBox(
                  height: 4,
                  width: 40,
                  child: LinearProgressIndicator(),
                ),
              ),
            ),
          )
        else
          searchStr.isEmpty
              ? SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18 + 4) +
                      const EdgeInsets.only(left: 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.startInputingText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18 + 4) +
                      const EdgeInsets.only(left: 8),
                  sliver: ListTileListStyled(
                    itemCount: state.count,
                    sliver: true,
                    tight: true,
                    itemBuilder: (context, index) {
                      final pool = state.backingStorage[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18 + 8,
                        ),
                        leading: SizedBox.square(
                          dimension: 48,
                          child: GridCellImage(
                            blur: false,
                            imageAlign: Alignment.center,
                            thumbnail: CachedNetworkImageProvider(
                              pool.thumbUrl,
                            ),
                          ),
                        ),
                        title: Text(pool.name),
                        subtitle: Text(pool.description, maxLines: 2),
                        onTap: () =>
                            PoolPage.open(context, pool, widget.favoritePools),
                      );
                    },
                  ),
                ),
      ],
    );
  }
}
