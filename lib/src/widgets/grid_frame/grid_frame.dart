// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/focus_notifier.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_bottom_padding_provider.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/search/autocomplete/autocomplete_tag.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

part "configuration/grid_action.dart";
part "configuration/grid_description.dart";
part "configuration/grid_selection.dart";
part "configuration/search_and_focus.dart";
part "configuration/segments.dart";
part "parts/app_bar.dart";
part "parts/bottom_widget.dart";
part "parts/cell_provider.dart";
part "wrappers/wrap_padding.dart";
part "wrappers/wrap_selection.dart";

typedef WatchFire<T> = StreamSubscription<T> Function(
  void Function(T), [
  bool fire,
]);

/// The grid of images.
class GridFrame<T extends CellBase> extends StatefulWidget {
  const GridFrame({
    required super.key,
    required this.slivers,
    this.initalScrollPosition = 0,
    required this.functionality,
    this.onDispose,
    this.belowMainFocus,
    required this.description,
  });

  /// [initalScrollPosition] is needed for the state restoration.
  /// If [initalScrollPosition] is not 0, then it is set as the starting scrolling position.
  final double initalScrollPosition;

  final GridFunctionality<T> functionality;

  /// Some additional metadata about the grid.
  final GridDescription<T> description;

  /// If [belowMainFocus] is not null, then when the grid gets disposed
  /// [belowMainFocus.requestFocus] get called.
  final FocusNode? belowMainFocus;

  final void Function()? onDispose;

  final List<Widget> slivers;

  @override
  State<GridFrame<T>> createState() => GridFrameState<T>();
}

class GridFrameState<T extends CellBase> extends State<GridFrame<T>> {
  late final ScrollController? controller;
  final _holderKey = GlobalKey<__GridSelectionCountHolderState>();
  final _animationsKey = GlobalKey<_PlayAnimationsState>();

  late final StreamSubscription<int>? _subscription;

  late final ValueNotifier<bool>? _scrollingNotifier;

  final searchFocus = FocusNode();

  late final selection = GridSelection<T>(
    widget.description.actions,
    widget.functionality.selectionGlue.chain(
      updateCount: (parent, count) {
        parent.updateCount(count);
        _holderKey.currentState?.update();
      },
    ),
    source: widget.functionality.source.backingStorage,
    noAppBar: !widget.description.showAppBar,
  );

  ResourceSource<int, T> get source => widget.functionality.source;

  late double lastOffset = widget.initalScrollPosition;

  @override
  void initState() {
    super.initState();

    final description = widget.description;

    _subscription = widget.description.animationsOnSourceWatch
        ? widget.functionality.source.backingStorage.watch((_) {
            _animationsKey.currentState?.enableAnimationsFor();
          })
        : null;

    controller = description.asSliver ? null : ScrollController();
    _scrollingNotifier = description.asSliver ? null : ValueNotifier(false);

    if (source.count == 0) {
      source.clearRefresh();
    }

    if (controller != null) {
      if (widget.initalScrollPosition != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller!.jumpTo(widget.initalScrollPosition);
        });
      }

      final f = widget.functionality.updateScrollPosition;
      if (f != null) {
        _scrollingNotifier!.addListener(_scrollListener);
      }

      controller!.addListener(() {
        final showFab = controller!.position.pixels ==
                controller!.position.maxScrollExtent ||
            controller!.position.userScrollDirection ==
                    ScrollDirection.forward &&
                controller!.offset != 0;
        if (_scrollingNotifier!.value != showFab) {
          _scrollingNotifier.value = showFab;
        }

        if (source.hasNext) {
          lastOffset = controller!.offset;

          if (!source.progress.canLoadMore) {
            return;
          }

          final h = controller!.position.viewportDimension;

          final height = h - h * 0.80;

          if (!source.progress.inRefreshing &&
              source.count != 0 &&
              (controller!.offset /
                      controller!.positions.first.maxScrollExtent) >=
                  1 - (height / controller!.positions.first.maxScrollExtent)) {
            source.next();
          }
        }
      });
    }
  }

  void _scrollListener() {
    widget.functionality.updateScrollPosition?.call(controller!.offset);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller?.dispose();
    searchFocus.dispose();

    _scrollingNotifier?.dispose();

    widget.belowMainFocus?.requestFocus();

    widget.onDispose?.call();

    widget.functionality.updateScrollPosition?.call(lastOffset);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final functionality = widget.functionality;
    final description = widget.description;

    final gridSettingsWatcher = GridConfiguration.watcherOf(context);

    return PlayAnimations(
      key: _animationsKey,
      playAnimationsOn:
          widget.functionality.playAnimationOn + [gridSettingsWatcher],
      child: FocusNotifier(
        notifier: searchFocus,
        child: _GridSelectionCountHolder(
          key: _holderKey,
          selection: selection,
          functionality: widget.functionality,
          description: widget.description,
          child: CellProvider<T>(
            getCell: source.forIdxUnsafe,
            child: GridScrollNotifier(
              scrollNotifier:
                  _scrollingNotifier ?? GridScrollNotifier.notifierOf(context),
              controller: controller ?? GridScrollNotifier.of(context),
              child: GridExtrasNotifier(
                data: GridExtrasData(
                  selection,
                  functionality,
                  description,
                  searchFocus,
                ),
                child: description.asSliver
                    ? functionality.registerNotifiers != null
                        ? functionality.registerNotifiers!(
                            _SingleSliverChild<T>(slivers: widget.slivers),
                          )
                        : _SingleSliverChild<T>(slivers: widget.slivers)
                    : functionality.registerNotifiers != null
                        ? functionality.registerNotifiers!(
                            _BodyChild<T>(
                              child: _MainBody<T>(slivers: widget.slivers),
                            ),
                          )
                        : _BodyChild<T>(
                            child: _MainBody<T>(slivers: widget.slivers),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainBody<T extends CellBase> extends StatelessWidget {
  const _MainBody({
    super.key,
    required this.slivers,
  });

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final m = MediaQuery.of(context);

    final extras = GridExtrasNotifier.of<T>(context);

    final controller = GridScrollNotifier.of(context);

    return MediaQuery(
      data: m.copyWith(
        padding: m.padding +
            EdgeInsets.only(
              top: 4,
              bottom: !extras.description.showAppBar ? 4 : 0,
            ),
      ),
      child: Scrollbar(
        interactive: false,
        controller: controller,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: MediaQuery(
            data: m,
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: extras.bodySlivers(context, slivers),
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleSliverChild<T extends CellBase> extends StatelessWidget {
  const _SingleSliverChild({
    super.key,
    required this.slivers,
  });

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final extras = GridExtrasNotifier.of<T>(context);

    return SliverMainAxisGroup(slivers: extras.bodySlivers(context, slivers));
  }
}

class _BodyChild<T extends CellBase> extends StatelessWidget {
  const _BodyChild({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extras = GridExtrasNotifier.of<T>(context);

    final source = extras.functionality.source;
    final description = extras.description;
    final functionality = extras.functionality;

    final bottomPadding = GridBottomPaddingProvider.of(context);

    return Stack(
      children: [
        if (description.pullToRefresh)
          RefreshIndicator(
            onRefresh: () {
              extras.selection.reset(true);

              if (source is ChainedFilterResourceSource) {
                return (source as ChainedFilterResourceSource)
                    .refreshOriginal();
              }

              return source.clearRefresh();
            },
            child: child,
          )
        else
          child,
        if (extras.functionality.updatesAvailable != null)
          _UpdatesAvailableWidget(
            updatesAvailable: extras.functionality.updatesAvailable!,
            progress: source.progress,
          ),
        if (description.footer != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: GridBottomPaddingProvider.of(context, true) + 4,
              ),
              child: description.footer,
            ),
          ),
        if (description.showLoadingIndicator &&
            (!description.showAppBar ||
                functionality.search is BarSearchWidget) &&
            functionality.selectionGlue.barHeight() != 0 &&
            functionality.selectionGlue.persistentBarHeight)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: _LinearProgressIndicator(
                  progress: source.progress,
                ),
              ),
            ),
          ),
        if (functionality.onEmptySource != null)
          _EmptyWidget(
            source: source,
            onEmpty: functionality.onEmptySource!,
          ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              right: 4 + 8,
              bottom: bottomPadding + 4 + 8,
            ),
            child: functionality.fab.widget(context),
          ),
        ),
      ],
    );
  }
}

class _EmptyWidget extends StatefulWidget {
  const _EmptyWidget({
    // super.key,
    required this.source,
    required this.onEmpty,
  });

  final ResourceSource<dynamic, dynamic> source;
  final Widget onEmpty;

  @override
  State<_EmptyWidget> createState() => __EmptyWidgetState();
}

class __EmptyWidgetState extends State<_EmptyWidget> {
  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.source.backingStorage.watch((_) {
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
    if (widget.source.count != 0) {
      return const Padding(padding: EdgeInsets.zero);
    }

    return Animate(
      effects: const [
        FadeEffect(
          begin: 0,
          end: 1,
          delay: Durations.short1,
          duration: Durations.short4,
          curve: Easing.standard,
        ),
      ],
      child: widget.onEmpty,
    );
  }
}

class _LinearProgressIndicator extends StatefulWidget {
  const _LinearProgressIndicator({required this.progress});

  final RefreshingProgress progress;

  @override
  State<_LinearProgressIndicator> createState() =>
      __LinearProgressIndicatorState();
}

class __LinearProgressIndicatorState extends State<_LinearProgressIndicator> {
  RefreshingProgress get progress => widget.progress;

  late final StreamSubscription<bool> _watcher;

  @override
  void initState() {
    _watcher = progress.watch((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !progress.inRefreshing
        ? const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SizedBox(),
          )
        : const LinearProgressIndicator();
  }
}

class _UpdatesAvailableWidget extends StatefulWidget {
  const _UpdatesAvailableWidget({
    // super.key,
    required this.updatesAvailable,
    required this.progress,
  });

  final UpdatesAvailable updatesAvailable;
  final RefreshingProgress progress;

  @override
  State<_UpdatesAvailableWidget> createState() =>
      __UpdatesAvailableWidgetState();
}

class __UpdatesAvailableWidgetState extends State<_UpdatesAvailableWidget>
    with TickerProviderStateMixin {
  late final StreamSubscription<UpdatesAvailableStatus> updatesSubsc;
  late final StreamSubscription<void> refreshSubsc;
  late final AnimationController controller;
  ScrollController? scrollController;

  late UpdatesAvailableStatus status;

  bool atEdge = false;
  EdgeInsets viewPadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);

    final currentlyRefreshing = widget.progress.inRefreshing
        ? false
        : widget.updatesAvailable.tryRefreshIfNeeded();

    status = UpdatesAvailableStatus(false, currentlyRefreshing);

    updatesSubsc = widget.updatesAvailable.watch((status_) {
      setState(() {
        status = status_;
      });

      if (_showCard(status) && controller.value != 1) {
        controller.forward();
      }
    });

    refreshSubsc = widget.progress.watch((refresh) {
      if (refresh && _showCard(status)) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    scrollController?.removeListener(_scrollListener);
    updatesSubsc.cancel();
    controller.dispose();
    refreshSubsc.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newScroll = GridScrollNotifier.of(context);
    if (newScroll != scrollController) {
      if (scrollController != null) {
        scrollController?.removeListener(_scrollListener);
      }
      scrollController = newScroll;
      scrollController?.addListener(_scrollListener);
    }

    viewPadding = MediaQuery.viewPaddingOf(context);
  }

  void _scrollListener() {
    final offsetIsAfterAppBar = scrollController!.offset > 80;
    if (offsetIsAfterAppBar != atEdge) {
      setState(() {
        atEdge = offsetIsAfterAppBar;
      });
    }
  }

  void _dismiss() {
    controller.reverse().then((_) {
      setState(() {
        status = const UpdatesAvailableStatus(false, false);
      });
    });
  }

  bool _showCard(UpdatesAvailableStatus c) => c.hasUpdates || c.inRefresh;

  @override
  Widget build(BuildContext context) {
    final notifier = GridScrollNotifier.notifierOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    const circularProgress = SizedBox.square(
      dimension: 12,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );

    final dismissCard = Tooltip(
      message: l10n.dismiss,
      child: ActionChip(
        avatar:
            status.inRefresh ? null : const Icon(Icons.new_releases_outlined),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
        visualDensity: VisualDensity.compact,
        onPressed: status.inRefresh ? null : _dismiss,
        label: status.inRefresh ? circularProgress : Text(l10n.hasNewPosts),
      ),
    );

    final dismissIcon = Tooltip(
      message: l10n.dismiss,
      child: ActionChip(
        labelPadding: EdgeInsets.zero,
        onPressed: status.inRefresh ? null : _dismiss,
        visualDensity: VisualDensity.comfortable,
        label: status.inRefresh
            ? circularProgress
            : Icon(
                Icons.new_releases_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
      ),
    );

    return Animate(
      value: 1,
      controller: controller,
      effects: const [
        FadeEffect(
          duration: Durations.medium1,
          curve: Easing.standard,
          begin: 0,
          end: 1,
        ),
      ],
      child: !_showCard(status)
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topRight,
              child: ListenableBuilder(
                listenable: notifier,
                builder: (context, child) {
                  final scrollingDown = !notifier.value;

                  return Animate(
                    effects: [
                      const FadeEffect(
                        duration: Durations.medium1,
                        curve: Easing.standard,
                        begin: 1,
                        end: 0,
                      ),
                      SwapEffect(
                        builder: (context, _) {
                          return Animate(
                            effects: const [
                              FadeEffect(
                                duration: Durations.medium1,
                                curve: Easing.standard,
                                begin: 00,
                                end: 1,
                              ),
                            ],
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: 8,
                                top: kToolbarHeight +
                                    8 +
                                    MediaQuery.viewPaddingOf(context).top,
                              ),
                              child: dismissCard,
                            ),
                          );
                        },
                      ),
                    ],
                    target: scrollingDown
                        ? !atEdge
                            ? 1
                            : 0
                        : 1,
                    child: child!,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8) +
                      EdgeInsets.only(
                        top: MediaQuery.viewPaddingOf(context).top,
                      ),
                  child: dismissIcon,
                ),
              ),
            ),
    );
  }
}

class _GridSelectionCountHolder<T extends CellBase> extends StatefulWidget {
  const _GridSelectionCountHolder({
    required super.key,
    required this.selection,
    required this.functionality,
    required this.description,
    required this.child,
  });

  final GridFunctionality<T> functionality;
  final GridDescription<T> description;
  final GridSelection<T> selection;

  final Widget child;

  @override
  State<_GridSelectionCountHolder> createState() =>
      __GridSelectionCountHolderState();
}

class __GridSelectionCountHolderState extends State<_GridSelectionCountHolder> {
  int _updateCount = 0;

  void update() {
    _updateCount += 1;

    setState(() {});
  }

  void _onPop(bool _, Object? __) {
    if (widget.selection.isNotEmpty) {
      widget.selection.reset();
    }
  }

  double _bottomPadding(BuildContext context) {
    final functionality = widget.functionality;
    final selectionGlue = widget.selection.glue;

    return (functionality.selectionGlue.keyboardVisible()
        ? 0
        : MediaQuery.viewPaddingOf(context).bottom +
            (selectionGlue.isOpen()
                ? selectionGlue.barHeight()
                : selectionGlue.persistentBarHeight
                    ? selectionGlue.barHeight()
                    : 0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.selection.isEmpty,
      onPopInvokedWithResult: _onPop,
      child: GridBottomPaddingProvider(
        fab: kFloatingActionButtonMargin * 2 + 24 + 8,
        padding: _bottomPadding(context),
        child: SelectionCountNotifier(
          count: widget.selection.count,
          countUpdateTimes: _updateCount,
          child: widget.child,
        ),
      ),
    );
  }
}

class GridExtrasData<T extends CellBase> {
  const GridExtrasData(
    this.selection,
    this.functionality,
    this.description,
    this.searchFocus,
  );

  final GridSelection<T> selection;
  final GridFunctionality<T> functionality;
  final GridDescription<T> description;

  final FocusNode searchFocus;

  List<Widget> bodySlivers(BuildContext context, List<Widget> slivers) {
    Widget? appBar;
    if (description.showAppBar) {
      final bottomWidget = description.bottomWidget != null
          ? description.bottomWidget!
          : functionality.search is BarSearchWidget ||
                  !description.showLoadingIndicator
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: _BottomWidget(
                    progress: functionality.source.progress,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: SizedBox.shrink(),
                    ),
                  ),
                );

      appBar = _AppBar(
        gridFunctionality: functionality,
        searchFocus: searchFocus,
        bottomWidget: bottomWidget,
        searchWidget: functionality.search,
        pageName: description.pageName ?? "",
        description: description,
      );
    }

    return [
      if (appBar != null) appBar,
      ...slivers,
      _WrapPadding(
        footer: description.footer,
        selectionGlue: functionality.selectionGlue,
        child: null,
      ),
    ];
  }
}

class GridExtrasNotifier<T extends CellBase> extends InheritedWidget {
  const GridExtrasNotifier({
    super.key,
    required this.data,
    required super.child,
  });

  final GridExtrasData<T> data;

  static GridExtrasData<T> of<T extends CellBase>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridExtrasNotifier<T>>();

    return widget!.data;
  }

  @override
  bool updateShouldNotify(GridExtrasNotifier<T> oldWidget) {
    return data != oldWidget.data;
  }
}

class GridScrollNotifier extends InheritedWidget {
  const GridScrollNotifier({
    required this.scrollNotifier,
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;
  final ValueNotifier<bool> scrollNotifier;

  static ScrollController of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridScrollNotifier>();

    return widget!.controller;
  }

  static ScrollController? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridScrollNotifier>();

    return widget?.controller;
  }

  static ValueNotifier<bool> notifierOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridScrollNotifier>();

    return widget!.scrollNotifier;
  }

  static void maybeScrollToOf<T extends CellBase>(BuildContext context, int i) {
    final controller = maybeOf(context);

    if (controller == null || !controller.hasClients) {
      return;
    }

    final extra = GridExtrasNotifier.of<T>(context);
    final config = GridConfiguration.of(context);

    if (controller.position.maxScrollExtent.isInfinite) {
      return;
    }

    final picPerRow = config.columns;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (config.layoutType == GridLayoutType.list) {
      target = contentSize * i / extra.functionality.source.count;
    } else {
      target = contentSize *
          (i / picPerRow.number - 1) /
          (extra.functionality.source.count / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      extra.functionality.updateScrollPosition
          ?.call(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (!extra.functionality.source.progress.canLoadMore) {
        extra.functionality.updateScrollPosition
            ?.call(controller.position.maxScrollExtent);
        return;
      }
    }

    extra.functionality.updateScrollPosition?.call(target);

    controller.jumpTo(target);
  }

  @override
  bool updateShouldNotify(GridScrollNotifier oldWidget) {
    return controller != oldWidget.controller ||
        scrollNotifier != oldWidget.scrollNotifier;
  }
}

class PlayAnimations extends StatefulWidget {
  const PlayAnimations({
    required super.key,
    required this.playAnimationsOn,
    required this.child,
  });

  final List<WatchFire<dynamic>> playAnimationsOn;
  final Widget child;

  static bool? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_PlayAnimationNotifier>();

    return widget?.play;
  }

  @override
  State<PlayAnimations> createState() => _PlayAnimationsState();
}

class _PlayAnimationsState extends State<PlayAnimations> {
  final List<StreamSubscription<void>> _subsc = [];

  bool play = false;

  void enableAnimationsFor([
    Duration duration = const Duration(milliseconds: 300),
  ]) {
    setState(() {
      play = true;
    });

    Future.delayed(duration, () {
      try {
        play = false;

        setState(() {});
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();

    for (final e in widget.playAnimationsOn) {
      _subsc.add(
        e((_) {
          enableAnimationsFor();
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final e in _subsc) {
      e.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PlayAnimationNotifier(
      play: play,
      child: widget.child,
    );
  }
}

class _PlayAnimationNotifier extends InheritedWidget {
  const _PlayAnimationNotifier({
    required this.play,
    required super.child,
  });

  final bool play;

  @override
  bool updateShouldNotify(_PlayAnimationNotifier oldWidget) =>
      play != oldWidget.play;
}

class SelectedGridPage extends InheritedWidget {
  const SelectedGridPage({
    super.key,
    required this.page,
    required super.child,
  });

  final int page;

  static int? of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SelectedGridPage>();

    return widget!.page;
  }

  @override
  bool updateShouldNotify(SelectedGridPage oldWidget) => page != oldWidget.page;
}

class SelectionCountNotifier extends InheritedWidget {
  const SelectionCountNotifier({
    super.key,
    required this.count,
    required this.countUpdateTimes,
    required super.child,
  });
  final int count;
  final int countUpdateTimes;

  static int countOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SelectionCountNotifier>();

    return widget!.count;
  }

  static int maybeCountOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SelectionCountNotifier>();

    return widget?.count ?? 0;
  }

  @override
  bool updateShouldNotify(SelectionCountNotifier oldWidget) {
    return count != oldWidget.count ||
        countUpdateTimes != oldWidget.countUpdateTimes;
  }
}
