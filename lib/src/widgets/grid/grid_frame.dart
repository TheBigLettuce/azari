// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show AspectRatio;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/plugs/download_movers/dart.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_back_button_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_fab_type.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_refresh_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/grid/parts/grid_app_bar_leading.dart';
import 'package:gallery/src/widgets/grid/parts/grid_app_bar_title.dart';
import 'package:gallery/src/widgets/grid/parts/page_switching_widget.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:logging/logging.dart';
import '../../interfaces/cell/cell.dart';
import '../../interfaces/grid/grid_mutation_interface.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import '../notifiers/focus.dart';
import 'grid_cell.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'parts/segment_label.dart';
import '../../interfaces/grid/selection_glue.dart';

part 'selection/grid_selection.dart';
part 'selection/wrap_selection.dart';
part 'mutation.dart';
part '../../interfaces/grid/segments.dart';
part '../../interfaces/grid/grid_action.dart';
part '../../interfaces/grid/grid_description.dart';
part '../../interfaces/grid/search_and_focus.dart';
part 'layouts/grid_layout_.dart';
part 'configuration/seg_sticky.dart';
part 'parts/app_bar.dart';
part 'wrappers/wrap_padding.dart';
part 'parts/body_padding.dart';
part 'parts/bottom_widget.dart';
part 'parts/mutation_interface_provider.dart';

/// The grid of images.
class GridFrame<T extends Cell> extends StatefulWidget {
  /// Grid gets the cell from [getCell].
  final T Function(int) getCell;

  /// [hasReachedEnd] should return true when the cell loading cannot load more.
  final bool Function() hasReachedEnd;

  // final int? backButtonBadge;

  /// The cell includes some keybinds by default.
  /// If [additionalKeybinds] is not null, they are added together.
  final Map<SingleActivatorDescription, Null Function()>? additionalKeybinds;

  /// If not null, [searchWidget] is displayed in the appbar.
  // final SearchAndFocus? searchWidget;

  /// If [initalCellCount] is not 0, then the grid won't call [refresh].
  final int initalCellCount;

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

  final ScrollController? overrideController;

  const GridFrame({
    required super.key,
    this.additionalKeybinds,
    required this.getCell,
    this.initalScrollPosition = 0,
    required this.functionality,
    required this.imageViewDescription,
    required this.systemNavigationInsets,
    required this.hasReachedEnd,
    this.onDispose,
    required this.mainFocus,
    this.belowMainFocus,
    this.overrideController,
    this.initalCellCount = 0,
    required this.description,
  });

  @override
  State<GridFrame<T>> createState() => GridFrameState<T>();
}

class GridFrameState<T extends Cell> extends State<GridFrame<T>>
    with GridSubpageState<T> {
  late final GridRefreshingStatus<T> refreshingStatus;
  late ScrollController controller;

  late final selection = GridSelection<T>(
    setState,
    widget.description.actions,
    widget.functionality.selectionGlue,
    () => controller,
    noAppBar: !widget.description.showAppBar,
    ignoreSwipe: widget.description.ignoreSwipeSelectGesture,
  );

  StreamSubscription<int>? ticker;

  late final GridMutationInterface<T> mutation = DefaultMutationInterface(
    initalCellCount: widget.initalCellCount,
    originalCell: widget.getCell,
    update: ({
      required bool imageView,
      required bool unselectAll,
    }) {
      if (imageView) {
        // imageViewKey.currentState?.update(context, _state.cellCount);
      }

      if (unselectAll) {
        selection.reset();
      }

      try {
        if (context.mounted) {
          setState(() {});
        }
      } catch (_) {}
    },
  );

  bool inImageView = false;

  List<int>? segTranslation;

  // final _fabKey = GlobalKey<__FabState>();

  void _refreshCallbackUpdate(int? i, bool refreshing) {
    mutation.isRefreshing = refreshing;
    if (i != null) {
      mutation.cellCount = i;
    }
  }

  void _restoreState(ImageViewDescription<T> imageViewDescription) {
    if (widget.initalCellCount != 0 &&
        imageViewDescription.pageViewScrollingOffset != null &&
        imageViewDescription.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        imageViewDescription.beforeImageViewRestore?.call();

        // onPressed(
        //     context, _state.getCell(widget.initalCell!), widget.initalCell!,
        //     offset: widget.pageViewScrollingOffset);
      });
    } else if (widget.initalCellCount != 0 &&
        imageViewDescription.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        imageViewDescription.beforeImageViewRestore?.call();

        // onPressed(
        //   context,
        //   _state.getCell(widget.initalCell!),
        //   widget.initalCell!,
        // );
      });
    } else {
      imageViewDescription.beforeImageViewRestore?.call();
    }
  }

  double lastOffset = 0;

  @override
  void initState() {
    super.initState();

    final description = widget.description;
    final functionality = widget.functionality;

    controller = description.asSliver && widget.overrideController != null
        ? widget.overrideController!
        : ScrollController(initialScrollOffset: widget.initalScrollPosition);

    ticker = functionality.progressTicker?.listen((event) {
      mutation.cellCount = event;
    });

    _restoreState(widget.imageViewDescription);

    refreshingStatus = GridRefreshingStatus._(mutation, functionality);

    final refreshBehaviour = functionality.refreshBehaviour;
    switch (refreshBehaviour) {
      case DefaultGridRefreshBehaviour():
        break;
      case RetainedGridRefreshBehaviour():
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          refreshBehaviour.interface.register(_refreshCallbackUpdate);

          final isRefreshing = refreshBehaviour.interface.isRefreshing();
          mutation.isRefreshing = isRefreshing;
        });
    }

    if (widget.initalCellCount == 0) {
      refreshingStatus.refresh();
    }

    if (!description.asSliver) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        controller = widget.overrideController ?? ScrollController();

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          // _addFabListener();
          _registerOffsetSaver(controller);
        });

        if (functionality.loadNext == null) {
          return;
        }

        controller.addListener(() {
          lastOffset = controller.offset;

          if (widget.hasReachedEnd() || atNotHomePage) {
            return;
          }

          final h = MediaQuery.sizeOf(context).height;

          final height = h - h * 0.80;

          if (!mutation.isRefreshing &&
              mutation.cellCount != 0 &&
              (controller.offset /
                      controller.positions.first.maxScrollExtent) >=
                  1 - (height / controller.positions.first.maxScrollExtent)) {
            refreshingStatus.onNearEnd();
            // _state._loadNext(context);
          }
        });

        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    ticker?.cancel();

    if (widget.overrideController == null) {
      controller.dispose();
    }

    widget.belowMainFocus?.requestFocus();

    final refreshBehaviour = widget.functionality.refreshBehaviour;
    switch (refreshBehaviour) {
      case DefaultGridRefreshBehaviour():
        break;
      case RetainedGridRefreshBehaviour():
        WidgetsBinding.instance.scheduleFrameCallback((_) {
          if (!mutation.isRefreshing) {
            refreshBehaviour.interface.reset();
          }

          refreshBehaviour.interface.unregister(_refreshCallbackUpdate);
        });
    }

    widget.onDispose?.call();

    widget.functionality.updateScrollPosition?.call(lastOffset);

    super.dispose();
  }

  Future refresh([Future<int> Function()? overrideRefresh]) {
    selection.reset();
    mutation.reset();
    // updateFab(fab: false, foreground: inImageView);

    return refreshingStatus.refresh(overrideRefresh);
  }

  void tryScrollUntil(int p) {
    if (controller.position.maxScrollExtent.isInfinite) {
      return;
    }

    final picPerRow = widget.description.layout.columns;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (widget.description.layout.isList) {
      target = contentSize * p / mutation.cellCount;
    } else {
      target = contentSize *
          (p / picPerRow!.number - 1) /
          (mutation.cellCount / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      widget.functionality.updateScrollPosition
          ?.call(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (widget.hasReachedEnd()) {
        widget.functionality.updateScrollPosition
            ?.call(controller.position.maxScrollExtent);
        return;
      }
    }

    widget.functionality.updateScrollPosition?.call(target);

    controller.jumpTo(target);
  }

  // Map<SingleActivatorDescription, void Function()> _makeBindings(
  //         BuildContext context) =>
  //     {
  //       SingleActivatorDescription(AppLocalizations.of(context)!.refresh,
  //           const SingleActivator(LogicalKeyboardKey.f5)): _state._f5,
  //       if (widget.searchWidget != null &&
  //           widget.searchWidget!.onPressed != null)
  //         SingleActivatorDescription(
  //                 AppLocalizations.of(context)!.selectSuggestion,
  //                 const SingleActivator(LogicalKeyboardKey.enter, shift: true)):
  //             () {
  //           widget.searchWidget?.onPressed!();
  //         },
  //       if (widget.searchWidget != null)
  //         SingleActivatorDescription(
  //             AppLocalizations.of(context)!.focusSearch,
  //             const SingleActivator(LogicalKeyboardKey.keyF,
  //                 control: true)): () {
  //           if (widget.searchWidget == null) {
  //             return;
  //           }

  //           if (widget.searchWidget!.focus.hasFocus) {
  //             widget.mainFocus.requestFocus();
  //           } else {
  //             widget.searchWidget!.focus.requestFocus();
  //           }
  //         },
  //       if (widget.onBack != null)
  //         SingleActivatorDescription(AppLocalizations.of(context)!.back,
  //             const SingleActivator(LogicalKeyboardKey.escape)): () {
  //           selection.selected.clear();
  //           selection.glue.close();
  //           widget.onBack!();
  //         },
  //       if (widget.additionalKeybinds != null) ...widget.additionalKeybinds!,
  //     };

  List<Widget> _makeActions(
      BuildContext context, GridDescription<T> description) {
    if (description.menuButtonItems == null) {
      return [];
    }

    return (!description.inlineMenuButtonItems &&
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
          ];
  }

  List<Widget> bodySlivers(BuildContext context, PageDescription? page) {
    final description = widget.description;
    final functionality = widget.functionality;

    Widget? appBar;
    if (description.showAppBar) {
      final appBarActions =
          page != null ? page.appIcons : _makeActions(context, description);

      final bottomWidget = description.bottomWidget != null
          ? description.bottomWidget!
          : _BottomWidget<T>(
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
        ...description.layout(context, this),
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
      return GridBottomPaddingProvider(
        padding: _calculateBottomPadding(),
        child: FocusNotifier(
          notifier: searchFocus,
          focusMain: widget.mainFocus.requestFocus,
          child: MutationInterfaceProvider<T>(
            state: mutation,
            child: SliverMainAxisGroup(
              slivers: bodySlivers(context, page),
            ),
          ),
        ),
      );
    }

    final fab = functionality.fab;

    Widget child = _BodyWrapping(
      bindings: const {},
      mainFocus: widget.mainFocus,
      pageName: widget.description.keybindsDescription,
      children: [
        if (atHomePage)
          RefreshIndicator(
            onRefresh: refreshingStatus.refresh,
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
        if (!widget.description.showAppBar || widget.description.pages != null)
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
            child: PrimaryScrollController(
              controller: controller,
              child: Builder(
                builder: (context) {
                  return fab.widget(context, ValueKey(currentPage));
                },
              ),
            ),
          ),
        ),
      ],
    );

    if (functionality.registerNotifiers != null) {
      child = functionality.registerNotifiers!(child);
    }

    return GridBottomPaddingProvider(
      padding: _calculateBottomPadding(),
      child: FocusNotifier(
        notifier: searchFocus,
        focusMain: widget.mainFocus.requestFocus,
        child: MutationInterfaceProvider(
          state: mutation,
          child: child,
        ),
      ),
    );
  }
}

mixin GridSubpageState<T extends Cell> on State<GridFrame<T>> {
  int currentPage = 0;
  double savedOffset = 0;

  bool get atHomePage => currentPage == 0;
  bool get atNotHomePage => !atHomePage;

  void _registerOffsetSaver(ScrollController controller) {
    final f = widget.functionality.updateScrollPosition;
    if (f == null) {
      return;
    }

    controller.position.isScrollingNotifier.addListener(() {
      f(controller.offset);
    });
  }

  void onSubpageSwitched(
      int next, GridSelection<T> selection, ScrollController controller) {
    selection.reset();

    if (atHomePage) {
      savedOffset = controller.offset;
    }

    // updateFab(
    //   fab: false,
    //   foreground: false,
    // );

    currentPage = next;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // _addFabListener();
      if (next == 0) {
        _registerOffsetSaver(controller);
      }

      if (atHomePage && controller.offset == 0 && savedOffset != 0) {
        controller.position
            .animateTo(savedOffset, duration: 200.ms, curve: Easing.standard);

        savedOffset = 0;
      }
    });

    setState(() {});
  }
}

class GridBottomPaddingProvider extends InheritedWidget {
  final double padding;

  const GridBottomPaddingProvider({
    super.key,
    required this.padding,
    required super.child,
  });

  static double of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GridBottomPaddingProvider>();

    return widget!.padding;
  }

  @override
  bool updateShouldNotify(GridBottomPaddingProvider oldWidget) =>
      padding != oldWidget.padding;
}

class GridRefreshingStatus<T extends Cell> {
  GridRefreshingStatus._(
    this.mutation,
    this.functionality,
  );

  final GridMutationInterface<T> mutation;
  final GridFunctionality<T> functionality;

  bool _locked = false;

  Object? refreshingError;

  void unlock() {
    _locked = false;
  }

  Future<int> refresh([Future<int> Function()? overrideRefresh]) {
    if (_locked) {
      return Future.value(mutation.cellCount);
    }
    _locked = true;

    final refresh = functionality.refresh;
    switch (refresh) {
      case SynchronousGridRefresh():
        mutation.cellCount = refresh.refresh();

        return Future.value(mutation.cellCount);
      case AsyncGridRefresh():
        final f =
            overrideRefresh != null ? overrideRefresh() : refresh.refresh();

        refreshingError = null;
        mutation.isRefreshing = true;
        mutation.cellCount = 0;

        return _saveOrWait(f);
      case RetainedGridRefresh():
        refresh.refresh();
        return Future.value(0);
      case MutationInterfaceSourcedGridRefresh():
        return Future.value(mutation.cellCount);
    }
  }

  Future<int> onNearEnd() async {
    if (_locked || functionality.loadNext == null || mutation.isRefreshing) {
      return Future.value(mutation.cellCount);
    }

    _locked = true;

    final f = functionality.loadNext!();
    mutation.isRefreshing = true;

    return _saveOrWait(f);
  }

  Future<int> _saveOrWait(Future<int> f) async {
    final refreshBehaviour = functionality.refreshBehaviour;
    switch (refreshBehaviour) {
      case DefaultGridRefreshBehaviour():
        try {
          mutation.cellCount = await f;
        } catch (e) {
          refreshingError = e;
        }

        mutation.isRefreshing = false;
        _locked = false;

        return mutation.cellCount;
      case RetainedGridRefreshBehaviour():
        refreshBehaviour.interface.save(f.then((value) {
          mutation.cellCount = value;
          mutation.isRefreshing = false;
          _locked = false;

          return value;
        }));
        return mutation.cellCount;
    }
  }
}
