// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/impl/jikan.dart";
import "package:azari/src/pages/anime/search_page.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:logging/logging.dart";

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

extension NewestAnimeGlobalProgress on GlobalProgressTab {
  ValueNotifier<Future<void>?> newestAnime() =>
      get("newestAnime", () => ValueNotifier(null));
}

extension CurrentSeasonAnimeGlobalProgress on GlobalProgressTab {
  ValueNotifier<Future<void>?> currentSeasonAnime() =>
      get("currentSeasonAnime", () => ValueNotifier(null));
}

class _AnimePageState extends State<AnimePage> {
  SavedAnimeEntriesService get savedAnimeEntries => widget.db.savedAnimeEntries;
  AnimeListsService get animeLists => widget.db.animeLists;

  late final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> filterWatching;

  late final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> filterBacklog;

  late final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> filterWatched;

  final overlayKey = GlobalKey<__MoreOverlayState>();

  final _textController = TextEditingController();
  final state = SkeletonState();

  final searchController = SearchController();

  ValueNotifier<Future<void>?>? refreshingStatusUpcoming;
  ValueNotifier<Future<void>?>? refreshingStatusCurrentSeason;

  final client = Dio();
  late final api = Jikan(client);

  final String _filteringValue = "";

  late final OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => _MoreOverlay(
      key: overlayKey,
      entry: overlayEntry,
      source: filterWatched.backingStorage,
    ),
  );

  @override
  void initState() {
    super.initState();

    filterWatching = ChainedFilterResourceSource.basic(
      savedAnimeEntries.watching,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    filterBacklog = ChainedFilterResourceSource.basic(
      savedAnimeEntries.backlog,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    filterWatched = ChainedFilterResourceSource.basic(
      savedAnimeEntries.watched,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) =>
          (cells.where((e) => e.title.contains(_filteringValue)), null),
    );

    filterWatching.clearRefresh();
    filterBacklog.clearRefresh();
    filterWatched.clearRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tab = GlobalProgressTab.maybeOf(context);

    final c = tab?.currentSeasonAnime();
    final r = tab?.newestAnime();

    if (refreshingStatusCurrentSeason == null && c != null) {
      refreshingStatusCurrentSeason = c;
      final data = animeLists.currentSeason;
      if (data.$2.isEmpty ||
          DateTime.now().isAfter(data.$1.add(const Duration(days: 5)))) {
        refreshingStatusCurrentSeason!.value = Future(() async {
          final client = Dio();
          late final api = Jikan(client);

          try {
            final result = await api.seasonNow(0) + await api.seasonNow(1);
            result.sort((e1, e2) => e2.score.compareTo(e1.score));

            int? prev;

            final f = result.where((e) {
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

            animeLists.setCurrentSeason(f);
          } catch (e, trace) {
            Logger.root.warning("newestAnime", e, trace);
          } finally {
            client.close(force: true);
            refreshingStatusCurrentSeason!.value = null;
          }
        });
      }
    }

    if (refreshingStatusUpcoming == null && r != null) {
      refreshingStatusUpcoming = r;
      final data = animeLists.upcoming;
      if (data.$2.isEmpty ||
          DateTime.now().isAfter(data.$1.add(const Duration(days: 1)))) {
        refreshingStatusUpcoming!.value = Future(() async {
          final client = Dio();
          late final api = Jikan(client);

          try {
            final result = await api.search(
              "",
              0,
              null,
              AnimeSafeMode.safe,
              sortOrder: AnimeSortOrder.upcoming,
            );

            int? prev;

            final f = result.where((e) {
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

            animeLists.setUpcoming(f);
          } catch (e, trace) {
            Logger.root.warning("currentSeasonAnime", e, trace);
          } finally {
            client.close(force: true);
            refreshingStatusUpcoming!.value = null;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    client.close();
    searchController.dispose();

    filterWatched.destroy();
    filterBacklog.destroy();
    filterWatching.destroy();

    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
    overlayEntry.dispose();

    state.dispose();
    _textController.dispose();

    super.dispose();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _procPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu_rounded),
          ),
          // leading: const SizedBox.shrink(),
          centerTitle: true,
          title: Center(
            child: IconButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute(
                    builder: (context) =>
                        AnimeSearchPage(db: widget.db, api: api),
                  ),
                );
                // SearchAnimePage.launchAnimeApi(context, (c) => Jikan(c));
              },
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () {
                Overlay.of(context, rootOverlay: true).insert(overlayEntry);
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            if (refreshingStatusUpcoming != null)
              _AnimeListHolder(
                label: l10n.upcomingAnime,
                current: () => animeLists.upcoming.$2,
                childSize: _NewAnime.size,
                notifier: refreshingStatusUpcoming!,
                child: (source) => _NewAnime(source: source),
              ),
            if (refreshingStatusCurrentSeason != null)
              _AnimeListHolder(
                label: l10n.currentSeason,
                current: () => animeLists.currentSeason.$2,
                childSize: _CurrentSeasonAnime.size,
                notifier: refreshingStatusCurrentSeason!,
                child: (source) => _CurrentSeasonAnime(source: source),
              ),
            WatchingAnimePanel(
              source: filterWatching,
              sourceBacklog: filterBacklog,
              // watchingBacklogChange: watchingBacklogChange.stream,
            ),
            Builder(
              builder: (context) => SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchingAnimePanel extends StatefulWidget {
  const WatchingAnimePanel({
    super.key,
    required this.source,
    required this.sourceBacklog,
  });

  final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> source;

  final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> sourceBacklog;

  @override
  State<WatchingAnimePanel> createState() => _WatchingAnimePanelState();
}

class _WatchingAnimePanelState extends State<WatchingAnimePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  final sourceChange = StreamController<bool>.broadcast();

  bool showWatching = true;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, value: 1, duration: Durations.medium1);
  }

  @override
  void dispose() {
    sourceChange.close();
    controller.dispose();

    super.dispose();
  }

  final tween = Tween<double>(begin: 0, end: 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = SliverPadding(
      padding: const EdgeInsets.only(
        // top: 14,
        bottom: 18,
        right: 18,
        left: 18,
      ),
      sliver: _WatchingGrid(
        source: showWatching ? widget.source : widget.sourceBacklog,
        glue: GlueProvider.generateOf(context)(),
        sourceBacklog: widget.sourceBacklog,
        sourceChange: sourceChange.stream,
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18),
            label: showWatching ? l10n.watchingLabel : l10n.backlogLabel,
            icon: Icons.cached_rounded,
            onPressed: () {
              controller.reverse().then((_) {
                if (showWatching) {
                  showWatching = false;
                } else {
                  showWatching = true;
                }

                setState(() {});

                sourceChange.add(showWatching);

                controller.forward();
              });
            },
          ),
        ),
        AnimatedBuilder(
          animation: controller.view,
          builder: (context, child) => SliverFadeTransition(
            opacity: CurvedAnimation(
              parent: controller,
              curve: Easing.standard,
            ),
            sliver: child,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _AnimeListHolder extends StatefulWidget {
  const _AnimeListHolder({
    // super.key,
    required this.notifier,
    required this.current,
    required this.label,
    required this.childSize,
    required this.child,
  });

  final ValueNotifier<Future<void>?> notifier;

  final List<AnimeEntryData> Function() current;

  final String label;
  final Size childSize;

  final Widget Function(GenericListSource<AnimeEntryData> source) child;

  @override
  State<_AnimeListHolder> createState() => _AnimeListHolderState();
}

class _AnimeListHolderState extends State<_AnimeListHolder> {
  late final listSource = GenericListSource<AnimeEntryData>(
    () => Future.value(widget.current()),
  );

  @override
  void initState() {
    super.initState();

    listSource.backingStorage.addAll(widget.current(), true);
    listSource.progress.inRefreshing = widget.notifier.value != null;
    widget.notifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    listSource.destroy();

    super.dispose();
  }

  void _listener() {
    listSource.progress.inRefreshing = widget.notifier.value != null;
    listSource.clearRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadingPanel(
        label: widget.label,
        source: listSource,
        childSize: widget.childSize,
        child: widget.child(listSource),
        // _NewAnime(source: newestSource),
      ),
    );
  }
}

class _WatchingGrid extends StatefulWidget {
  const _WatchingGrid({
    // super.key,
    required this.source,
    required this.glue,
    required this.sourceBacklog,
    required this.sourceChange,
  });

  final ChainedFilterResourceSource<dynamic, AnimeEntryData> source;
  final ChainedFilterResourceSource<(int id, AnimeMetadata site),
      AnimeEntryData> sourceBacklog;
  final SelectionGlue glue;

  final Stream<bool> sourceChange;

  @override
  State<_WatchingGrid> createState() => __WatchingGridState();
}

class __WatchingGridState extends State<_WatchingGrid> {
  late final StreamSubscription<int> subscWatching;
  late final StreamSubscription<int> subscBacklog;
  late final StreamSubscription<void> sourceChangeSubsc;

  final focusNode = FocusNode();
  late final selection = GridSelection<AnimeEntryData>(
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

  bool showWatching = true;

  @override
  void initState() {
    super.initState();

    subscBacklog = widget.sourceBacklog.backingStorage.watch((_) {
      setState(() {});
    });

    subscWatching = widget.source.backingStorage.watch((_) {
      setState(() {});
    });

    sourceChangeSubsc = widget.sourceChange.listen((_) {
      if (showWatching) {
        showWatching = false;
      } else {
        showWatching = true;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    sourceChangeSubsc.cancel();
    subscWatching.cancel();
    subscBacklog.cancel();
    focusNode.dispose();
    gridSettings.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = showWatching ? widget.source : widget.sourceBacklog;
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      sliver: true,
      watch: gridSettings.watch,
      child: GridExtrasNotifier<AnimeEntryData>(
        data: GridExtrasData(
          selection,
          GridFunctionality(source: source, selectionGlue: widget.glue),
          const GridDescription(
            actions: [],
            gridSeed: 0,
          ),
          focusNode,
        ),
        child: CellProvider(
          getCell: source.forIdxUnsafe,
          child: GridLayout(
            progress: source.progress,
            source: source.backingStorage,
            buildEmpty: (error) => Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 2),
              child: Text(l10n.emptyValue),
            ),
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
  final (IconData, void Function())? trailing;

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
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
          FadingPanelLabel(
            horizontalPadding: widget.horizontalPadding,
            label: widget.label,
            controller: controller,
            onPressed: widget.enableHide
                ? () {
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
                  }
                : null,
            icon: widget.enableHide ? Icons.keyboard_arrow_down_rounded : null,
            trailing: widget.trailing,
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

class FadingPanelLabel extends StatelessWidget {
  const FadingPanelLabel({
    super.key,
    required this.horizontalPadding,
    this.onPressed,
    required this.label,
    this.icon,
    this.controller,
    this.trailing,
    this.tween,
  });

  final EdgeInsets horizontalPadding;

  final void Function()? onPressed;

  final String label;
  final IconData? icon;

  final AnimationController? controller;

  final (IconData, void Function())? trailing;

  final Tween<double>? tween;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    final t = tween ?? Tween<double>(begin: -1.570796, end: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18) + horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: icon == null
                  ? Text(
                      label,
                      style: textStyle,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: textStyle,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: controller == null
                              ? Icon(
                                  icon,
                                  size: 24,
                                  color:
                                      textStyle?.color?.withValues(alpha: 0.9),
                                )
                              : AnimatedBuilder(
                                  animation: controller!.view,
                                  builder: (context, _) {
                                    return Transform.rotate(
                                      angle: t.transform(
                                        Easing.standard
                                            .transform(controller!.value),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 24,
                                        color: textStyle?.color
                                            ?.withValues(alpha: 0.9),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ),
          if (trailing != null)
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: trailing!.$2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      trailing!.$1,
                      size: 24,
                      color: textStyle?.color?.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
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

class ShimmerPlaceholdersChips extends StatelessWidget {
  const ShimmerPlaceholdersChips({
    super.key,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
  });

  final EdgeInsets childPadding;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: padding,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return SizedBox(
          key: ValueKey(index),
          height: 42,
          child: Padding(
            padding: childPadding,
            child: const ActionChip(
              labelPadding: EdgeInsets.zero,
              // padding: EdgeInsets.zero,
              label: SizedBox(
                height: 42 / 2,
                width: 58,
                child: ShimmerLoadingIndicator(
                  delay: Duration(milliseconds: 900),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerPlaceholderCarousel extends StatelessWidget {
  const ShimmerPlaceholderCarousel({
    super.key,
    required this.childSize,
    this.cornerRadius = 15,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
    this.weights = const [3, 2, 1],
  });

  final Size childSize;
  final double cornerRadius;
  final EdgeInsets childPadding;
  final EdgeInsets padding;

  final List<int> weights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: childSize.height,
      child: Padding(
        padding: padding,
        child: CarouselView.weighted(
          padding: childPadding,
          flexWeights: weights,
          itemSnapping: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          children: List<Widget>.generate(10, (index) {
            return ShimmerLoadingIndicator(
              key: ValueKey(index),
              delay: const Duration(milliseconds: 900),
            );
          }),
        ),
      ),
    );
  }
}

class _NewAnime extends StatefulWidget {
  const _NewAnime({
    // super.key,
    required this.source,
  });

  final GenericListSource<AnimeEntryData> source;

  static const size = Size(180 / 1.5, 180);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18);

  @override
  State<_NewAnime> createState() => __NewAnimeState();
}

class __NewAnimeState extends State<_NewAnime> {
  GenericListSource<AnimeEntryData> get source => widget.source;

  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _NewAnime.size.height,
      child: widget.source.progress.inRefreshing
          ? const ShimmerPlaceholdersHorizontal(
              childSize: _NewAnime.size,
              padding: _NewAnime.listPadding,
            )
          : ListView.builder(
              padding: _NewAnime.listPadding,
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
                    width: _NewAnime.size.width,
                    child: GridCell(cell: cell, hideTitle: false),
                  ),
                );
              },
            ).animate().fadeIn(),
    );
  }
}

class _CurrentSeasonAnime extends StatefulWidget {
  const _CurrentSeasonAnime({
    // super.key,
    required this.source,
  });

  final GenericListSource<AnimeEntryData> source;

  static const size = Size(220 / 1.3, 220);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18);

  @override
  State<_CurrentSeasonAnime> createState() => __CurrentSeasonAnimeState();
}

class __CurrentSeasonAnimeState extends State<_CurrentSeasonAnime> {
  GenericListSource<AnimeEntryData> get source => widget.source;

  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _CurrentSeasonAnime.size.height,
      child: widget.source.progress.inRefreshing
          ? const ShimmerPlaceholderCarousel(
              childSize: _CurrentSeasonAnime.size,
              padding: _CurrentSeasonAnime.listPadding,
              weights: [4, 2, 2, 2],
            )
          : Padding(
              padding: _CurrentSeasonAnime.listPadding,
              child: CarouselView.weighted(
                padding: EdgeInsets.zero,
                flexWeights: const [4, 2, 2, 2],
                itemSnapping: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onTap: (idx) => source.forIdxUnsafe(idx).openInfoPage(context),
                children: source.backingStorage
                    .map((cell) => GridCell(cell: cell, hideTitle: false))
                    .toList(),
              ),
            ).animate().fadeIn(),
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

class _MoreOverlay extends StatefulWidget {
  const _MoreOverlay({super.key, required this.entry, required this.source});

  final OverlayEntry entry;
  final ReadOnlyStorage<int, AnimeEntryData> source;

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
  final ReadOnlyStorage<int, AnimeEntryData> source;

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
                  l10n.cardWatched,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
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
                      l10n.emptyValue,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    begin: widget.theme.colorScheme.scrim.withValues(alpha: 0),
    end: widget.theme.colorScheme.scrim.withValues(alpha: 0.5),
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
