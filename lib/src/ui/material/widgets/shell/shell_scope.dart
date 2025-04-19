// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:async/async.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/autocomplete_widget.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/focus_notifier.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_fab_type.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";

part "configuration/shell_selection.dart";
part "parts/app_bar.dart";
part "shell_element.dart";
part "wrappers/wrap_selection.dart";

typedef WatchFire<T> = StreamSubscription<T> Function(
  void Function(T), [
  bool fire,
]);

typedef NotifiersFn = InheritedWidget Function(Widget child);
typedef ScrollOffsetFn = void Function(double pos);
typedef ScrollUpEvents = (Stream<void> stream, bool Function()? conditional);
typedef ScrollSizeCalculator = double Function(
  double contentSize,
  int idx,
  GridLayoutType layoutType,
  GridColumn columns,
);

abstract class ShellScopeOverlayInjector {
  Widget wrapChild(Widget child);

  OnEmptyInterface get onEmpty;

  double tryCalculateScrollSizeToItem(
    double contentSize,
    int idx,
    GridLayoutType layoutType,
    GridColumn columns,
  );

  List<Widget> injectStack(BuildContext context);
}

abstract class OnEmptyInterface {
  const factory OnEmptyInterface.empty() = _EmptyOnEmptyInterface;

  bool get showEmpty;

  Widget build(BuildContext context);

  StreamSubscription<bool> watch(void Function(bool showEmpty) fn);
}

class _EmptyOnEmptyInterface implements OnEmptyInterface {
  const _EmptyOnEmptyInterface();

  @override
  Widget build(BuildContext context) =>
      const SliverPadding(padding: EdgeInsets.zero);

  @override
  bool get showEmpty => false;

  @override
  StreamSubscription<bool> watch(void Function(bool showEmpty) fn) =>
      const Stream<bool>.empty().listen(fn);
}

class SourceOnEmptyInterface implements OnEmptyInterface {
  const SourceOnEmptyInterface(this.source, this.subtitle);

  final ResourceSource<int, dynamic> source;
  final String Function(BuildContext) subtitle;

  @override
  Widget build(BuildContext context) {
    return EmptyWidgetBackground(
      subtitle: subtitle(context),
    );
  }

  @override
  bool get showEmpty =>
      source.backingStorage.isEmpty && !source.progress.inRefreshing;

  @override
  StreamSubscription<bool> watch(void Function(bool isEmpty) fn) {
    return StreamGroup.merge([
      source.backingStorage.countEvents,
      source.progress.stream,
    ]).map((e) => showEmpty).listen(fn);
  }
}

mixin DefaultInjectStack implements ShellScopeOverlayInjector {
  ResourceSource<dynamic, dynamic>? get source;
  UpdatesAvailable? get updatesAvailable;

  @override
  List<Widget> injectStack(BuildContext context) {
    return [
      if (updatesAvailable != null && source != null)
        _UpdatesAvailableWidget(
          updatesAvailable: updatesAvailable!,
          progress: source!.progress,
        ),
    ];
  }
}

class ElementPriority {
  const ElementPriority(
    this.sliver, {
    this.hideOnEmpty = true,
  });

  final Widget sliver;
  final bool hideOnEmpty;
}

class ThisIndex extends InheritedWidget {
  const ThisIndex({
    super.key,
    required this.idx,
    required this.selectFrom,
    required super.child,
  });

  final int idx;
  final List<int>? selectFrom;

  static (int, List<int>?) of(BuildContext context) => maybeOf(context)!;

  static (int, List<int>?)? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ThisIndex>();

    return widget != null ? (widget.idx, widget.selectFrom) : null;
  }

  @override
  bool updateShouldNotify(ThisIndex oldWidget) =>
      idx != oldWidget.idx || selectFrom != oldWidget.selectFrom;
}

class ShellScope extends StatefulWidget {
  const ShellScope({
    super.key,
    required this.stackInjector,
    required this.configWatcher,
    required this.elements,
    this.addGesturesPadding = false,
    this.appBar = const NoShellAppBar(),
    this.searchBottomWidget,
    this.footer,
    this.settingsButton,
    this.backButton = const EmptyAppBarBackButton(inherit: true),
    this.fab = const NoShellFab(),
    this.scrollDirection = Axis.vertical,
    this.showScrollbar = true,
  });

  final bool addGesturesPadding;
  final ShellScopeOverlayInjector stackInjector;
  final ShellAppBarType appBar;
  final PreferredSizeWidget? searchBottomWidget;
  final PreferredSizeWidget? footer;
  final Widget? settingsButton;
  final AppBarBackButtonBehaviour backButton;
  final ShellFabType fab;
  final ShellConfigurationWatcher configWatcher;

  final Axis scrollDirection;
  final bool showScrollbar;

  final List<ElementPriority> elements;

  @override
  State<ShellScope> createState() => _ShellScopeState();
}

class _ShellScopeState extends State<ShellScope> with _ShellScrollStatusMixin {
  @override
  final ScrollController controller = ScrollController();

  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellConfiguration(
      watch: widget.configWatcher,
      child: ShellCapabilityQuery(
        data: ShellCapabilityData(fab: widget.fab),
        child: FocusNotifier(
          notifier: focusNode,
          child: ShellScrollNotifier(
            saveScrollNotifier: _saveOffNotifier,
            fabNotifier: _fabNotifier,
            controller: controller,
            scrollSizeCalculator:
                widget.stackInjector.tryCalculateScrollSizeToItem,
            child: widget.stackInjector.wrapChild(
              _StaticBottomPadding(
                actions: SelectionActions.of(context),
                child: _Stack(
                  footer: widget.footer,
                  fab: widget.fab,
                  stackInjector: widget.stackInjector,
                  child: _MainBody(
                    showScrollbar: widget.showScrollbar,
                    backButton: widget.backButton,
                    slivers: widget.elements,
                    addGesturesPadding: widget.addGesturesPadding,
                    searchWidget: widget.appBar,
                    footer: widget.footer,
                    onEmpty: widget.stackInjector.onEmpty,
                    bottomWidget: widget.searchBottomWidget,
                    settingsButton: widget.settingsButton,
                    controller: controller,
                    saveScrollOffsNotifier: _saveOffNotifier,
                    scrollDirection: widget.scrollDirection,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

mixin _ShellScrollStatusMixin<S extends StatefulWidget> on State<S> {
  ScrollController get controller;

  late final ValueNotifier<bool> _fabNotifier;
  late final ValueNotifier<bool> _saveOffNotifier;

  @override
  void initState() {
    super.initState();

    _fabNotifier = ValueNotifier(false);
    _saveOffNotifier = ValueNotifier(false);

    controller.addListener(_listener);
  }

  @override
  void dispose() {
    _saveOffNotifier.dispose();
    _fabNotifier.dispose();

    controller.removeListener(_listener);

    super.dispose();
  }

  void _listener() {
    final showFab = controller.position.pixels ==
            controller.position.maxScrollExtent ||
        controller.position.userScrollDirection == ScrollDirection.forward &&
            controller.offset != 0;
    if (_fabNotifier.value != showFab) {
      _fabNotifier.value = showFab;
    }
  }
}

class _MainBody extends StatelessWidget {
  const _MainBody({
    // super.key,
    required this.backButton,
    required this.searchWidget,
    required this.footer,
    required this.bottomWidget,
    required this.settingsButton,
    required this.controller,
    required this.addGesturesPadding,
    required this.slivers,
    required this.saveScrollOffsNotifier,
    required this.onEmpty,
    required this.scrollDirection,
    required this.showScrollbar,
  });

  final AppBarBackButtonBehaviour backButton;

  final ShellAppBarType searchWidget;
  final PreferredSizeWidget? footer;
  final PreferredSizeWidget? bottomWidget;

  final Widget? settingsButton;
  final ScrollController controller;

  final bool addGesturesPadding;
  final ValueNotifier<bool> saveScrollOffsNotifier;

  final OnEmptyInterface onEmpty;

  final List<ElementPriority> slivers;
  final Axis scrollDirection;

  final bool showScrollbar;

  static List<Widget> bodySlivers(
    BuildContext context, {
    required List<ElementPriority> slivers,
    required AppBarBackButtonBehaviour backButton,
    required Widget? settingsButton,
    required ShellAppBarType searchWidget,
    required PreferredSizeWidget? footer,
    required PreferredSizeWidget? bottomWidget,
    required OnEmptyInterface onEmpty,
  }) {
    Widget? appBar;
    if (searchWidget is! NoShellAppBar) {
      appBar = _AppBar(
        searchFocus: FocusNotifier.nodeOf(context),
        bottomWidget: bottomWidget,
        searchWidget: searchWidget,
        settingsButton: settingsButton,
        backButton: backButton,
      );
    }

    return [
      if (appBar != null) appBar,
      _OnEmptyListenerSlivers(
        onEmpty: onEmpty,
        slivers: slivers,
      ),
      // ...slivers,

      _WrapPadding(footer: footer),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final m = MediaQuery.of(context);

    final child = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: MediaQuery(
        data: m,
        child: Padding(
          padding: addGesturesPadding
              ? EdgeInsets.only(
                  left: m.systemGestureInsets.left != 0
                      ? m.systemGestureInsets.left / 2
                      : 0,
                  right: m.systemGestureInsets.right != 0
                      ? m.systemGestureInsets.right / 2
                      : 0,
                )
              : EdgeInsets.zero,
          child: _OnEmptyListenerScrollView(
            onEmpty: onEmpty,
            controller: controller,
            build: (context, showEmpty) => CustomScrollView(
              scrollDirection: scrollDirection,
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: bodySlivers(
                context,
                slivers: slivers,
                backButton: backButton,
                bottomWidget: bottomWidget,
                footer: footer,
                searchWidget: searchWidget,
                settingsButton: settingsButton,
                onEmpty: onEmpty,
              ),
            ),
          ),
        ),
      ),
    );

    return MediaQuery(
      data: m.copyWith(
        padding: m.padding +
            EdgeInsets.only(
              top: 4,
              bottom: searchWidget is NoShellAppBar ? 4 : 0,
            ),
      ),
      child: showScrollbar
          ? Scrollbar(
              interactive: false,
              controller: controller,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final newValue = notification is ScrollEndNotification;
                  if (newValue != saveScrollOffsNotifier.value) {
                    saveScrollOffsNotifier.value = newValue;
                  }
                  return false;
                },
                child: child,
              ),
            )
          : child,
    );
  }
}

class _OnEmptyListenerScrollView extends StatefulWidget {
  const _OnEmptyListenerScrollView({
    // super.key,
    required this.onEmpty,
    required this.build,
    required this.controller,
  });

  final OnEmptyInterface onEmpty;
  final ScrollController controller;

  final Widget Function(BuildContext context, bool showEmpty) build;

  @override
  State<_OnEmptyListenerScrollView> createState() =>
      __OnEmptyListenerScrollViewState();
}

class __OnEmptyListenerScrollViewState extends State<_OnEmptyListenerScrollView>
    with _OnEmptyMixin {
  @override
  OnEmptyInterface get onEmpty => widget.onEmpty;

  @override
  void onNewShowEmpty(bool showEmpty) {
    if (showEmpty) {
      widget.controller.animateTo(
        0,
        duration: Durations.medium3,
        curve: Easing.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, showEmpty);
  }
}

mixin _OnEmptyMixin<W extends StatefulWidget> on State<W> {
  OnEmptyInterface get onEmpty;

  late final StreamSubscription<bool> _events;
  bool showEmpty = false;

  @override
  void initState() {
    super.initState();

    showEmpty = onEmpty.showEmpty;

    _events = onEmpty.watch((newShowEmpty) {
      if (newShowEmpty != showEmpty) {
        onNewShowEmpty(newShowEmpty);
        setState(() {
          showEmpty = newShowEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  void onNewShowEmpty(bool newEmpty) {}
}

class _OnEmptyListenerSlivers extends StatefulWidget {
  const _OnEmptyListenerSlivers({
    // super.key,
    required this.onEmpty,
    required this.slivers,
  });

  final OnEmptyInterface onEmpty;
  final List<ElementPriority> slivers;

  @override
  State<_OnEmptyListenerSlivers> createState() =>
      _OnEmptyListenerSliversState();
}

class _OnEmptyListenerSliversState extends State<_OnEmptyListenerSlivers>
    with _OnEmptyMixin {
  @override
  OnEmptyInterface get onEmpty => widget.onEmpty;

  @override
  Widget build(BuildContext context) {
    final notHide =
        widget.slivers.where((e) => !e.hideOnEmpty).map((e) => e.sliver);
    final hide =
        widget.slivers.where((e) => e.hideOnEmpty).map((e) => e.sliver);

    return SliverMainAxisGroup(
      slivers: [
        ...notHide,
        if (showEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: widget.onEmpty.build(context),
          ),
        SliverVisibility(
          visible: !showEmpty,
          maintainState: true,
          sliver: SliverMainAxisGroup(slivers: hide.toList()),
        ),
      ],
    );
  }
}

class _WrapPadding extends StatelessWidget {
  const _WrapPadding({
    required this.footer,
  });

  final PreferredSizeWidget? footer;

  @override
  Widget build(BuildContext context) {
    final hasFab = ShellCapabilityQuery.fabOf(context) is! NoShellFab;

    final insets = EdgeInsets.only(
      bottom: ShellBottomPaddingProvider.of(context, hasFab) +
          (footer != null ? footer!.preferredSize.height : 0) +
          8,
    );

    return SliverPadding(padding: insets);
  }
}

class _Stack extends StatelessWidget {
  const _Stack({
    // super.key,
    required this.stackInjector,
    required this.fab,
    required this.footer,
    required this.child,
  });

  final ShellScopeOverlayInjector stackInjector;
  final ShellFabType fab;
  final PreferredSizeWidget? footer;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = ShellBottomPaddingProvider.of(context);

    return Stack(
      children: [
        child,
        ...stackInjector.injectStack(context),
        if (fab is! NoShellFab)
          Align(
            alignment: Alignment.bottomRight,
            child: AnimatedPadding(
              duration: Durations.medium3,
              curve: Easing.standard,
              padding: EdgeInsets.only(
                right: 4 + 8,
                bottom: bottomPadding + 4 + 8,
              ),
              child: fab.widget(context),
            ),
          ),
        if (footer != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: Durations.medium3,
              curve: Easing.standard,
              padding: EdgeInsets.only(
                bottom: ShellBottomPaddingProvider.of(context, true) + 4,
              ),
              child: footer,
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

    final newScroll = ShellScrollNotifier.of(context);
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
    final notifier = ShellScrollNotifier.fabNotifierOf(context);
    final theme = Theme.of(context);
    final l10n = context.l10n();

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

class _StaticBottomPadding extends StatelessWidget {
  const _StaticBottomPadding({
    // super.key,
    required this.actions,
    required this.child,
  });

  final SelectionActions actions;

  final Widget child;

  double _bottomPadding(BuildContext context) {
    final paddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final actions = SelectionActions.of(context);

    return paddingBottom +
        (actions.controller.isExpanded
            ? actions.size.expanded
            : actions.size.base);
  }

  @override
  Widget build(BuildContext context) {
    SelectionCountNotifier.maybeCountOf(context);

    final fab = ShellCapabilityQuery.fabOf(context);

    return ShellBottomPaddingProvider(
      fab: fab is NoShellFab ? 0 : kFloatingActionButtonMargin * 2 + 24 + 8,
      padding: _bottomPadding(context),
      child: child,
    );
  }
}

enum _ShellCapAspect {
  fab,
}

class ShellCapabilityData {
  const ShellCapabilityData({
    required this.fab,
  });

  final ShellFabType fab;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ShellCapabilityData && fab == other.fab;
  }

  @override
  int get hashCode => fab.hashCode;
}

class ShellCapabilityQuery extends InheritedModel<_ShellCapAspect> {
  const ShellCapabilityQuery({
    super.key,
    required this.data,
    required super.child,
  });

  final ShellCapabilityData data;

  @override
  bool updateShouldNotify(ShellCapabilityQuery oldWidget) {
    return oldWidget.data != data;
  }

  static ShellFabType fabOf(BuildContext context) =>
      _of(context, _ShellCapAspect.fab).fab;

  static ShellCapabilityData of(BuildContext context) => _of(context);

  static ShellCapabilityData _of(
    BuildContext context, [
    _ShellCapAspect? aspect,
  ]) {
    return InheritedModel.inheritFrom<ShellCapabilityQuery>(
      context,
      aspect: aspect,
    )!
        .data;
  }

  static ShellCapabilityData? maybeOf(BuildContext context) {
    return _maybeOf(context);
  }

  static ShellCapabilityData? _maybeOf(
    BuildContext context, [
    _ShellCapAspect? aspect,
  ]) {
    return InheritedModel.inheritFrom<ShellCapabilityQuery>(
      context,
      aspect: aspect,
    )?.data;
  }

  @override
  bool updateShouldNotifyDependent(
    ShellCapabilityQuery oldWidget,
    Set<_ShellCapAspect> dependencies,
  ) {
    return dependencies.any(
      (Object dependency) =>
          dependency is _ShellCapAspect &&
          switch (dependency) {
            _ShellCapAspect.fab => data.fab != oldWidget.data.fab,
          },
    );
  }
}

class ShellScrollNotifier extends InheritedWidget {
  const ShellScrollNotifier({
    super.key,
    required this.fabNotifier,
    required this.controller,
    required this.saveScrollNotifier,
    required this.scrollSizeCalculator,
    required super.child,
  });

  final ScrollController controller;
  final ValueNotifier<bool> fabNotifier;
  final ValueNotifier<bool> saveScrollNotifier;
  final ScrollSizeCalculator scrollSizeCalculator;

  static ScrollController of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ShellScrollNotifier>();

    return widget!.controller;
  }

  static ShellScrollNotifier? _maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ShellScrollNotifier>();

    return widget;
  }

  static ScrollController? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ShellScrollNotifier>();

    return widget?.controller;
  }

  static ValueNotifier<bool> fabNotifierOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ShellScrollNotifier>();

    return widget!.fabNotifier;
  }

  static ValueNotifier<bool> saveScrollNotifierOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ShellScrollNotifier>();

    return widget!.saveScrollNotifier;
  }

  static void maybeScrollToOf<T extends CellBuilder>(
    BuildContext context,
    int i, [
    bool animate = false,
  ]) {
    final notifier = _maybeOf(context);
    if (notifier == null || !notifier.controller.hasClients) {
      return;
    }
    final controller = notifier.controller;

    // final extra = _GridExtrasNotifier.of(context);
    final config = ShellConfiguration.of(context);

    if (controller.position.maxScrollExtent.isInfinite) {
      return;
    }

    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    final double target = notifier.scrollSizeCalculator(
      contentSize,
      i,
      config.layoutType,
      config.columns,
    );

    if (target < controller.position.minScrollExtent ||
        target > controller.position.maxScrollExtent) {
      return;
    }

    if (animate) {
      controller.animateTo(
        target,
        curve: Easing.standard,
        duration: Durations.medium3,
      );
    } else {
      controller.jumpTo(target);
    }
  }

  @override
  bool updateShouldNotify(ShellScrollNotifier oldWidget) {
    return controller != oldWidget.controller ||
        fabNotifier != oldWidget.fabNotifier;
  }
}

class ShellBottomPaddingProvider extends InheritedWidget {
  const ShellBottomPaddingProvider({
    super.key,
    required this.padding,
    required this.fab,
    required super.child,
  });

  final double padding;
  final double fab;

  static double of(BuildContext context, [bool includeFab = false]) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ShellBottomPaddingProvider>();

    return widget!.padding + (includeFab ? widget.fab : 0.0);
  }

  @override
  bool updateShouldNotify(ShellBottomPaddingProvider oldWidget) =>
      padding != oldWidget.padding;
}
