// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/home/booru_restored_page.dart";
import "package:azari/src/ui/material/widgets/radio_dialog.dart";
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
                    safeModeState.current.inLevelPostRating(e.rating) &&
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
                    safeModeState.current.inLevelPostRating(e.rating) &&
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
                    safeModeState.current.inLevelPostRating(e.rating) &&
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
                    safeModeState.current.inLevelPostRating(element.rating) &&
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
                    safeModeState.current.inLevelPostRating(element.rating) &&
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
                    safeModeState.current.inLevelPostRating(e.rating) &&
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

  Iterable<FavoritePost> _filterStars(
    Iterable<FavoritePost> cells,
    FilteringMode mode,
    FilteringColors? colors,
  ) {
    return cells.where(
      (e) =>
          safeModeState.current.inLevelPostRating(e.rating) &&
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
      if (!safeModeState.current.inLevelPostRating(e.rating)) {
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

  late final BooruAPI api;

  late final SourceShellScopeElementState<FavoritePost> status;

  final gridSettings = GridSettingsData<FavoritePostsData>();

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(settings.selectedBooru);

    status = SourceShellScopeElementState(
      source: filter,
      gridSettings: gridSettings,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyFavoritedPosts,
      ),
      selectionController: widget.selectionController,
      actions: makePostActions(
        context,
        settings.selectedBooru,
        showHideButton: false,
      ),
      wrapRefresh: null,
    );

    _safeModeWatcher = safeModeState.events.listen((_) {
      filter.clearRefresh();
    });
  }

  @override
  void dispose() {
    status.destroy();
    api.destroy();
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

  void _openPressedDialog() {
    context.openSafeModeDialog(
      (e) => BooruRestoredPage.open(
        context,
        booru: api.booru,
        tags: searchTextController.text.trim(),
        overrideSafeMode: e,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    final l10n = context.l10n();

    return GridPopScope(
      searchTextController: searchTextController,
      filter: filter,
      rootNavigatorPop: widget.rootNavigatorPop,
      child: ShellScope(
        stackInjector: status,
        appBar: RawAppBarType(
          (context, gridSettingsButton, _) => FavoritePostsSearchSliver(
            textEditingController: searchTextController,
            searchFocus: searchFocus,
            filter: filter,
            hint: l10n.favoritesLabel,
            onSearchTag: _openPressedDialog,
            leadingButton: IconButton(
              onPressed: _openDrawer,
              icon: const Icon(Icons.menu_rounded),
            ),
            gridSettingsButton: gridSettingsButton,
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
            ShellElement(
              state: status,
              gridSettings: gridSettings,
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

class FavoritePostsSearchSliver extends StatelessWidget {
  const FavoritePostsSearchSliver({
    super.key,
    required this.textEditingController,
    required this.searchFocus,
    required this.filter,
    required this.leadingButton,
    required this.onSearchTag,
    this.trailing = const [],
    this.complete = _pinnedTagsComplete,
    this.gridSettingsButton,
    required this.hint,
  });

  final ChainedFilterResourceSource<dynamic, dynamic> filter;

  final String hint;

  final VoidCallback onSearchTag;
  final TextEditingController textEditingController;
  final FocusNode searchFocus;
  final CompleteTagFunc? complete;

  final List<Widget> trailing;
  final Widget? gridSettingsButton;
  final Widget? leadingButton;

  static Future<List<TagData>> _pinnedTagsComplete(String str) =>
      const TagManagerService().pinned.search(str);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final l10n = context.l10n();

    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      centerTitle: true,
      actionsPadding: EdgeInsets.zero,
      titleSpacing: 0,
      title: IconButtonTheme(
        data: const IconButtonThemeData(
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        child: SearchBarAutocompleteWrapper2(
          complete: complete,
          textEditingController: textEditingController,
          focusNode: searchFocus,
          child: SearchBar(
            controller: textEditingController,
            focusNode: searchFocus,
            onTapOutside: (event) {
              if (searchFocus.hasFocus) {
                searchFocus.unfocus();
              }
            },
            elevation: const WidgetStatePropertyAll(0),
            hintText: hint,
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
            ),
            constraints: const BoxConstraints(
              minWidth: 360,
              maxWidth: 460,
              minHeight: 34,
              maxHeight: 34,
            ),
            leading: _SearchButton(
              textEditingController: textEditingController,
              onPressed: onSearchTag,
            ),
            trailing: [
              ...trailing,
              ChainedFilterIcon(
                filter: filter,
                controller: textEditingController,
                focusNode: searchFocus,
                iconSize: 20,
              ),
              ClearTextButton(textEditingController: textEditingController),
            ],
          ),
        ),
      ),
      leading: leadingButton,
      actions: [?gridSettingsButton],
      automaticallyImplyLeading: false,
    );
  }
}

class _SearchButton extends StatefulWidget {
  const _SearchButton({
    // super.key,
    required this.textEditingController,
    required this.onPressed,
  });

  final TextEditingController textEditingController;

  final VoidCallback onPressed;

  @override
  State<_SearchButton> createState() => __SearchButtonState();
}

class __SearchButtonState extends State<_SearchButton>
    with SingleTickerProviderStateMixin, _SlidingAnimationSingle {
  @override
  TextEditingController get textEditingController =>
      widget.textEditingController;

  @override
  bool get animateForward => true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return buildAnimation(
      context,
      IconButton(
        iconSize: 20,
        onPressed: widget.onPressed,
        color: theme.colorScheme.primary,
        icon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

mixin _SlidingAnimationSingle<W extends StatefulWidget> on State<W>
    implements SingleTickerProviderStateMixin<W> {
  late final AnimationController controller;

  TextEditingController get textEditingController;

  bool get animateForward => false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Durations.medium3,
      reverseDuration: Durations.medium1,
      value: 1,
    );

    textEditingController.addListener(_listener);
  }

  @override
  void dispose() {
    controller.dispose();
    textEditingController.removeListener(_listener);

    super.dispose();
  }

  void _listener() {
    if (textEditingController.text.trim().isEmpty) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  Widget buildAnimation(BuildContext context, Widget child) => AnimatedBuilder(
    animation: controller.view,
    builder: (context, child) => AnimatedSize(
      duration: Durations.medium2,
      curve: Easing.emphasizedDecelerate,
      child: SlideTransition(
        position: AlwaysStoppedAnimation(
          animateForward
              ? Offset(
                  -Easing.emphasizedAccelerate.transform(controller.value),
                  0,
                )
              : Offset(
                  Easing.emphasizedAccelerate.transform(controller.value),
                  0,
                ),
        ),
        child: Opacity(
          opacity: 1 - controller.value,
          child: controller.value == 1 ? const SizedBox.shrink() : child,
        ),
      ),
    ),
    child: child,
  );
}

class ClearTextButton extends StatefulWidget {
  const ClearTextButton({super.key, required this.textEditingController});

  final TextEditingController textEditingController;

  @override
  State<ClearTextButton> createState() => _ClearTextButtonState();
}

class _ClearTextButtonState extends State<ClearTextButton>
    with SingleTickerProviderStateMixin, _SlidingAnimationSingle {
  @override
  TextEditingController get textEditingController =>
      widget.textEditingController;

  @override
  Widget build(BuildContext context) {
    return buildAnimation(
      context,
      IconButton(
        iconSize: 20,
        onPressed: widget.textEditingController.clear,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
