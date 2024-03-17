// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_subpage_state.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_app_bar_leading.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_app_bar_title.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_bottom_padding_provider.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';
import 'package:gallery/src/widgets/grid_frame/parts/page_switching_widget.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import '../../interfaces/cell/cell.dart';
import 'configuration/grid_mutation_interface.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import '../notifiers/focus.dart';

import 'configuration/selection_glue.dart';

part 'configuration/grid_selection.dart';
part 'wrappers/wrap_selection.dart';
part 'configuration/mutation.dart';
part 'configuration/segments.dart';
part 'configuration/grid_action.dart';
part 'configuration/grid_description.dart';
part 'configuration/search_and_focus.dart';
part 'parts/app_bar.dart';
part 'wrappers/wrap_padding.dart';
part 'parts/body_padding.dart';
part 'parts/bottom_widget.dart';
part 'parts/mutation_interface_provider.dart';

typedef MakeCellFunc<T extends Cell> = GridCell<T> Function(BuildContext, int);

/// The grid of images.
class GridFrame<T extends Cell> extends StatefulWidget {
  /// Grid gets the cell from [getCell].
  final T Function(int) getCell;

  /// [initalScrollPosition] is needed for the state restoration.
  /// If [initalScrollPosition] is not 0, then it is set as the starting scrolling position.
  final double initalScrollPosition;

  /// Padding of the system navigation, like the system bottom navigation bar.
  final EdgeInsets systemNavigationInsets;

  /// The main focus node of the grid.
  final FocusNode mainFocus;

  final GridFunctionality<T> functionality;

  /// Some additional metadata about the grid.
  final GridDescription<T> description;

  final ImageViewDescription<T> imageViewDescription;

  /// If [belowMainFocus] is not null, then when the grid gets disposed
  /// [belowMainFocus.requestFocus] get called.
  final FocusNode? belowMainFocus;

  final void Function()? onDispose;

  final GridRefreshingStatus<T> refreshingStatus;

  final ScrollController? overrideController;

  final GridLayoutBehaviour layout;

  const GridFrame({
    required super.key,
    required this.getCell,
    this.initalScrollPosition = 0,
    required this.functionality,
    required this.imageViewDescription,
    required this.systemNavigationInsets,
    this.onDispose,
    required this.layout,
    required this.mainFocus,
    this.belowMainFocus,
    required this.refreshingStatus,
    this.overrideController,
    required this.description,
  });

  @override
  State<GridFrame<T>> createState() => GridFrameState<T>();
}

class GridFrameState<T extends Cell> extends State<GridFrame<T>>
    with GridSubpageState<T> {
  StreamSubscription<void>? _gridSettingsWatcher;
  late final StreamSubscription<void> _mutationEvents;

  late ScrollController controller;
  // bool swappedController = false;

  late GridSettingsBase _layoutSettings = widget.layout.defaultSettings();

  late final selection = GridSelection<T>(
    setState,
    widget.description.actions,
    widget.functionality.selectionGlue,
    () => controller,
    noAppBar: !widget.description.showAppBar,
    ignoreSwipe: widget.description.ignoreSwipeSelectGesture,
  );

  GridRefreshingStatus<T> get refreshingStatus => widget.refreshingStatus;
  GridMutationInterface<T> get mutation => refreshingStatus.mutation;

  bool inImageView = false;

  List<int>? segTranslation;

  void _restoreState(ImageViewDescription<T> imageViewDescription) {
    imageViewDescription.beforeImageViewRestore?.call();
  }

  late double lastOffset = widget.initalScrollPosition;

  @override
  void initState() {
    super.initState();

    _mutationEvents =
        widget.refreshingStatus.mutation.registerStatusUpdate((_) {
      setState(() {});
    });
    _gridSettingsWatcher =
        widget.functionality.watchLayoutSettings?.call((newSettings) {
      _layoutSettings = newSettings;

      setState(() {});
    });

    final description = widget.description;
    final functionality = widget.functionality;

    controller = description.asSliver && widget.overrideController != null
        ? widget.overrideController!
        : ScrollController(initialScrollOffset: widget.initalScrollPosition);

    _restoreState(widget.imageViewDescription);

    if (mutation.cellCount == 0) {
      refreshingStatus.refresh(widget.functionality);
    }

    if (!description.asSliver) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        controller = widget.overrideController ?? ScrollController();

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          registerOffsetSaver(controller);
        });

        setState(() {});

        if (functionality.loadNext == null) {
          return;
        }

        controller.addListener(() {
          lastOffset = controller.offset;

          if (refreshingStatus.reachedEnd || atNotHomePage) {
            return;
          }

          final h = MediaQuery.sizeOf(context).height;

          final height = h - h * 0.80;

          if (!mutation.isRefreshing &&
              mutation.cellCount != 0 &&
              (controller.offset /
                      controller.positions.first.maxScrollExtent) >=
                  1 - (height / controller.positions.first.maxScrollExtent)) {
            refreshingStatus.onNearEnd(widget.functionality);
          }
        });
      });
    }
  }

  bool _enableAnimations = false;

  void enableAnimationsFor(
      [Duration duration = const Duration(milliseconds: 300)]) {
    setState(() {
      _enableAnimations = true;
    });

    Future.delayed(duration, () {
      try {
        _enableAnimations = false;

        setState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _mutationEvents.cancel();
    _gridSettingsWatcher?.cancel();

    if (widget.overrideController == null) {
      controller.dispose();
    }

    widget.belowMainFocus?.requestFocus();

    widget.onDispose?.call();

    widget.functionality.updateScrollPosition?.call(lastOffset);

    super.dispose();
  }

  void tryScrollUntil(int p) {
    if (controller.position.maxScrollExtent.isInfinite) {
      return;
    }

    final picPerRow = _layoutSettings.columns;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (_layoutSettings.layoutType.layout().isList) {
      target = contentSize * p / mutation.cellCount;
    } else {
      target = contentSize *
          (p / picPerRow.number - 1) /
          (mutation.cellCount / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      widget.functionality.updateScrollPosition
          ?.call(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (refreshingStatus.reachedEnd) {
        widget.functionality.updateScrollPosition
            ?.call(controller.position.maxScrollExtent);
        return;
      }
    }

    widget.functionality.updateScrollPosition?.call(target);

    controller.jumpTo(target);
  }

  List<Widget> _makeActions(
      BuildContext context, GridDescription<T> description) {
    final button = widget.description.settingsButton;

    final ret = <Widget>[
      if (button != null)
        GridSettingsButton(
          () => _layoutSettings,
          watch: widget.functionality.watchLayoutSettings,
          selectRatio: button.selectRatio,
          selectHideName: button.selectHideName,
          selectGridLayout: button.selectGridLayout,
          selectGridColumn: button.selectGridColumn,
          safeMode: button.safeMode,
          selectSafeMode: button.selectSafeMode,
          onChanged: enableAnimationsFor,
        )
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
                            (e) => PopupMenuItem(
                              enabled: false,
                              child: e,
                            ),
                          )
                          .toList();
                    })
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
              if (pageSettingsButton != null)
                GridSettingsButton(
                  pageSettingsButton.overrideDefault!,
                  watch: pageSettingsButton.watchExplicitly,
                  selectRatio: pageSettingsButton.selectRatio,
                  selectHideName: pageSettingsButton.selectHideName,
                  selectGridLayout: pageSettingsButton.selectGridLayout,
                  selectGridColumn: pageSettingsButton.selectGridColumn,
                  safeMode: pageSettingsButton.safeMode,
                  selectSafeMode: pageSettingsButton.selectSafeMode,
                  onChanged: enableAnimationsFor,
                ),
            ]
          : _makeActions(context, description);

      final bottomWidget = description.bottomWidget != null
          ? description.bottomWidget!
          : _BottomWidget<T>(
              isRefreshing: mutation.isRefreshing,
              routeChanger: page != null && page.search == null
                  ? const SizedBox.shrink()
                  : widget.description.pages != null
                      ? PageSwitchingWidget(
                          controller: controller,
                          selection: selection,
                          padding: EdgeInsets.only(
                            top: Platform.isAndroid ? 8 : 12,
                            bottom: Platform.isAndroid ? 8 : 12,
                          ),
                          state: this,
                          pageSwitcher: widget.description.pages!,
                        )
                      : null,
              preferredSize: Size.fromHeight(
                ((page?.search == null && !atHomePage) ||
                            widget.description.pages == null
                        ? 0
                        : (Platform.isAndroid ? 40 + 16 : 32 + 24)) +
                    (page == null ? 4 : 0),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: page == null ? 4 : 0),
                child: const SizedBox.shrink(),
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
      if (appBar != null) appBar,
      if (page != null)
        ...page.slivers
      else ...[
        if (!mutation.isRefreshing &&
            mutation.cellCount == 0 &&
            !description.ignoreEmptyWidgetOnNoContent)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyWidget(
                    gridSeed: 0,
                    error: refreshingStatus.refreshingError == null
                        ? null
                        : EmptyWidget.unwrapDioError(
                            refreshingStatus.refreshingError),
                  ),
                  if (functionality.onError != null &&
                      refreshingStatus.refreshingError != null)
                    functionality.onError!(refreshingStatus.refreshingError!),
                ],
              ),
            ),
          ),
        ...widget.layout.makeFor<T>(_layoutSettings)(
            context, _layoutSettings, this),
      ],
      _WrapPadding<T>(
        systemNavigationInsets: widget.systemNavigationInsets.bottom,
        footer: description.footer,
        selectionGlue: functionality.selectionGlue,
        child: null,
      )
    ];
  }

  Widget mainBody(BuildContext context, PageDescription? page) => Scrollbar(
        interactive: false,
        thumbVisibility: Platform.isAndroid || Platform.isIOS ? false : true,
        controller: controller,
        child: CustomScrollView(
          key: atHomePage && page != null ? const PageStorageKey(0) : null,
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: bodySlivers(context, page),
        ),
      );

  double _calculateBottomPadding() {
    final functionality = widget.functionality;
    final selectionGlue = functionality.selectionGlue;
    final description = widget.description;

    return (functionality.selectionGlue.keyboardVisible()
            ? 0
            : widget.systemNavigationInsets.bottom +
                (selectionGlue.isOpen()
                    ? selectionGlue.barHeight()
                    : selectionGlue.persistentBarHeight
                        ? selectionGlue.barHeight()
                        : 0)) +
        (description.footer != null
            ? description.footer!.preferredSize.height
            : 0);
  }

  @override
  Widget build(BuildContext context) {
    segTranslation = null;

    final functionality = widget.functionality;
    final description = widget.description;
    final pageSwitcher = description.pages;

    final PageDescription? page = pageSwitcher != null && atNotHomePage
        ? pageSwitcher.buildPage(currentPage - 1)
        : null;

    final search = functionality.search;
    final FocusNode? searchFocus = page?.search?.focus ??
        (search is OverrideGridSearchWidget ? search.widget.focus : null);

    if (description.asSliver) {
      return PlayAnimationNotifier(
        play: _enableAnimations,
        child: GridBottomPaddingProvider(
          padding: _calculateBottomPadding(),
          child: FocusNotifier(
            notifier: searchFocus,
            focusMain: widget.mainFocus.requestFocus,
            child: CellProvider<T>(
              getCell: widget.getCell,
              child: Builder(
                builder: (context) {
                  return SliverMainAxisGroup(
                    slivers: bodySlivers(context, page),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    final fab = functionality.fab;

    Widget child(BuildContext context) {
      Widget ret = _BodyWrapping(
        bindings: const {},
        mainFocus: widget.mainFocus,
        pageName: widget.description.keybindsDescription,
        children: [
          if (atHomePage && widget.functionality.refresh.pullToRefresh)
            RefreshIndicator(
              onRefresh: () => refreshingStatus.refresh(widget.functionality),
              child: mainBody(context, page),
            )
          else
            mainBody(context, page),
          if (description.footer != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: widget.systemNavigationInsets.bottom,
                ),
                child: description.footer!,
              ),
            ),
          if (!widget.description.showAppBar ||
              widget.description.pages != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: _calculateBottomPadding(),
                ),
                child: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: !mutation.isRefreshing
                      ? const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: SizedBox(),
                        )
                      : const LinearProgressIndicator(),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                  right: 4, bottom: _calculateBottomPadding() + 4),
              child: fab.widget(context, controller),
            ),
          ),
        ],
      );
      if (functionality.registerNotifiers != null) {
        ret = functionality.registerNotifiers!(ret);
      }

      if (widget.description.risingAnimation) {
        ret = _RisingAnimation(key: ValueKey(currentPage), child: ret);
      }

      return ret;
    }

    return PlayAnimationNotifier(
      play: _enableAnimations,
      child: GridBottomPaddingProvider(
        padding: _calculateBottomPadding(),
        child: FocusNotifier(
          notifier: searchFocus,
          focusMain: widget.mainFocus.requestFocus,
          child: CellProvider<T>(
            getCell: widget.getCell,
            child: Builder(
              builder: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayAnimationNotifier extends InheritedWidget {
  final bool play;

  const PlayAnimationNotifier({
    super.key,
    required this.play,
    required super.child,
  });

  static bool? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PlayAnimationNotifier>();

    return widget?.play;
  }

  @override
  bool updateShouldNotify(PlayAnimationNotifier oldWidget) =>
      play != oldWidget.play;
}

class _RisingAnimation extends StatelessWidget {
  final Widget child;

  const _RisingAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: true,
      effects: [
        FadeEffect(begin: 0, end: 1, duration: 400.ms, curve: Easing.standard),
        MoveEffect(
            begin: const Offset(0, 60),
            end: const Offset(0, 0),
            duration: 400.ms,
            curve: Easing.standard),
      ],
      child: child,
    );
  }
}
