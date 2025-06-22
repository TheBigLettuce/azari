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
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/search/booru/booru_search_page.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:dio/dio.dart";
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
  final searchTextController = SearchController();

  late final SafeModeState safeModeState;
  late final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
  final searchFocus = FocusNode();

  String _currentText = "";

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

    searchTextController.addListener(() {
      final newText = searchTextController.text.trim();
      if (newText == _currentText) {
        return;
      }
      _currentText = newText;

      filter.clearRefresh();
    });

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
        appBar: RawAppBarType((context, gridSettingsButton, _) {
          final theme = Theme.of(context);

          return SliverAppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: true,
            actionsPadding: EdgeInsets.zero,
            titleSpacing: 0,
            title: SearchBarAutocompleteWrapper2(
              complete: const TagManagerService().pinned.search,
              textEditingController: searchTextController,
              focusNode: searchFocus,
              child: SearchBar(
                controller: searchTextController,
                focusNode: searchFocus,
                onTapOutside: (event) {
                  if (searchFocus.hasFocus) {
                    searchFocus.unfocus();
                  }
                },
                elevation: const WidgetStatePropertyAll(0),
                hintText: l10n.favoritesLabel,
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 360,
                  maxWidth: 460,
                  minHeight: 34,
                  maxHeight: 34,
                ),
                trailing: [
                  ChainedFilterIcon(
                    filter: filter,
                    controller: searchTextController,
                    complete: api.searchTag,
                    focusNode: searchFocus,
                    iconSize: 20,
                  ),
                  _ClearTextButton(textEditingController: searchTextController),
                ],
              ),
            ),
            leading: IconButton(
              onPressed: _openDrawer,
              icon: const Icon(Icons.menu_rounded),
            ),
            actions: [?gridSettingsButton],
            automaticallyImplyLeading: false,
          );
        }),
        settingsButton: ShellSettingsButton.fromWatchable(
          gridSettings,
          header: SafeModeSegment(state: safeModeState),
          buildHideName: false,
          localizeHideNames: (_) => "",
        ),
        elements: [
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

class _ClearTextButton extends StatefulWidget {
  const _ClearTextButton({super.key, required this.textEditingController});

  final TextEditingController textEditingController;

  @override
  State<_ClearTextButton> createState() => __ClearTextButtonState();
}

class __ClearTextButtonState extends State<_ClearTextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Durations.medium3,
      reverseDuration: Durations.medium1,
      value: 1,
    );

    widget.textEditingController.addListener(_listener);
  }

  @override
  void dispose() {
    controller.dispose();
    widget.textEditingController.removeListener(_listener);

    super.dispose();
  }

  void _listener() {
    if (widget.textEditingController.text.trim().isEmpty) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.view,
      builder: (context, child) => AnimatedSize(
        duration: Durations.medium2,
        curve: Easing.emphasizedDecelerate,
        child: SlideTransition(
          position: AlwaysStoppedAnimation(
            Offset(Easing.emphasizedAccelerate.transform(controller.value), 0),
          ),
          child: Opacity(
            opacity: 1 - controller.value,
            child: controller.value == 1 ? const SizedBox.shrink() : child,
          ),
        ),
      ),
      child: IconButton(
        iconSize: 20,
        onPressed: widget.textEditingController.clear,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _OpenSearchDialogButton extends StatefulWidget {
  const _OpenSearchDialogButton({super.key, required this.controller});

  final SearchController controller;

  @override
  State<_OpenSearchDialogButton> createState() =>
      __OpenSearchDialogButtonState();
}

class __OpenSearchDialogButtonState extends State<_OpenSearchDialogButton> {
  // ignore: use_setters_to_change_properties
  void onTagPressed(String tag) {
    widget.controller.text = tag;
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      viewOnSubmitted: (value) {
        onTagPressed(value);
        widget.controller.closeView(null);
      },
      searchController: widget.controller,
      isFullScreen: false,
      viewConstraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 280,
        maxHeight: 220,
      ),
      builder: (context, controller) => IconButton(
        onPressed: controller.openView,
        icon: const Icon(Icons.search_rounded),
      ),
      viewBuilder: (_) => FavoritePostsPinnedTagsRow(
        onTagPressed: onTagPressed,
        onTagLongPressed: null,
        filterController: widget.controller,
      ),
      suggestionsBuilder: (context, controller) {
        return const [];
      },
    );
  }
}

class FavoritePostsPinnedTagsRow extends StatefulWidget {
  const FavoritePostsPinnedTagsRow({
    super.key,
    required this.onTagPressed,
    required this.onTagLongPressed,
    this.filterController,
  });

  final TextEditingController? filterController;

  final StringCallback onTagPressed;
  final StringCallback? onTagLongPressed;

  @override
  State<FavoritePostsPinnedTagsRow> createState() =>
      _FavoritePostsPinnedTagsRowState();
}

class _FavoritePostsPinnedTagsRowState
    extends State<FavoritePostsPinnedTagsRow> {
  final controller = ScrollController();
  final _filteringEvents = StreamController<String>.broadcast();

  // late final StreamSubscription<int> _latestCountEvents;
  // int _latestCount = 0;
  // final List<String> _list = [];
  late final BooruAPI api;
  late final Dio _apiClient;

  @override
  void initState() {
    super.initState();

    // _latestCountEvents = const TagManagerService().latest.events.listen((e) {
    //   if (e == _latestCount) {
    //     return;
    //   }

    //   _latestCount = e;
    //   // _seekLastSearchedPinnedTags();
    //   setState(() {});
    // });

    final booru = const SettingsService().current.selectedBooru;
    _apiClient = BooruAPI.defaultClientForBooru(booru);
    api = BooruAPI.fromEnum(booru, _apiClient);

    widget.filterController?.addListener(_listener);
  }

  @override
  void dispose() {
    _filteringEvents.close();
    _apiClient.close(force: true);
    controller.dispose();
    // _latestCountEvents.cancel();
    widget.filterController?.removeListener(_listener);

    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  // _seekLastSearchedPinnedTags();
  // }

  void _listener() {
    // _seekLastSearchedPinnedTags();
    if (widget.filterController != null) {
      _filteringEvents.add(widget.filterController!.text.trim());
    }

    setState(() {});
  }

  // void _seekLastSearchedPinnedTags() {
  //   final pinnedTags = PinnedTagsProvider.of(context);

  //   final tags = <String>{};

  //   final latestTags = const TagManagerService().latest.get(25);

  //   final text = widget.filterController?.text.trim();

  //   for (final tag in latestTags) {
  //     if (pinnedTags.map.containsKey(tag.tag)) {
  //       tags.add(tag.tag);
  //     }
  //   }

  //   tags.addAll(pinnedTags.map.keys);

  //   if (text != null && text.isNotEmpty) {
  //     tags.removeWhere((e) => !e.startsWith(text));
  //   }

  //   _list.clear();
  //   _list.addAll(tags);

  //   if (controller.hasClients) {
  //     controller.animateTo(
  //       0,
  //       duration: Durations.medium1,
  //       curve: Easing.standard,
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    PinnedTagsProvider.of(context);

    return SingleChildScrollView(
      child: PinnedTagsPanel(
        sliver: false,
        filteringEvents: _filteringEvents.stream,
        onTagPressed: (tag) {
          controller.animateTo(
            0,
            duration: Durations.medium3,
            curve: Easing.standard,
          );
          widget.onTagPressed(tag);
          const TagManagerService().latest.add(tag);
        },
        api: api,
      ),
    );
  }
}

// class _SearchBarWidget extends StatelessWidget {
//   const _SearchBarWidget({
//     // super.key,
//     required this.api,
//     required this.filter,
//     required this.safeModeState,
//     required this.searchTextController,
//     required this.searchFocus,
//     required this.settingsService,
//   });

//   final TextEditingController searchTextController;
//   final FocusNode searchFocus;

//   final BooruAPI api;

//   final ChainedFilterResourceSource<(int, Booru), FavoritePost> filter;
//   final SafeModeState safeModeState;

//   final SettingsService settingsService;

//   void launchGrid(BuildContext context) {
//     if (searchTextController.text.isNotEmpty) {
//       context.openSafeModeDialog((safeMode) {
//         BooruRestoredPage.open(
//           context,
//           booru: api.booru,
//           tags: searchTextController.text.trim(),
//           overrideSafeMode: safeMode,
//           // wrapScaffold: true,
//         );
//       });
//     }
//   }

//   void clear() {
//     searchTextController.text = "";
//     filter.clearRefresh();
//     searchFocus.unfocus();
//   }

//   void onChanged(String? _) {
//     filter.clearRefresh();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n();
//     final theme = Theme.of(context);

//     const padding = EdgeInsets.only(right: 16, left: 16, top: 4, bottom: 8);

//     return Center(
//       child: Padding(
//         padding: padding,
//         child: SearchBarAutocompleteWrapper(
//           search: SearchBarAppBarType(
//             onChanged: onChanged,
//             complete: api.searchTag,
//             textEditingController: searchTextController,
//           ),
//           searchFocus: searchFocus,
//           child: (context, controller, focus, onSubmitted) => SearchBar(
//             onSubmitted: (str) {
//               onSubmitted();
//               filter.clearRefresh();
//             },
//             backgroundColor: WidgetStatePropertyAll(
//               theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
//             ),
//             onTapOutside: (event) => focus.unfocus(),
//             elevation: const WidgetStatePropertyAll(0),
//             focusNode: focus,
//             controller: controller,
//             onChanged: onChanged,
//             hintText: l10n.filterHint,
//             leading: IconButton(
//               onPressed: () => launchGrid(context),
//               icon: Icon(
//                 Icons.search_rounded,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             trailing: [
//               ChainedFilterIcon(
//                 filter: filter,
//                 controller: searchTextController,
//                 complete: api.searchTag,
//                 focusNode: searchFocus,
//               ),
//               IconButton(
//                 onPressed: clear,
//                 icon: const Icon(Icons.close_rounded),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
