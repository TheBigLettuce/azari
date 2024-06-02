// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_subpage_state.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_app_bar_leading.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_app_bar_title.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_bottom_padding_provider.dart";
import "package:gallery/src/widgets/keybinds/describe_keys.dart";
import "package:gallery/src/widgets/keybinds/keybind_description.dart";
import "package:gallery/src/widgets/keybinds/single_activator_description.dart";
import "package:gallery/src/widgets/notifiers/focus.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

part "configuration/grid_action.dart";
part "configuration/grid_description.dart";
part "configuration/grid_selection.dart";
part "configuration/mutation.dart";
part "configuration/search_and_focus.dart";
part "configuration/segments.dart";
part "parts/app_bar.dart";
part "parts/body_padding.dart";
part "parts/bottom_widget.dart";
part "parts/cell_provider.dart";
part "wrappers/wrap_padding.dart";
part "wrappers/wrap_selection.dart";

class GridConfiguration extends StatefulWidget {
  const GridConfiguration({
    super.key,
    required this.watch,
    this.sliver = false,
    required this.child,
  });

  final GridSettingsWatcher watch;
  final bool sliver;
  final Widget child;

  static GridSettingsData of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_GridConfigurationNotifier>();

    return widget!.config;
  }

  static GridSettingsWatcher watcherOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_GridConfigurationNotifier>();

    return widget!.watcher;
  }

  @override
  State<GridConfiguration> createState() => _GridConfigurationState();
}

class _GridConfigurationState extends State<GridConfiguration> {
  late final StreamSubscription<GridSettingsData> _watcher;

  GridSettingsData? config;

  @override
  void initState() {
    super.initState();

    _watcher = widget.watch(
      (d) {
        config = d;

        setState(() {});
      },
      true,
    );
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return widget.sliver
          ? const SliverPadding(padding: EdgeInsets.zero)
          : const SizedBox.shrink();
    }

    return _GridConfigurationNotifier(
      config: config!,
      watcher: widget.watch,
      child: widget.child,
    );
  }
}

class _GridConfigurationNotifier extends InheritedWidget {
  const _GridConfigurationNotifier({
    // super.key,
    required this.config,
    required this.watcher,
    required super.child,
  });

  final GridSettingsData config;
  final GridSettingsWatcher watcher;

  @override
  bool updateShouldNotify(_GridConfigurationNotifier oldWidget) =>
      config != oldWidget.config;
}

/// The grid of images.
class GridFrame<T extends CellBase> extends StatefulWidget {
  const GridFrame({
    required super.key,
    required this.slivers,
    this.initalScrollPosition = 0,
    required this.functionality,
    this.onDispose,
    // required this.mainFocus,
    this.belowMainFocus,
    this.overrideController,
    required this.description,
  });

  /// [initalScrollPosition] is needed for the state restoration.
  /// If [initalScrollPosition] is not 0, then it is set as the starting scrolling position.
  final double initalScrollPosition;

  /// The main focus node of the grid.
  // final FocusNode mainFocus;

  final GridFunctionality<T> functionality;

  /// Some additional metadata about the grid.
  final GridDescription<T> description;

  /// If [belowMainFocus] is not null, then when the grid gets disposed
  /// [belowMainFocus.requestFocus] get called.
  final FocusNode? belowMainFocus;

  final void Function()? onDispose;

  final ScrollController? overrideController;

  final List<Widget> slivers;

  @override
  State<GridFrame<T>> createState() => GridFrameState<T>();
}

class GridFrameState<T extends CellBase> extends State<GridFrame<T>>
    with GridSubpageState<T> {
  late ScrollController controller;
  final _holderKey = GlobalKey<__GridSelectionCountHolderState>();
  final _animationsKey = GlobalKey<_PlayAnimationsState>();

  late final StreamSubscription<int>? _subscription;

  late final selection = GridSelection<T>(
    widget.description.actions,
    widget.functionality.selectionGlue.chain(
      updateCount: (parent, count) {
        parent.updateCount(count);
        _holderKey.currentState?.update();
      },
    ),
    () => controller,
    source: widget.functionality.source.backingStorage,
    noAppBar: !widget.description.showAppBar,
  );

  ResourceSource<int, T> get source => widget.functionality.source;

  int _refreshes = 0;

  late double lastOffset = widget.initalScrollPosition;

  void switchPage(int i) {
    if (i == currentPage) {
      return;
    }

    onSubpageSwitched(i, selection, controller);
  }

  @override
  void initState() {
    super.initState();

    final description = widget.description;

    _subscription = widget.description.animationsOnSourceWatch
        ? widget.functionality.source.backingStorage.watch((_) {
            _animationsKey.currentState?.enableAnimationsFor();
          })
        : null;

    controller = description.asSliver && widget.overrideController != null
        ? widget.overrideController!
        : ScrollController(initialScrollOffset: widget.initalScrollPosition);

    if (source.count == 0) {
      source.clearRefresh();
    }

    if (!description.asSliver) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        controller = widget.overrideController ?? ScrollController();

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          registerOffsetSaver(controller);
        });

        setState(() {});

        if (!source.hasNext) {
          return;
        }

        controller.addListener(() {
          lastOffset = controller.offset;

          if (!source.progress.canLoadMore || atNotHomePage) {
            return;
          }

          final h = MediaQuery.sizeOf(context).height;

          final height = h - h * 0.80;

          if (!source.progress.inRefreshing &&
              source.count != 0 &&
              (controller.offset /
                      controller.positions.first.maxScrollExtent) >=
                  1 - (height / controller.positions.first.maxScrollExtent)) {
            source.next();
          }
        });
      });
    }
  }

  // void enableAnimationsFor([
  //   Duration duration = const Duration(milliseconds: 300),
  // ]) {}

  void resetFab() {
    setState(() {
      _refreshes += 1;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (widget.overrideController == null) {
      controller.dispose();
    }

    widget.belowMainFocus?.requestFocus();

    widget.onDispose?.call();

    widget.functionality.updateScrollPosition?.call(lastOffset);

    super.dispose();
  }

  void tryScrollUntil(int p, GridSettingsData config) {
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
      target = contentSize * p / source.count;
    } else {
      target = contentSize *
          (p / picPerRow.number - 1) /
          (source.count / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      widget.functionality.updateScrollPosition
          ?.call(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (!source.progress.canLoadMore) {
        widget.functionality.updateScrollPosition
            ?.call(controller.position.maxScrollExtent);
        return;
      }
    }

    widget.functionality.updateScrollPosition?.call(target);

    controller.jumpTo(target);
  }

  double _bottomPadding(BuildContext context) {
    final functionality = widget.functionality;
    final selectionGlue = functionality.selectionGlue;
    final description = widget.description;

    return (functionality.selectionGlue.keyboardVisible()
            ? 0
            : MediaQuery.viewPaddingOf(context).bottom +
                (selectionGlue.isOpen()
                    ? selectionGlue.barHeight()
                    : selectionGlue.persistentBarHeight
                        ? selectionGlue.barHeight()
                        : 0)) +
        (description.footer != null
            ? description.footer!.preferredSize.height
            : 0);
  }

  double appBarBottomWidgetSize(PageDescription? page) =>
      ((page?.search == null && !atHomePage) || widget.description.pages == null
          ? 0
          : (40 + 16)) +
      (page == null ? 4 : 0);

  bool get hideAppBar =>
      !widget.description.showAppBar || widget.description.pages != null;

  static const double loadingIndicatorSize = 4;

  List<Widget> _makeActions(
    BuildContext context,
    GridDescription<T> description,
  ) {
    final ret = <Widget>[
      if (widget.functionality.settingsButton != null)
        widget.functionality.settingsButton!,
    ];

    if (description.menuButtonItems == null) {
      return ret;
    }

    return ((!description.inlineMenuButtonItems &&
                description.menuButtonItems!.length > 1)
            ? [
                PopupMenuButton(
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) {
                    return description.menuButtonItems!
                        .map(
                          (e) => PopupMenuItem<void>(
                            enabled: false,
                            child: e,
                          ),
                        )
                        .toList();
                  },
                ),
              ]
            : [
                ...description.menuButtonItems!,
              ]) +
        ret;
  }

  List<Widget> bodySlivers(BuildContext context, PageDescription? page) {
    final description = widget.description;
    final functionality = widget.functionality;

    Widget? appBar;
    if (description.showAppBar) {
      final pageSettingsButton = page?.settingsButton;

      final List<Widget> appBarActions = page != null
          ? [
              ...page.appIcons,
              if (pageSettingsButton != null) pageSettingsButton,
            ]
          : _makeActions(context, description);

      final bottomWidget = description.bottomWidget != null
          ? description.bottomWidget!
          : PreferredSize(
              preferredSize: Size.fromHeight(
                appBarBottomWidgetSize(page),
              ),
              child: _BottomWidget(
                progress: source.progress,
                routeChanger: page != null && page.search == null
                    ? const SizedBox.shrink()
                    : widget.description.pages?.switcherWidget(context, this),
                child: Padding(
                  padding: EdgeInsets.only(top: page == null ? 4 : 0),
                  child: const SizedBox.shrink(),
                ),
              ),
            );

      final backButton = widget.functionality.backButton;

      appBar = _AppBar(
        leading: backButton is EmptyGridBackButton && backButton.inherit
            ? null
            : GridAppBarLeading(state: this),
        title: GridAppBarTitle(state: this, page: page),
        actions: appBarActions,
        bottomWidget: bottomWidget,
        searchWidget: widget.functionality.search,
        pageName: widget.description.pageName ??
            widget.description.keybindsDescription,
        snap: widget.description.appBarSnap,
      );
    }

    return [
      if (!widget.description.showAppBar && widget.description.pages != null)
        SliverToBoxAdapter(
          child: widget.description.pages!.switcherWidget(context, this),
        ),
      if (appBar != null) appBar,
      if (page != null) ...page.slivers else ...widget.slivers,
      if (currentPage == 0)
        _WrapPadding(
          footer: description.footer,
          selectionGlue: functionality.selectionGlue,
          child: null,
        ),
    ];
  }

  Widget mainBody(BuildContext context, PageDescription? page) {
    final m = MediaQuery.of(context);

    return MediaQuery(
      data: m.copyWith(
        padding: m.padding +
            EdgeInsets.only(
              top: appBarBottomWidgetSize(page),
              bottom: hideAppBar ? loadingIndicatorSize : 0,
            ),
      ),
      child: Scrollbar(
        interactive: false,
        // thumbVisibility: !Platform.isAndroid && !Platform.isIOS,
        controller: controller,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: MediaQuery(
            data: m,
            child: CustomScrollView(
              key: atHomePage && page != null ? const PageStorageKey(0) : null,
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: bodySlivers(context, page),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final functionality = widget.functionality;
    final description = widget.description;
    final pageSwitcher = description.pages;

    final PageDescription? page = pageSwitcher != null && atNotHomePage
        ? pageSwitcher.buildPage(context, this, currentPage - 1)
        : null;

    final search = functionality.search;
    final FocusNode? searchFocus = page?.search?.focus ??
        (search is OverrideGridSearchWidget ? search.widget.focus : null);

    final gridSettingsWatcher = GridConfiguration.watcherOf(context);

    if (description.asSliver) {
      return PlayAnimations(
        key: _animationsKey,
        playAnimationsOn:
            widget.functionality.playAnimationOn + [gridSettingsWatcher],
        child: FocusNotifier(
          notifier: searchFocus,
          child: _GridSelectionCountHolder(
            calculatePadding: _bottomPadding,
            key: _holderKey,
            selection: selection,
            child: CellProvider<T>(
              getCell: source.forIdxUnsafe,
              child: GridExtrasNotifier(
                data: GridExtrasData(tryScrollUntil, selection, functionality),
                child: Builder(
                  builder: (context) {
                    Widget child = SliverMainAxisGroup(
                      slivers: bodySlivers(context, page),
                    );

                    final r = widget.functionality.registerNotifiers;
                    if (r != null) {
                      child = r(child);
                    }

                    return child;
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    final fab = functionality.fab;

    Widget child(BuildContext context) {
      final Widget ret = _BodyWrapping(
        bindings: const {},
        // mainFocus: widget.mainFocus,
        pageName: widget.description.keybindsDescription,
        children: [
          if (atHomePage && widget.description.pullToRefresh)
            RefreshIndicator(
              onRefresh: () {
                selection.reset(true);

                return source.clearRefresh();
              },
              child: mainBody(context, page),
            )
          else
            mainBody(context, page),
          if (description.footer != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Builder(
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: description.footer,
                  );
                },
              ),
            ),
          if (hideAppBar)
            Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: GridBottomPaddingProvider.of(context),
                    ),
                    child: PreferredSize(
                      preferredSize:
                          const Size.fromHeight(loadingIndicatorSize),
                      child: _LinearProgressIndicator(
                        progress: source.progress,
                      ),
                    ),
                  );
                },
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Builder(
              key: ValueKey((currentPage, _refreshes)),
              builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: 4,
                    bottom: GridBottomPaddingProvider.of(context) + 4,
                  ),
                  child: fab.widget(context, controller),
                );
              },
            ),
          ),
        ],
      );

      return ret;
    }

    Widget c = Builder(builder: child);

    if (functionality.registerNotifiers != null) {
      c = functionality.registerNotifiers!(c);
    }

    return PlayAnimations(
      key: _animationsKey,
      playAnimationsOn:
          widget.functionality.playAnimationOn + [gridSettingsWatcher],
      child: FocusNotifier(
        notifier: searchFocus,
        // focusMain: widget.mainFocus.requestFocus,
        child: _GridSelectionCountHolder(
          key: _holderKey,
          calculatePadding: _bottomPadding,
          selection: selection,
          child: CellProvider<T>(
            getCell: source.forIdxUnsafe,
            child: GridExtrasNotifier(
              data: GridExtrasData(tryScrollUntil, selection, functionality),
              child: c,
            ),
          ),
        ),
      ),
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
            padding: EdgeInsets.only(top: GridFrameState.loadingIndicatorSize),
            child: SizedBox(),
          )
        : const LinearProgressIndicator();
  }
}

class _GridSelectionCountHolder<T extends CellBase> extends StatefulWidget {
  const _GridSelectionCountHolder({
    required super.key,
    required this.selection,
    required this.calculatePadding,
    required this.child,
  });
  final GridSelection<T> selection;
  final double Function(BuildContext) calculatePadding;

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

  void _onPop(bool _) {
    if (widget.selection.isNotEmpty) {
      widget.selection.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.selection.isEmpty,
      onPopInvoked: _onPop,
      child: GridBottomPaddingProvider(
        fab: kFloatingActionButtonMargin * 2 + 24 + 8,
        padding: widget.calculatePadding(context),
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
  const GridExtrasData(this.scrollTo, this.selection, this.functionality);

  final void Function(int idx, GridSettingsData config) scrollTo;
  final GridSelection<T> selection;
  final GridFunctionality<T> functionality;
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
