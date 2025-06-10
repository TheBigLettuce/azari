// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/actions.dart"
    as booru_actions;
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class FavoritePostsPage extends StatefulWidget {
  const FavoritePostsPage({
    super.key,
    required this.rootNavigatorPop,
    required this.selectionController,
  });

  final void Function(bool)? rootNavigatorPop;
  final SelectionController selectionController;

  static bool hasServicesRequired() =>
      GridSettingsService.available && FavoritePostSourceService.available;

  @override
  State<FavoritePostsPage> createState() => _FavoritePostsPageState();
}

mixin FavoritePostsPageLogic<W extends StatefulWidget> on State<W> {
  final searchTextController = TextEditingController();

  late final SafeModeState safeModeState;
  late final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    final (settings, favoritePosts) = (
      const SettingsService().current,
      const FavoritePostSourceService(),
    );

    safeModeState = SafeModeState(settings.safeMode);

    filter = ChainedFilterResourceSource(
      ResourceSource.external(
        favoritePosts.cache,
        trySorted: (sort) {
          if (sort == SortingMode.none) {
            return favoritePosts.cache;
          }

          final values = favoritePosts.cache.toList()
            ..sort((e1, e2) {
              return switch (sort) {
                SortingMode.none || SortingMode.size => e2.id.compareTo(e1.id),
                SortingMode.rating => e1.rating.index.compareTo(
                  e2.rating.index,
                ),
                SortingMode.score => e1.score.compareTo(e2.score),
                SortingMode.stars => e1.stars.asNumber.compareTo(
                  e2.stars.asNumber,
                ),
                SortingMode.color => e1.filteringColors.index.compareTo(
                  e2.filteringColors.index,
                ),
              };
            });

          return values;
        },
      ),
      ListStorage(reverse: true),
      filter: (cells, filteringMode, sortingMode, colors, end, data) {
        return switch (filteringMode) {
          FilteringMode.onlyHalfStars => (
            _filterTag(
              cells.where(
                (e) =>
                    _matchSafeMode(e.rating) &&
                    e.stars != FavoriteStars.zero &&
                    e.stars.isHalf &&
                    (colors == FilteringColors.noColor ||
                        e.filteringColors == colors),
              ),
            ),
            data,
          ),
          FilteringMode.onlyFullStars => (
            _filterTag(
              cells.where(
                (e) =>
                    _matchSafeMode(e.rating) &&
                    e.stars != FavoriteStars.zero &&
                    !e.stars.isHalf &&
                    (colors == FilteringColors.noColor ||
                        e.filteringColors == colors),
              ),
            ),
            data,
          ),
          FilteringMode.fiveStars ||
          FilteringMode.fourHalfStars ||
          FilteringMode.fourStars ||
          FilteringMode.threeHalfStars ||
          FilteringMode.threeStars ||
          FilteringMode.twoHalfStars ||
          FilteringMode.twoStars ||
          FilteringMode.oneHalfStars ||
          FilteringMode.oneStars ||
          FilteringMode.zeroHalfStars ||
          FilteringMode.zeroStars => (
            _filterTag(_filterStars(cells, filteringMode, colors)),
            data,
          ),
          FilteringMode.same => sameFavorites(cells, data, end, _collector),
          FilteringMode.tag => (
            _filterTag(
              cells.where(
                (e) =>
                    _matchSafeMode(e.rating) &&
                    (colors == FilteringColors.noColor ||
                        e.filteringColors == colors),
              ),
            ),
            data,
          ),
          FilteringMode.gif => (
            _filterTag(
              cells.where(
                (element) =>
                    element.type == PostContentType.gif &&
                    _matchSafeMode(element.rating) &&
                    (colors == FilteringColors.noColor ||
                        element.filteringColors == colors),
              ),
            ),
            data,
          ),
          FilteringMode.video => (
            _filterTag(
              cells.where(
                (element) =>
                    element.type == PostContentType.video &&
                    _matchSafeMode(element.rating) &&
                    (colors == FilteringColors.noColor ||
                        element.filteringColors == colors),
              ),
            ),
            data,
          ),
          FilteringMode() => (
            _filterTag(
              cells.where(
                (e) =>
                    _matchSafeMode(e.rating) &&
                    (colors == FilteringColors.noColor ||
                        e.filteringColors == colors),
              ),
            ),
            data,
          ),
        };
      },
      allowedFilteringModes: const {
        FilteringMode.tag,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.same,
        FilteringMode.fiveStars,
        FilteringMode.fourHalfStars,
        FilteringMode.fourStars,
        FilteringMode.threeHalfStars,
        FilteringMode.threeStars,
        FilteringMode.twoHalfStars,
        FilteringMode.twoStars,
        FilteringMode.oneHalfStars,
        FilteringMode.oneStars,
        FilteringMode.zeroHalfStars,
        FilteringMode.zeroStars,
        FilteringMode.onlyFullStars,
        FilteringMode.onlyHalfStars,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.rating,
        SortingMode.score,
        SortingMode.stars,
        SortingMode.color,
      },
      initialFilteringMode: FilteringMode.tag,
      initialSortingMode: SortingMode.none,
      filteringColors: FilteringColors.noColor,
    );

    filter.clearRefresh();
  }

  @override
  void dispose() {
    searchTextController.dispose();
    searchFocus.dispose();
    safeModeState.dispose();

    filter.destroy();

    super.dispose();
  }

  Iterable<FavoritePost> _filterTag(Iterable<FavoritePost> cells) {
    final searchText = searchTextController.text.trim();
    if (searchText.isEmpty) {
      return cells;
    }

    final tags = searchText.split(" ");

    return cells.where((e) {
      final flags = tags.map((_) => false).toList();

      for (final (index, tagsTo) in tags.indexed) {
        for (final tag in e.tags) {
          if (tag.startsWith(tagsTo)) {
            flags[index] = true;
            break;
          }
        }
      }

      return flags.fold(true, (v, e1) => v & e1);
    });
  }

  bool _matchSafeMode(PostRating rating) => switch (safeModeState.current) {
    SafeMode.normal => rating == PostRating.general,
    SafeMode.relaxed =>
      rating == PostRating.sensitive || rating == PostRating.general,
    SafeMode.explicit =>
      rating == PostRating.questionable || rating == PostRating.explicit,
    SafeMode.none => true,
  };

  Iterable<FavoritePost> _filterStars(
    Iterable<FavoritePost> cells,
    FilteringMode mode,
    FilteringColors? colors,
  ) {
    return cells.where(
      (e) =>
          _matchSafeMode(e.rating) &&
          (mode.toStars == e.stars) &&
          (colors == FilteringColors.noColor || e.filteringColors == colors),
    );
  }

  Iterable<FavoritePost> _collector(
    Map<String, Set<(int, Booru)>>? data,
  ) sync* {
    for (final ids in data!.values) {
      for (final i in ids) {
        yield const FavoritePostSourceService().cache.get((i.$1, i.$2))!;
      }
    }
  }

  (Iterable<T>, dynamic) sameFavorites<T extends PostBase>(
    Iterable<T> cells,
    dynamic data_,
    bool end,
    Iterable<T> Function(Map<String, Set<(int, Booru)>>? data) collect,
    // SafeMode currentSafeMode,
  ) {
    final data = (data_ as Map<String, Set<(int, Booru)>>?) ?? {};

    T? prevCell;
    for (final e in cells) {
      if (!_matchSafeMode(e.rating)) {
        continue;
      }

      if (prevCell != null) {
        if (prevCell.md5 == e.md5) {
          final prev = data[e.md5] ?? {};

          data[e.md5] = {...prev, (e.id, e.booru)};
        }
      }

      prevCell = e;
    }

    if (end) {
      return (collect(data), null);
    }

    return (const [], data);
  }
}

class _FavoritePostsPageState extends State<FavoritePostsPage>
    with SettingsWatcherMixin, FavoritePostsPageLogic {
  late final StreamSubscription<void> _safeModeWatcher;

  late final client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
  late final BooruAPI api;

  late final SourceShellElementState<FavoritePost> status;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(settings.selectedBooru, client);

    status = SourceShellElementState(
      source: filter,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyFavoritedPosts,
      ),
      selectionController: widget.selectionController,
      actions: <SelectionBarAction>[
        if (DownloadManager.available && LocalTagsService.available)
          booru_actions.downloadPost(context, settings.selectedBooru, null),
        booru_actions.favorites(context, showDeleteSnackbar: true),
      ],
      wrapRefresh: null,
    );

    _safeModeWatcher = safeModeState.events.listen((_) {
      filter.clearRefresh();
    });
  }

  @override
  void dispose() {
    status.destroy();
    client.close(force: true);
    _safeModeWatcher.cancel();

    super.dispose();
  }

  void _onPressed(
    BuildContext context,
    Booru booru,
    String t,
    SafeMode? safeMode,
  ) {
    ExitOnPressRoute.maybeExitOf(context);

    searchTextController.text = t;
    filter.filteringMode = FilteringMode.tag;

    if (safeMode != null) {
      safeModeState.setCurrent(safeMode);
    }
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final navBarEvents = NavigationButtonEvents.maybeOf(context);
    final gridSettings = GridSettingsData<FavoritePostsData>();

    return GridPopScope(
      searchTextController: searchTextController,
      filter: filter,
      rootNavigatorPop: widget.rootNavigatorPop,
      child: ShellScope(
        stackInjector: status,
        configWatcher: gridSettings.watch,
        searchBottomWidget: PreferredSize(
          preferredSize: const Size(double.infinity, 80),
          child: _SearchBarWidget(
            api: api,
            filter: filter,
            safeModeState: safeModeState,
            searchTextController: searchTextController,
            searchFocus: searchFocus,
            settingsService: const SettingsService(),
          ),
        ),
        appBar: TitleAppBarType(
          title: l10n.favoritesLabel,
          leading: IconButton(
            onPressed: _openDrawer,
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        settingsButton: ShellSettingsButton.fromWatchable(
          gridSettings,
          header: SafeModeSegment(state: safeModeState),
          buildHideName: false,
          localizeHideNames: (_) => "",
        ),
        elements: [
          ElementPriority(
            FavoritePostsPinnedTagsRow(
              onTagPressed: (str) {
                _onPressed(context, settings.selectedBooru, str, null);
              },
              onTagLongPressed: null,
            ),
            hideOnEmpty: false,
          ),
          ElementPriority(
            ShellElement(
              state: status,
              scrollUpOn: navBarEvents != null
                  ? [(navBarEvents, null)]
                  : const [],
              scrollingState: ScrollingStateSinkProvider.maybeOf(context),
              registerNotifiers: (child) => OnBooruTagPressed(
                onPressed: _onPressed,
                child: filter.inject(status.source.inject(child)),
              ),
              slivers: [
                Builder(
                  builder: (context) {
                    final padding = MediaQuery.systemGestureInsetsOf(context);

                    return SliverPadding(
                      padding: EdgeInsets.only(
                        left: padding.left * 0.2,
                        right: padding.right * 0.2,
                      ),
                      sliver: CurrentGridSettingsLayout<FavoritePost>(
                        source: filter.backingStorage,
                        progress: filter.progress,
                        // gridSeed: gridSeed,
                        selection: status.selection,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritePostsPinnedTagsRow extends StatefulWidget {
  const FavoritePostsPinnedTagsRow({
    super.key,
    required this.onTagPressed,
    required this.onTagLongPressed,
  });

  final StringCallback onTagPressed;
  final StringCallback? onTagLongPressed;

  @override
  State<FavoritePostsPinnedTagsRow> createState() =>
      _FavoritePostsPinnedTagsRowState();
}

class _FavoritePostsPinnedTagsRowState
    extends State<FavoritePostsPinnedTagsRow> {
  final controller = ScrollController();

  late final StreamSubscription<int> _latestCountEvents;
  int _latestCount = 0;
  final List<String> _list = [];

  @override
  void initState() {
    super.initState();

    _latestCountEvents = const TagManagerService().latest.events.listen((e) {
      if (e == _latestCount) {
        return;
      }

      _latestCount = e;
      _seekLastSearchedPinnedTags();
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _latestCountEvents.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _seekLastSearchedPinnedTags();
  }

  void _seekLastSearchedPinnedTags() {
    final pinnedTags = PinnedTagsProvider.of(context);

    final tags = <String>{};

    final latestTags = const TagManagerService().latest.get(25);
    for (final tag in latestTags) {
      if (pinnedTags.map.containsKey(tag.tag)) {
        tags.add(tag.tag);
      }
    }

    tags.addAll(pinnedTags.map.keys);

    _list.clear();
    _list.addAll(tags);
  }

  @override
  Widget build(BuildContext context) {
    PinnedTagsProvider.of(context);

    if (_list.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 52),
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: _list.length,
          itemBuilder: (context, index) {
            final tag = _list[index];

            return Padding(
              padding: const EdgeInsets.all(4),
              child: GestureDetector(
                onLongPress: widget.onTagLongPressed == null
                    ? null
                    : () {
                        widget.onTagLongPressed!(tag);
                      },
                child: ActionChip(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    controller.animateTo(
                      0,
                      duration: Durations.medium3,
                      curve: Easing.standard,
                    );
                    widget.onTagPressed(tag);
                    const TagManagerService().latest.add(tag);
                  },
                  label: Text(tag),
                  avatar: const Icon(Icons.push_pin_rounded),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  const _SearchBarWidget({
    // super.key,
    required this.api,
    required this.filter,
    required this.safeModeState,
    required this.searchTextController,
    required this.searchFocus,
    required this.settingsService,
  });

  final TextEditingController searchTextController;
  final FocusNode searchFocus;

  final BooruAPI api;

  final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  final SafeModeState safeModeState;

  final SettingsService settingsService;

  void launchGrid(BuildContext context) {
    if (searchTextController.text.isNotEmpty) {
      context.openSafeModeDialog((safeMode) {
        BooruRestoredPage.open(
          context,
          booru: api.booru,
          tags: searchTextController.text.trim(),
          overrideSafeMode: safeMode,
          // wrapScaffold: true,
        );
      });
    }
  }

  void clear() {
    searchTextController.text = "";
    filter.clearRefresh();
    searchFocus.unfocus();
  }

  void onChanged(String? _) {
    filter.clearRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    const padding = EdgeInsets.only(right: 16, left: 16, top: 4, bottom: 8);

    return Center(
      child: Padding(
        padding: padding,
        child: SearchBarAutocompleteWrapper(
          search: SearchBarAppBarType(
            onChanged: onChanged,
            complete: api.searchTag,
            textEditingController: searchTextController,
          ),
          searchFocus: searchFocus,
          child: (context, controller, focus, onSubmitted) => SearchBar(
            onSubmitted: (str) {
              onSubmitted();
              filter.clearRefresh();
            },
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            ),
            onTapOutside: (event) => focus.unfocus(),
            elevation: const WidgetStatePropertyAll(0),
            focusNode: focus,
            controller: controller,
            onChanged: onChanged,
            hintText: l10n.filterHint,
            leading: IconButton(
              onPressed: () => launchGrid(context),
              icon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: [
              ChainedFilterIcon(
                filter: filter,
                controller: searchTextController,
                complete: api.searchTag,
                focusNode: searchFocus,
              ),
              IconButton(
                onPressed: clear,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
