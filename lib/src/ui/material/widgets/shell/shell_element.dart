// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "shell_scope.dart";

class SourceShellRefreshIndicator extends StatelessWidget {
  const SourceShellRefreshIndicator({
    super.key,
    required this.selection,
    required this.source,
    required this.child,
  });

  final ShellSelectionHolder selection;

  final ResourceSource<dynamic, dynamic> source;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        selection.reset(true);

        if (source is ChainedFilterResourceSource) {
          return (source as ChainedFilterResourceSource).refreshOriginal();
        }

        return source.clearRefresh();
      },
      child: child,
    );
  }
}

class SourceShellElementState<T extends CellBuilder>
    with DefaultInjectStack
    implements ShellScopeOverlayInjector, ShellElementState {
  SourceShellElementState({
    required this.source,
    required this.selectionController,
    required this.actions,
    required this.onEmpty,
    this.topPaddingHeight = 80,
    this.wrapRefresh = defaultRefreshIndicator,
    this.updatesAvailable,
  });

  final double topPaddingHeight;

  final SelectionController selectionController;
  final List<SelectionBarAction> actions;

  final Widget Function(SourceShellElementState state, Widget child)?
      wrapRefresh;

  static Widget defaultRefreshIndicator(
    SourceShellElementState state,
    Widget child,
  ) =>
      SourceShellRefreshIndicator(
        selection: state.selection,
        source: state.source,
        child: child,
      );

  double _cachedScrollOffset = 0;

  double get localScrollOffset => _cachedScrollOffset;

  // ignore: use_setters_to_change_properties
  void setOffset(double d) {
    _cachedScrollOffset = d;
  }

  @override
  final OnEmptyInterface onEmpty;

  @override
  final ResourceSource<int, T> source;

  @override
  final UpdatesAvailable? updatesAvailable;

  @override
  late ShellSelectionHolder selection = ShellSelectionHolder.source(
    selectionController,
    actions,
    source: source.backingStorage,
  );

  @override
  bool get canLoadMore => source.progress.canLoadMore;

  @override
  bool get hasNext => source.hasNext;

  @override
  bool get isEmpty => source.backingStorage.isEmpty;

  @override
  bool get isNotEmpty => source.backingStorage.isNotEmpty;

  @override
  bool get isRefreshing => source.progress.inRefreshing;

  @override
  Future<void> clearRefresh() {
    _cachedScrollOffset = 0;

    return source.clearRefresh();
  }

  @override
  Widget wrapChild(Widget child) {
    return ShellSelectionCountHolder(
      key: null,
      selection: selection,
      controller: selectionController,
      child: wrapRefresh != null ? wrapRefresh!(this, child) : child,
    );
  }

  @override
  void clearRefreshIfNeeded() {
    if (source.count == 0) {
      clearRefresh();
    }
  }

  @override
  Future<void> next() {
    if (source.count == 0) {
      return Future.value();
    }

    return source.next();
  }

  @override
  double tryCalculateScrollSizeToItem(
    double contentSize,
    int idx,
    GridLayoutType layoutType,
    GridColumn columns,
  ) {
    if (layoutType == GridLayoutType.list) {
      return (contentSize - topPaddingHeight) * idx / source.count;
    } else {
      return (contentSize - topPaddingHeight) *
          (idx / columns.number - 1) /
          (source.count / columns.number);
    }
  }

  @override
  StreamSubscription<bool> watchRefreshing(
    void Function(bool isRefreshing) fn,
  ) =>
      source.progress.watch(fn);

  void destroy() {
    selection.dispose();
  }
}

abstract class ShellElementState {
  bool get isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get hasNext;
  bool get canLoadMore;
  bool get isRefreshing;

  ShellSelectionHolder get selection;

  double tryCalculateScrollSizeToItem(
    double contentSize,
    int idx,
    GridLayoutType layoutType,
    GridColumn columns,
  );

  void clearRefreshIfNeeded();

  Future<void> clearRefresh();
  Future<void> next();

  StreamSubscription<bool> watchRefreshing(void Function(bool isRefreshing) fn);
}

class ShellElement extends StatefulWidget {
  const ShellElement({
    super.key,
    required this.state,
    required this.slivers,
    this.initialScrollPosition = 0,
    this.addGesturesPadding = false,
    this.animationsOnSourceWatch = true,
    this.playAnimationOn = const [],
    this.registerNotifiers,
    this.updateScrollPosition,
    this.scrollUpOn = const [],
    this.scrollingState,
  });

  final bool animationsOnSourceWatch;
  final bool addGesturesPadding;

  final double initialScrollPosition;

  final ShellElementState state;

  final ScrollOffsetFn? updateScrollPosition;

  final NotifiersFn? registerNotifiers;

  final List<WatchFire<dynamic>> playAnimationOn;
  final List<ScrollUpEvents> scrollUpOn;
  final ScrollingStateSink? scrollingState;

  final List<Widget> slivers;

  @override
  State<ShellElement> createState() => _ShellElementState();
}

class _ShellElementState extends State<ShellElement> {
  ShellElementState get state => widget.state;

  final _animationsKey = GlobalKey<_PlayAnimationsState>();

  late final StreamSubscription<bool>? _subscription;
  late final StreamSubscription<void>? _refreshEvents;

  final searchFocus = FocusNode();

  ScrollingStateSink? get scrollingState => widget.scrollingState;

  @override
  void initState() {
    super.initState();

    _subscription = widget.animationsOnSourceWatch
        ? state.watchRefreshing((refreshing) {
            if (!refreshing) {
              _animationsKey.currentState?.enableAnimationsFor();
            }
          })
        : null;

    _refreshEvents = widget.scrollingState != null
        ? state.watchRefreshing((isRefreshing) {
            if (!isRefreshing) {
              scrollingState?.sink.add(true);
            }
          })
        : null;

    state.clearRefreshIfNeeded();
  }

  @override
  void dispose() {
    _refreshEvents?.cancel();
    if (scrollingState != null && !scrollingState!.isExpanded) {
      scrollingState?.sink.add(true);
    }

    _subscription?.cancel();
    searchFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridSettingsWatcher = ShellConfiguration.watcherOf(context);

    return PlayAnimations(
      key: _animationsKey,
      playAnimationsOn: widget.playAnimationOn + [gridSettingsWatcher],
      child: state.selection.inject(
        Builder(
          builder: (context) {
            final saveScroll =
                ShellScrollNotifier.saveScrollNotifierOf(context);

            return ShellScrollingLogicHolder(
              offsetSaveNotifier: saveScroll,
              initalScrollPosition: widget.initialScrollPosition,
              controller: ShellScrollNotifier.of(context),
              state: state,
              scrollingState: widget.scrollingState,
              scrollUpOn: widget.scrollUpOn,
              updateScrollPosition: widget.updateScrollPosition,
              child: FocusNotifier(
                notifier: searchFocus,
                child: widget.registerNotifiers != null
                    ? widget.registerNotifiers!(
                        SliverMainAxisGroup(slivers: widget.slivers),
                      )
                    : SliverMainAxisGroup(slivers: widget.slivers),
              ),
            );
          },
        ),
      ),
    );
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

class ShellScrollingLogicHolder extends StatefulWidget {
  const ShellScrollingLogicHolder({
    super.key,
    required this.controller,
    required this.initalScrollPosition,
    required this.state,
    required this.scrollingState,
    required this.offsetSaveNotifier,
    required this.scrollUpOn,
    required this.updateScrollPosition,
    required this.child,
  });

  final double initalScrollPosition;

  final ShellElementState state;
  final ScrollingStateSink? scrollingState;
  final List<ScrollUpEvents> scrollUpOn;
  final ScrollOffsetFn? updateScrollPosition;

  final ValueNotifier<bool> offsetSaveNotifier;
  final ScrollController controller;
  final Widget child;

  @override
  State<ShellScrollingLogicHolder> createState() =>
      _ShellScrollingLogicHolderState();
}

class _ShellScrollingLogicHolderState extends State<ShellScrollingLogicHolder> {
  ScrollController get controller => widget.controller;

  ShellElementState get state => widget.state;
  ScrollingStateSink? get scrollingState => widget.scrollingState;

  final List<StreamSubscription<void>> _scrollUpEvents = [];

  late double lastOffset = widget.initalScrollPosition;
  double _scrollingOffsetFlingDown = 0;
  double _prevScrollOffsetDown = 0;

  double _scrollingOffsetFlingUp = 0;
  double _prevScrollOffsetUp = 0;

  @override
  void initState() {
    super.initState();

    for (final e in widget.scrollUpOn) {
      _scrollUpEvents.add(
        e.$1.listen((_) {
          if (e.$2 != null) {
            if (!e.$2!()) {
              return;
            }
          }

          if (controller.hasClients) {
            controller.animateTo(
              0,
              duration: Durations.long1,
              curve: Easing.standard,
            );
          }
        }),
      );
    }

    if (widget.initalScrollPosition != controller.offset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.jumpTo(widget.initalScrollPosition);
      });
    }

    scrollingState?.sink.add(true);

    controller.addListener(listener);

    if (widget.updateScrollPosition != null) {
      widget.offsetSaveNotifier.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    widget.offsetSaveNotifier.removeListener(_scrollListener);
    controller.removeListener(listener);
    widget.updateScrollPosition?.call(lastOffset);

    for (final e in _scrollUpEvents) {
      e.cancel();
    }

    super.dispose();
  }

  void _scrollListener() {
    widget.updateScrollPosition?.call(controller.offset);
  }

  void listener() {
    if (controller.offset == 0 ||
        controller.offset == controller.position.maxScrollExtent) {
      scrollingState?.sink.add(true);
    }

    final scrollingEvent =
        controller.position.pixels == controller.position.maxScrollExtent ||
            controller.offset == 0;

    if (scrollingEvent ||
        controller.position.userScrollDirection == ScrollDirection.forward) {
      if (_scrollingOffsetFlingDown > 120) {
        scrollingState?.sink.add(true);
      } else {
        if (_prevScrollOffsetDown == 0) {
          _prevScrollOffsetDown = controller.offset;
        } else {
          _scrollingOffsetFlingDown +=
              (_prevScrollOffsetDown - controller.offset).abs();
          _prevScrollOffsetDown = controller.offset;
        }
      }

      _scrollingOffsetFlingUp = 0;
      _prevScrollOffsetUp = 0;
    } else if (scrollingEvent ||
        controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (_scrollingOffsetFlingUp > 120) {
        scrollingState?.sink.add(false);
      } else {
        if (_prevScrollOffsetUp == 0) {
          _prevScrollOffsetUp = controller.offset;
        } else {
          _scrollingOffsetFlingUp +=
              (_prevScrollOffsetUp - controller.offset).abs();
          _prevScrollOffsetUp = controller.offset;
        }
      }

      _scrollingOffsetFlingDown = 0;
      _prevScrollOffsetDown = 0;
    } else {
      _scrollingOffsetFlingUp = 0;
      _prevScrollOffsetUp = 0;

      _scrollingOffsetFlingDown = 0;
      _prevScrollOffsetDown = 0;
    }

    if (state.hasNext) {
      lastOffset = controller.offset;

      if (!state.canLoadMore) {
        return;
      }

      final h = controller.position.viewportDimension;

      final height = h - h * 0.80;

      if (!state.isRefreshing &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              1 - (height / controller.positions.first.maxScrollExtent)) {
        state.next();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ShellSelectionCountHolder extends StatefulWidget {
  const ShellSelectionCountHolder({
    required super.key,
    required this.selection,
    required this.controller,
    required this.child,
  });

  final ShellSelectionHolder selection;

  final SelectionController controller;

  final Widget child;

  @override
  State<ShellSelectionCountHolder> createState() =>
      _ShellSelectionCountHolderState();
}

class _ShellSelectionCountHolderState extends State<ShellSelectionCountHolder> {
  late final StreamSubscription<void> _expandedEvents;
  late final StreamSubscription<void> _countEvents;

  int _updateCount = 0;

  void _onPop(bool _, Object? __) {
    if (widget.selection.isNotEmpty) {
      widget.selection.reset();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    _countEvents = widget.controller.countEvents.listen((_) {
      setState(() {
        _updateCount += 1;
      });
    });

    _expandedEvents = widget.controller.expandedEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countEvents.cancel();
    _expandedEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.selection.isEmpty,
      onPopInvokedWithResult: _onPop,
      child: SelectionCountNotifier(
        count: widget.selection.count,
        countUpdateTimes: _updateCount,
        child: widget.child,
      ),
    );
  }
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
