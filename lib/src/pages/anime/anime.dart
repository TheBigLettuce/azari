// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/resource_source/source_storage.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/anime/anime_api.dart";
import "package:gallery/src/net/anime/anime_entry.dart";
import "package:gallery/src/net/anime/impl/jikan.dart";
import "package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:gallery/src/pages/anime/search/search_anime.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/dashboard/dashboard_card.dart";
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
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/shimmer_loading_indicator.dart";
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

class _AnimePageState extends State<AnimePage> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  WatchedAnimeEntryService get watchedAnimeEntries => widget.db.watchedAnime;

  late final sourceBacklog = GenericListSource<SavedAnimeEntryData>(
    () => Future.value(savedAnimeEntries.backlogAll),
    watchCount: savedAnimeEntries.watchCount,
  );

  late final sourceWatching = GenericListSource<SavedAnimeEntryData>(
    () => Future.value(savedAnimeEntries.currentlyWatchingAll),
    watchCount: savedAnimeEntries.watchCount,
  );

  late final ChainedFilterResourceSource<int, SavedAnimeEntryData>
      filterBacklog;

  final finishedKey = GlobalKey<__FinishedTabState>();
  final discoverKey = GlobalKey<_DiscoverTabState>();
  final overlayKey = GlobalKey<__MoreOverlayState>();
  final animeSearchKey = GlobalKey<__AnimeSearchState>();

  final _textController = TextEditingController();
  final state = SkeletonState();
  late final StreamSubscription<void> watcherWatched;

  final searchController = SearchController();

  late final source = GenericListSource<AnimeSearchEntry>(
    () => api
        .search(
      "",
      0,
      null,
      null,
      sortOrder: AnimeSortOrder.latest,
    )
        .then((e) {
      int? prev;

      return e.where((e) {
        if (prev == null) {
          prev = e.id;
          return true;
        }

        if (prev == e.id) {
          prev = e.id;
          return false;
        }

        prev = e.id;

        return true;
      }).toList();
    }),
  );

  final client = Dio();
  late final api = Jikan(client);

  late final entry = DiscoverPagingEntry(api);

  String _filteringValue = "";

  late final OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => _MoreOverlay(
      key: overlayKey,
      entry: overlayEntry,
      source: filterBacklog.backingStorage,
    ),
  );

  @override
  void initState() {
    super.initState();

    filterBacklog = ChainedFilterResourceSource.basic(
      sourceBacklog,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    watcherWatched = watchedAnimeEntries.watchAll((_) {
      setState(() {});
    });

    sourceBacklog.clearRefresh();
    sourceWatching.clearRefresh();
  }

  @override
  void dispose() {
    sourceWatching.destroy();
    client.close();
    entry.dispose();
    searchController.dispose();
    source.destroy();

    sourceBacklog.destroy();
    filterBacklog.destroy();

    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
    overlayEntry.dispose();

    state.dispose();
    watcherWatched.cancel();
    _textController.dispose();

    super.dispose();
  }

  void _filter(String? value) {
    setState(() {});

    if (value == null) {
      return;
    }

    // watchingKey.currentState?.doFilter(value);
    finishedKey.currentState?.doFilter(value);
  }

  void _procPop(bool pop, dynamic __) {
    if (overlayEntry.mounted) {
      overlayKey.currentState?.hide();
    } else {
      widget.procPop(pop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _procPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
          leading: Center(
            child: SearchAnchor(
              searchController: searchController,
              builder: (context, controller) {
                return IconButton(
                  onPressed: controller.openView,
                  icon: const Icon(Icons.search_rounded),
                );
              },
              viewOnSubmitted: (value) {
                animeSearchKey.currentState?.performSearch(value);
              },
              viewHintText: l10n.searchHint,
              viewTrailing: [
                _RefresingIcon(
                  controller: searchController,
                  progress: entry.source.progress,
                ),
              ],
              viewBuilder: (_) {
                return _AnimeSearch(
                  key: animeSearchKey,
                  api: api,
                  entry: entry,
                  generateGlue: GlueProvider.generateOf(context),
                );
              },
              suggestionsBuilder: (context, controller) => const [],
            ),
          ),
          centerTitle: true,
          title: Text(l10n.animePage),
          actions: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () {
                Overlay.of(context).insert(overlayEntry);
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadingPanel(
                label: "Newest", // TODO: change
                source: source,
                childSize: _NewAnime.size,
                child: _NewAnime(source: source),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Watching",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                top: 14,
                bottom: 18,
                right: 18,
                left: 18,
              ),
              sliver: _WatchingGrid(
                source: sourceWatching,
                glue: GlueProvider.generateOf(context)(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchingGrid extends StatefulWidget {
  const _WatchingGrid({
    // super.key,
    required this.source,
    required this.glue,
  });

  final GenericListSource<SavedAnimeEntryData> source;
  final SelectionGlue glue;

  @override
  State<_WatchingGrid> createState() => __WatchingGridState();
}

class __WatchingGridState extends State<_WatchingGrid> {
  late final StreamSubscription<int> subsc;
  final focusNode = FocusNode();
  late final selection = GridSelection<SavedAnimeEntryData>(
    const [],
    widget.glue,
    noAppBar: true,
    source: widget.source.backingStorage,
  );

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.four,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    subsc = widget.source.backingStorage.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subsc.cancel();
    focusNode.dispose();
    gridSettings.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      sliver: true,
      watch: gridSettings.watch,
      child: GridExtrasNotifier<SavedAnimeEntryData>(
        data: GridExtrasData(
          selection,
          GridFunctionality(source: widget.source, selectionGlue: widget.glue),
          const GridDescription(
            actions: [],
            gridSeed: 0,
            keybindsDescription: "",
          ),
          focusNode,
        ),
        child: CellProvider(
          getCell: widget.source.forIdxUnsafe,
          child: GridLayout(
            progress: widget.source.progress,
            source: widget.source.backingStorage,
          ),
        ),
      ),
    );
  }
}

class FadingPanel extends StatefulWidget {
  const FadingPanel({
    super.key,
    required this.label,
    this.trailing,
    required this.source,
    required this.childSize,
    this.enableHide = true,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 18),
    required this.child,
  });

  final String label;
  final Widget? trailing;

  final ResourceSource<dynamic, dynamic> source;
  final Size childSize;

  final bool enableHide;

  final EdgeInsets horizontalPadding;

  final Widget child;

  @override
  State<FadingPanel> createState() => _FadingPanelState();
}

class _FadingPanelState extends State<FadingPanel>
    with SingleTickerProviderStateMixin {
  bool shrink = false;

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  final tween = Tween<double>(begin: -1.570796, end: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.8),
    );

    final textSize =
        MediaQuery.textScalerOf(context).scale(textStyle?.fontSize ?? 28);

    final double labelSize = 18 + 18 + 6 + textSize;

    return FadingController(
      source: widget.source,
      childSize: Size(
        widget.childSize.width,
        (shrink ? 0 : widget.childSize.height) + labelSize,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 18) +
                widget.horizontalPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    if (shrink) {
                      controller.forward().then((_) {
                        setState(() {
                          shrink = false;
                        });
                      });
                    } else {
                      controller.reverse().then((_) {
                        setState(() {
                          shrink = true;
                        });
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: !widget.enableHide
                        ? Text(
                            widget.label,
                            style: textStyle,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                style: textStyle,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: AnimatedBuilder(
                                  animation: controller.view,
                                  builder: (context, _) {
                                    return Transform.rotate(
                                      angle: tween.transform(
                                        Easing.standard
                                            .transform(controller.value),
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 24,
                                        color:
                                            textStyle?.color?.withOpacity(0.9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
          Animate(
            value: 1,
            autoPlay: false,
            controller: controller,
            effects: const [
              FadeEffect(
                begin: 0,
                end: 1,
              ),
            ],
            child: shrink ? const SizedBox.shrink() : widget.child,
          ),
        ],
      ),
    );
  }
}

class ShimmerPlaceholdersHorizontal extends StatefulWidget {
  const ShimmerPlaceholdersHorizontal({
    super.key,
    required this.childSize,
    this.cornerRadius = 15,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
  });

  final Size childSize;
  final double cornerRadius;
  final EdgeInsets childPadding;
  final EdgeInsets padding;

  @override
  State<ShimmerPlaceholdersHorizontal> createState() =>
      _ShimmerPlaceholdersHorizontalState();
}

class _ShimmerPlaceholdersHorizontalState
    extends State<ShimmerPlaceholdersHorizontal> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.childSize.height,
      child: ListView.builder(
        itemCount: 10,
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return SizedBox(
            key: ValueKey(index),
            width: widget.childSize.width,
            child: Padding(
              padding: widget.childPadding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.cornerRadius),
                child: const ShimmerLoadingIndicator(
                  delay: Duration(milliseconds: 900),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewAnime extends StatelessWidget {
  const _NewAnime({
    // super.key,
    required this.source,
  });

  final GenericListSource<AnimeSearchEntry> source;

  static const size = Size(180 / 1.5, 180);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: WrapFutureRestartable<int>(
        placeholder: const ShimmerPlaceholdersHorizontal(
          childSize: size,
          padding: listPadding,
        ),
        newStatus: () {
          if (source.backingStorage.isNotEmpty) {
            return Future.value(source.backingStorage.count);
          }

          return source.clearRefresh();
        },
        builder: (context, _) {
          return ListView.builder(
            padding: listPadding,
            scrollDirection: Axis.horizontal,
            itemCount: source.backingStorage.count,
            itemBuilder: (context, i) {
              final cell = source.backingStorage[i];

              return InkWell(
                onTap: () {
                  cell.openInfoPage(context);
                },
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: size.width,
                  child: GridCell(cell: cell, hideTitle: false),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FadingController extends StatefulWidget {
  const FadingController({
    super.key,
    required this.source,
    required this.childSize,
    required this.child,
  });

  final ResourceSource<dynamic, dynamic> source;

  final Size childSize;
  final Widget child;

  @override
  State<FadingController> createState() => _FadingControllerState();
}

class _FadingControllerState extends State<FadingController>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<bool> subscription;
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, value: 1);
    subscription = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      value: 1,
      autoPlay: false,
      target: !widget.source.progress.inRefreshing &&
              widget.source.backingStorage.isEmpty
          ? 0
          : 1,
      effects: const [
        FadeEffect(
          curve: Easing.standardDecelerate,
          duration: Durations.medium1,
          begin: 0,
          end: 1,
        ),
      ],
      controller: controller,
      child: AnimatedSize(
        alignment: Alignment.topLeft,
        duration: Durations.medium1,
        curve: Easing.standard,
        reverseDuration: Durations.short3,
        child: SizedBox(
          height: !widget.source.progress.inRefreshing &&
                  widget.source.backingStorage.isEmpty
              ? 0
              : widget.childSize.height,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RefresingIcon extends StatefulWidget {
  const _RefresingIcon({
    // super.key,
    required this.progress,
    required this.controller,
  });

  final RefreshingProgress progress;
  final SearchController controller;

  @override
  State<_RefresingIcon> createState() => __RefresingIconState();
}

class __RefresingIconState extends State<_RefresingIcon> {
  late final StreamSubscription<bool> subscription;

  @override
  void initState() {
    super.initState();

    subscription = widget.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.progress.inRefreshing
        ? const Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : IconButton(
            onPressed: widget.controller.clear,
            icon: const Icon(Icons.close_rounded),
          );
  }
}

class _AnimeSearch extends StatefulWidget {
  const _AnimeSearch({
    super.key,
    required this.api,
    required this.generateGlue,
    required this.entry,
  });

  final AnimeAPI api;
  final GenerateGlueFnc generateGlue;
  final DiscoverPagingEntry entry;

  @override
  State<_AnimeSearch> createState() => __AnimeSearchState();
}

class __AnimeSearchState extends State<_AnimeSearch> {
  final key = GlobalKey<_DiscoverTabState>();

  void performSearch(String search) {
    key.currentState?.search(search);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage(
      addScaffold: true,
      child: DiscoverTab(
        key: key,
        api: widget.api,
        db: DatabaseConnectionNotifier.of(context),
        entry: widget.entry,
      ),
    );
  }
}

class _MoreOverlay extends StatefulWidget {
  const _MoreOverlay({super.key, required this.entry, required this.source});

  final OverlayEntry entry;
  final ReadOnlyStorage<int, SavedAnimeEntryData> source;

  @override
  State<_MoreOverlay> createState() => __MoreOverlayState();
}

class __MoreOverlayState extends State<_MoreOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void hide() {
    if (widget.entry.mounted) {
      _hideOverlayAnimate(controller, widget.entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final height = MediaQuery.sizeOf(context).height;

    return Material(
      type: MaterialType.transparency,
      child: _ColorDecoration(
        controller: controller,
        theme: theme,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _hideOverlayAnimate(controller, widget.entry),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints.loose(
                  Size.fromHeight(height * 0.5 >= 200 ? height * 0.5 : height),
                ),
                child: Animate(
                  controller: controller,
                  effects: const [
                    SlideEffect(
                      duration: Durations.long2,
                      curve: Easing.standardDecelerate,
                      begin: Offset(0, -1),
                      end: Offset.zero,
                    ),
                    FadeEffect(
                      duration: Durations.long2,
                      curve: Easing.standard,
                      begin: 0,
                      end: 1,
                    ),
                  ],
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.viewPaddingOf(context).top,
                          ),
                          child: _MoreOverlayBody(
                            entry: widget.entry,
                            controller: controller,
                            source: widget.source,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreOverlayBody extends StatelessWidget {
  const _MoreOverlayBody({
    // super.key,
    required this.entry,
    required this.controller,
    required this.source,
  });

  final OverlayEntry entry;
  final AnimationController controller;
  final ReadOnlyStorage<int, SavedAnimeEntryData> source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.backlogLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
                IconButton(
                  onPressed: () => _hideOverlayAnimate(controller, entry),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: source.isEmpty
                ? Center(
                    child: Text(
                      "No elements", // TODO: change
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: source.count,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      crossAxisCount: 2,
                    ),
                    itemBuilder: (context, i) {
                      final cell = source[i];

                      return GestureDetector(
                        onTap: () {
                          _hideOverlayAnimate(controller, entry).then((e) {
                            if (context.mounted) {
                              cell.openInfoPage(context);
                            }
                          });
                        },
                        child: GridCell(cell: cell, hideTitle: false),
                      );
                    },
                  ),
          ),
          const Padding(padding: EdgeInsets.only(top: 16)),
        ],
      ),
    );
  }
}

class _ColorDecoration extends StatefulWidget {
  const _ColorDecoration({
    // super.key,
    required this.controller,
    required this.theme,
    required this.child,
  });

  final AnimationController controller;

  final ThemeData theme;

  final Widget child;

  @override
  State<_ColorDecoration> createState() => __ColorDecorationState();
}

class __ColorDecorationState extends State<_ColorDecoration> {
  late final _colorTween = ColorTween(
    begin: widget.theme.colorScheme.scrim.withOpacity(0),
    end: widget.theme.colorScheme.scrim.withOpacity(0.5),
  );

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);

    super.dispose();
  }

  void listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _colorTween.transform(
        Easing.standardDecelerate.transform(widget.controller.value),
      )!,
      child: widget.child,
    );
  }
}

Future<void> _hideOverlayAnimate(
  AnimationController controller,
  OverlayEntry entry,
) {
  return controller
      .animateBack(0, duration: Durations.medium3)
      .then((e) => entry.remove());
}
