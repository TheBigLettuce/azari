// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:ui";

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/settings/settings_label.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({
    super.key,
    required this.pagingRegistry,
    required this.saveSelectedPage,
    required this.selectionController,
  });

  final void Function(String? e) saveSelectedPage;
  final PagingStateRegistry pagingRegistry;

  final SelectionController selectionController;

  static bool hasServicesRequired() => GridBookmarkService.available;

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> with SettingsWatcherMixin {
  final PageController pageController = PageController(viewportFraction: 0.8);
  final StreamController<void> _updates = StreamController.broadcast();
  late final StreamSubscription<void> _updatesEvents;

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  String? currentPage;

  late final _ClusteredSource source;

  @override
  void initState() {
    super.initState();

    _updatesEvents = _updates.stream.listen((_) {
      setState(() {});
    });

    const gridBookmarks = GridBookmarkService();

    source = _ClusteredSource(
      gridBookmarks,
      const SettingsService(),
      _updates.sink,
      widget.selectionController,
    )..refresh(gridBookmarks);
  }

  @override
  void dispose() {
    _updatesEvents.cancel();
    source.dispose();
    pageController.dispose();
    gridSettings.cancel();
    _updates.close();

    super.dispose();
  }

  void launchGrid(BuildContext context, GridBookmark e) {
    currentPage = e.name;

    BooruRestoredPage.open(
      context,
      booru: e.booru,
      tags: e.tags,
      name: e.name,
      pagingRegistry: widget.pagingRegistry,
      saveSelectedPage: widget.saveSelectedPage,
    ).whenComplete(() => currentPage = null);
  }

  @override
  Widget build(BuildContext context) {
    final navigationEvents = NavigationButtonEvents.maybeOf(context);
    final theme = Theme.of(context);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        final l10n = context.l10n();

        return [
          SliverAppBar(
            title: Text(l10n.bookmarksPageName),
            // forceElevated: true,
          ),
        ];
      },
      body: PageView(
        padEnds: false,
        controller: pageController,
        children: source._sources.entries.indexed.map((e) {
          final state = e.$2.value.state;
          final source = e.$2.value.source;
          final booru = e.$2.key;

          return DecoratedBox(
            decoration: e.$1.isOdd
                ? BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow.withValues(
                      alpha: 0.4,
                    ),
                  )
                : BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow.withValues(
                      alpha: 0.2,
                    ),
                  ),
            child: ShellScope(
              key: ValueKey(booru),
              stackInjector: state,
              configWatcher: gridSettings.watch,
              showScrollbar: false,
              elements: [
                ElementPriority(
                  SliverPadding(
                    padding: e.$1.isOdd
                        ? const EdgeInsets.only(top: 24)
                        : EdgeInsets.zero,
                    sliver: ShellElement(
                      scrollingState: ScrollingStateSinkProvider.maybeOf(
                        context,
                      ),
                      state: state,
                      scrollUpOn: navigationEvents != null
                          ? [(navigationEvents, () => currentPage == null)]
                          : const [],
                      slivers: [
                        // SliverPadding(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 20,
                        //     vertical: 18,
                        //   ),
                        //   sliver: SliverToBoxAdapter(
                        //     child: Text(
                        //       booru.string,
                        //       style: theme.textTheme.titleLarge?.copyWith(
                        //         color: theme.colorScheme.onSurface
                        //             .withValues(alpha: 0.9),
                        //       ),
                        //       textAlign: TextAlign.right,
                        //     ),
                        //   ),
                        // ),
                        _BookmarkBody(
                          source: source.backingStorage,
                          openBookmark: launchGrid,
                          progress: source.progress,
                          gridBookmarks: const GridBookmarkService(),
                          gridDbs: GridDbService.safe(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ClusteredSource {
  _ClusteredSource(
    GridBookmarkService service,
    SettingsService settings,
    this.updateSink,
    this.selectionController,
  ) {
    events = service.watch((_) {
      refresh(service);
    });

    final current = settings.current.selectedBooru;
    _sources[current] = _makeSource(current);

    for (final e in Booru.values.where((e) => e != current)) {
      _sources[e] = _makeSource(e);
    }
  }

  final SelectionController selectionController;
  final Sink<void> updateSink;

  late final StreamSubscription<int> events;

  final _sources =
      <
        Booru,
        ({
          GenericListSource<GridBookmark> source,
          SourceShellElementState<GridBookmark> state,
        })
      >{};

  Iterable<ResourceSource<int, GridBookmark>> get sources =>
      _sources.values.map((e) => e.source);
  Iterable<SourceShellElementState<GridBookmark>> get statuses =>
      _sources.values.map((e) => e.state);

  void refresh(GridBookmarkService service) {
    for (final e in _sources.values) {
      e.source.backingStorage.clear(true);
    }

    for (final e in service.all) {
      final source = _sources.putIfAbsent(e.booru, () => _makeSource(e.booru));

      source.source.backingStorage.add(e, true);
    }

    for (final e in _sources.values) {
      e.source.backingStorage.addAll([]);
    }

    updateSink.add(null);
  }

  ({
    GenericListSource<GridBookmark> source,
    SourceShellElementState<GridBookmark> state,
  })
  _makeSource(Booru booru) {
    final source = GenericListSource<GridBookmark>(null);

    return (
      source: source,
      state: SourceShellElementState(
        source: source,
        selectionController: selectionController,
        actions: const [],
        wrapRefresh: null,
        onEmpty: SourceOnEmptyInterface(
          source,
          (context) => "No ${booru.string} bookmarks.", // TODO: change
        ),
      ),
    );
  }

  void dispose() {
    events.cancel();
    for (final e in _sources.values) {
      e.source.destroy();
      e.state.destroy();
    }
  }
}

class _BookmarkBody extends StatefulWidget {
  const _BookmarkBody({
    // super.key,
    required this.source,
    required this.openBookmark,
    required this.progress,
    required this.gridBookmarks,
    required this.gridDbs,
  });

  final ReadOnlyStorage<int, GridBookmark> source;
  final RefreshingProgress progress;

  final void Function(BuildContext context, GridBookmark e) openBookmark;

  final GridBookmarkService gridBookmarks;
  final GridDbService? gridDbs;

  @override
  State<_BookmarkBody> createState() => __BookmarkBodyState();
}

class __BookmarkBodyState extends State<_BookmarkBody> {
  GridDbService? get gridDbs => widget.gridDbs;
  GridBookmarkService get gridBookmarks => widget.gridBookmarks;

  late final StreamSubscription<void> sourceEvents;

  @override
  void initState() {
    super.initState();

    sourceEvents = widget.source.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    sourceEvents.cancel();

    super.dispose();
  }

  List<Widget> makeList(BuildContext context, ThemeData theme) {
    final timeNow = DateTime.now();
    final list = <Widget>[];

    final titleStyle = theme.textTheme.titleSmall!.copyWith(
      color: theme.colorScheme.secondary,
    );

    ({int day, int month, int year})? time;

    for (final e in widget.source) {
      final addTime =
          time == null ||
          time != (day: e.time.day, month: e.time.month, year: e.time.year);
      if (addTime) {
        time = (day: e.time.day, month: e.time.month, year: e.time.year);

        list.add(TimeLabel(time, titleStyle, timeNow));
      }

      list.add(
        Padding(
          padding: EdgeInsets.only(top: addTime ? 0 : 12, left: 12, right: 16),
          child: _BookmarkListTileCarousel(
            openBookmark: widget.openBookmark,
            key: ValueKey(e.name),
            state: e,
            title: e.tags,
            subtitle: e.booru.string,
            gridBookmarks: gridBookmarks,
            gridDbs: gridDbs,
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 8),
      sliver: SliverList.list(children: makeList(context, theme)),
    );
  }
}

class TimeLabel extends StatelessWidget {
  const TimeLabel(
    this.time,
    this.titleStyle,
    this.now, {
    super.key,
    this.removePadding = false,
  });

  final bool removePadding;

  final ({int day, int month, int year}) time;

  final TextStyle titleStyle;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (time == (year: now.day, month: now.month, day: now.year)) {
      return SettingsLabel(
        l10n.todayLabel,
        titleStyle,
        removePadding: removePadding,
      );
    } else {
      return SettingsLabel(
        l10n.dateSimple(DateTime(time.year, time.month, time.day)),
        titleStyle,
        removePadding: removePadding,
      );
    }
  }
}

class _BookmarkListTileCarousel extends StatefulWidget {
  const _BookmarkListTileCarousel({
    super.key,
    required this.subtitle,
    required this.title,
    required this.state,
    required this.openBookmark,
    required this.gridBookmarks,
    required this.gridDbs,
  });

  final String title;
  final String subtitle;

  final GridBookmark state;

  final GridBookmarkService gridBookmarks;
  final GridDbService? gridDbs;

  final void Function(BuildContext context, GridBookmark e) openBookmark;

  @override
  State<_BookmarkListTileCarousel> createState() =>
      __BookmarkListTileStateCarousel();
}

class __BookmarkListTileStateCarousel extends State<_BookmarkListTileCarousel>
    with SingleTickerProviderStateMixin {
  GridDbService? get gridDbs => widget.gridDbs;
  GridBookmarkService get gridBookmarks => widget.gridBookmarks;

  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).longestSide * 0.2;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n();

    return Animate(
      autoPlay: false,
      value: 0,
      controller: animationController,
      effects: const [
        FadeEffect(
          delay: Duration(milliseconds: 80),
          duration: Durations.medium4,
          curve: Easing.standard,
          begin: 1,
          end: 0,
        ),
        SlideEffect(
          duration: Durations.medium4,
          curve: Easing.emphasizedDecelerate,
          begin: Offset.zero,
          end: Offset(1, 0),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200),
        child: GestureDetector(
          onTap: () {
            widget.openBookmark(context, widget.state);
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            fit: StackFit.passthrough,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.25,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: SizedBox(height: size, width: double.infinity),
              ),
              Column(
                children: [
                  SizedBox(
                    height: size,
                    child: ClipPath.shape(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Stack(
                        children: [
                          CarouselView.weighted(
                            enableSplash: false,
                            itemSnapping: true,
                            flexWeights: const [2, 1],
                            children: List.generate(
                              widget.state.thumbnails.length,
                              (index) {
                                final e = widget.state.thumbnails[index];

                                return ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  enabled:
                                      e.rating == PostRating.explicit ||
                                      e.rating == PostRating.questionable,
                                  child: Image(
                                    frameBuilder:
                                        (
                                          context,
                                          child,
                                          frame,
                                          wasSynchronouslyLoaded,
                                        ) {
                                          if (wasSynchronouslyLoaded) {
                                            return child;
                                          }

                                          return frame == null
                                              ? const ShimmerLoadingIndicator()
                                              : child.animate().fadeIn();
                                        },

                                    colorBlendMode: BlendMode.color,
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                                    image: CachedNetworkImageProvider(e.url),
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    DialogRoute<void>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(l10n.delete),
                                          content: ListTile(
                                            title: Text(widget.state.tags),
                                            subtitle: Text(
                                              widget.state.time.toString(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: gridDbs != null
                                                  ? () {
                                                      gridDbs!
                                                          .openSecondary(
                                                            widget.state.booru,
                                                            widget.state.name,
                                                            null,
                                                          )
                                                          .destroy()
                                                          .then((value) {
                                                            if (context
                                                                .mounted) {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            }

                                                            animationController
                                                                .forward()
                                                                .then((_) {
                                                                  gridBookmarks
                                                                      .delete(
                                                                        widget
                                                                            .state
                                                                            .name,
                                                                      );
                                                                });
                                                          });
                                                    }
                                                  : null,
                                              child: Text(l10n.yes),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(l10n.no),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.9,
                              ),
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
