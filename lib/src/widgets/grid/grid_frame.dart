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
import 'package:gallery/src/interfaces/note_interface.dart';
import 'package:gallery/src/interfaces/refreshing_status_interface.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:logging/logging.dart';
import '../../interfaces/cell/cell.dart';
import '../../interfaces/grid/grid_mutation_interface.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import '../notifiers/focus.dart';
import 'grid_cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'segment_label.dart';
import '../../interfaces/grid/selection_glue.dart';

part 'selection/grid_selection.dart';
part 'selection/wrap_selection.dart';
part 'mutation.dart';
part '../../interfaces/grid/segments.dart';
part '../../interfaces/grid/grid_action.dart';
part '../../interfaces/grid/grid_description.dart';
part '../../interfaces/grid/search_and_focus.dart';
part 'layouts/grid_layout_.dart';
part 'fab.dart';

class _SegSticky {
  final String seg;
  final bool sticky;
  final void Function()? onLabelPressed;
  final bool unstickable;

  const _SegSticky(this.seg, this.sticky, this.onLabelPressed,
      {this.unstickable = true});
}

/// The grid of images.
class GridFrame<T extends Cell> extends StatefulWidget {
  /// [loadNext] gets called when the grid is scrolled around the end of the viewport.
  /// If this is null, then the grid is assumed to be not able to incrementally add posts
  /// by scrolling at the near end of the viewport.
  final Future<int> Function()? loadNext;

  /// In case if the cell represents an online resource which can be downloaded,
  /// setting [download] enables buttons to download the resource.
  final Future<void> Function(int indx)? download;

  /// Refresh the grid.
  /// If [refresh] returns null, it means no posts can be loaded more,
  /// which means that if [loadNext] is not null it wont be called more.
  final Future<int>? Function() refresh;

  /// [updateScrollPosition] gets called when grid first builds and then when scrolling stops,
  ///  if not null. Useful when it is desirable to persist the scroll position of the grid.
  /// [infoPos] represents the scroll position in the "Info" of the image view,
  ///  and [selectedCell] represents the inital page of the image view.
  /// State restoration takes this info into the account.
  final void Function(double pos, {double? infoPos, int? selectedCell})?
      updateScrollPosition;

  /// If [onBack] is not null, then a back button will be displayed in the appbar,
  /// which would call this callback when pressed.
  final void Function()? onBack;

  final int? backButtonBadge;

  /// Overrides the default behaviour of launching the image view on cell pressed.
  /// [overrideOnPress] can, for example, include calls to [Navigator.push] of routes.
  final void Function(BuildContext context, T cell)? overrideOnPress;

  // final bool unpressable;

  /// Grid gets the cell from [getCell].
  final T Function(int) getCell;

  /// [hasReachedEnd] should return true when the cell loading cannot load more.
  final bool Function() hasReachedEnd;

  /// The cell includes some keybinds by default.
  /// If [additionalKeybinds] is not null, they are added together.
  final Map<SingleActivatorDescription, Null Function()>? additionalKeybinds;

  /// If not null, [searchWidget] is displayed in the appbar.
  final SearchAndFocus? searchWidget;

  /// If [initalCellCount] is not 0, then the grid won't call [refresh].
  final int initalCellCount;

  /// [initalCell] is needed for the state restoration.
  /// If [initalCell] is not null the grid will launch image view setting [ImageView.startingCell] as this value.
  final int? initalCell;

  /// [initalScrollPosition] is needed for the state restoration.
  /// If [initalScrollPosition] is not 0, then it is set as the starting scrolling position.
  final double initalScrollPosition;

  /// [pageViewScrollingOffset] is needed for the state restoration.
  /// If not null, [pageViewScrollingOffset] gets supplied to the [ImageView.infoScrollOffset].
  final double? pageViewScrollingOffset;

  /// Used for enabling bottom sheets and the drawer.
  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Items added in the menu button's children, after the [searchWidget], or the page name
  /// if [searchWidget] is null. If [menuButtonItems] includes only one widget,
  /// it is displayed directly.
  final List<Widget>? menuButtonItems;

  /// Padding of the system navigation, like the system bottom navigation bar.
  final EdgeInsets systemNavigationInsets;

  /// The main focus node of the grid.
  final FocusNode mainFocus;

  /// If the elemnts of the grid arrive in batches [progressTicker] can be set to not null,
  /// grid will subscribe to it and set the cell count from this ticker's events.
  final Stream<int>? progressTicker;

  /// Some additional metadata about the grid.
  final GridDescription<T> description;

  /// If [belowMainFocus] is not null, then when the grid gets disposed
  /// [belowMainFocus.requestFocus] get called.
  final FocusNode? belowMainFocus;

  /// Supplied to [ImageView.addIcons].
  final List<GridAction<T>> Function(T)? addIconsImage;

  /// Supplied to [ImageView.pageChange].
  final void Function(ImageViewState<T> state)? pageChangeImage;

  /// Makes [menuButtonItems] appear as app bar items.
  final bool inlineMenuButtonItems;

  final PreferredSizeWidget? footer;

  final Widget Function(Object error)? onError;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final void Function()? onExitImageView;

  final void Function()? beforeImageViewRestore;

  final bool showCount;

  final SelectionGlue<T> selectionGlue;
  final Widget? overrideBackButton;

  final NoteInterface<T>? noteInterface;

  final ImageViewStatistics? statistics;

  final bool ignoreImageViewEndDrawer;

  final RefreshingStatusInterface? refreshInterface;

  final void Function()? onDispose;

  // static CallbackGridState<T> of<T extends Cell>(BuildContext context) {
  //   return context.findAncestorStateOfType<CallbackGridState<T>>()!;
  // }

  const GridFrame({
    required super.key,
    this.additionalKeybinds,
    required this.getCell,
    required this.initalScrollPosition,
    required this.scaffoldKey,
    required this.systemNavigationInsets,
    required this.hasReachedEnd,
    this.pageChangeImage,
    this.onError,
    this.onDispose,
    this.statistics,
    required this.selectionGlue,
    this.showCount = false,
    this.overrideBackButton,
    this.beforeImageViewRestore,
    required this.mainFocus,
    this.addIconsImage,
    this.onExitImageView,
    this.refreshInterface,
    this.footer,
    this.registerNotifiers,
    this.backButtonBadge,
    this.belowMainFocus,
    this.inlineMenuButtonItems = false,
    this.progressTicker,
    this.menuButtonItems,
    this.ignoreImageViewEndDrawer = false,
    this.searchWidget,
    this.initalCell,
    this.pageViewScrollingOffset,
    this.loadNext,
    this.noteInterface,
    required this.refresh,
    this.updateScrollPosition,
    this.download,
    this.onBack,
    this.initalCellCount = 0,
    this.overrideOnPress,
    required this.description,
  });

  @override
  State<GridFrame<T>> createState() => GridFrameState<T>();
}

class GridFrameState<T extends Cell> extends State<GridFrame<T>> {
  late final controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);
  final fakeController = ScrollController();

  final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();

  late final selection = GridSelection<T>._(
      setState, widget.description.actions, widget.selectionGlue, controller,
      noAppBar: !widget.description.showAppBar,
      ignoreSwipe: widget.description.ignoreSwipeSelectGesture);

  StreamSubscription<int>? ticker;

  GridMutationInterface<T> get mutationInterface => _state;

  bool inImageView = false;

  List<int>? segTranslation;

  final _fabKey = GlobalKey<__FabState>();

  void updateFab({required bool fab, required bool foreground}) {
    if (fab != _fabKey.currentState?.showFab) {
      _fabKey.currentState?.showFab = fab;
      if (!foreground) {
        try {
          // widget.hideShowNavBar(!showFab);
          _fabKey.currentState?.setState(() {});
        } catch (_) {}
      }
    }
  }

  late final _Mutation<T> _state = _Mutation(
    updateImageView: () {
      imageViewKey.currentState?.update(context, _state.cellCount);
    },
    scrollUp: () {
      updateFab(fab: false, foreground: inImageView);
    },
    unselectall: () {
      selection.selected.clear();
      selection.glue.close();
    },
    saveStatus: widget.refreshInterface == null
        ? null
        : (status) {
            widget.refreshInterface?.save(status);
          },
    widget: () => widget,
    update: (f) {
      try {
        if (context.mounted) {
          f?.call();

          setState(() {});
        }
      } catch (_) {}
    },
  );

  void _refreshCallbackUpdate(int? i, bool refreshing) {
    _state._refreshing = refreshing;
    if (i != null) {
      _state.tick(i);
    }

    _state.updateImageView();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    ticker = widget.progressTicker?.listen((event) {
      setState(() {
        _state._cellCount = event;
      });
    });

    if (widget.initalCellCount != 0 &&
        widget.pageViewScrollingOffset != null &&
        widget.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        widget.beforeImageViewRestore?.call();

        // onPressed(
        //     context, _state.getCell(widget.initalCell!), widget.initalCell!,
        //     offset: widget.pageViewScrollingOffset);
      });
    } else if (widget.initalCellCount != 0 && widget.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        widget.beforeImageViewRestore?.call();

        // onPressed(
        //   context,
        //   _state.getCell(widget.initalCell!),
        //   widget.initalCell!,
        // );
      });
    } else {
      widget.beforeImageViewRestore?.call();
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.refreshInterface?.register(_refreshCallbackUpdate);

      controller.position.isScrollingNotifier.addListener(() {
        // if (!_state.isRefreshing) {
        widget.updateScrollPosition?.call(controller.offset);
        // }

        if (controller.offset == 0) {
          updateFab(fab: false, foreground: inImageView);
        } else {
          updateFab(
              fab: !controller.position.isScrollingNotifier.value,
              foreground: inImageView);
        }
      });
    });

    if (widget.initalCellCount != 0) {
      _state._cellCount = widget.initalCellCount;
    } else if (widget.refreshInterface == null ||
        !widget.refreshInterface!.isRefreshing()) {
      refresh();
    } else {
      _state._refreshing = true;
    }

    if (widget.loadNext == null) {
      return;
    }

    controller.addListener(() {
      if (widget.hasReachedEnd()) {
        return;
      }

      final h = MediaQuery.sizeOf(context).height;

      final height = h - h * 0.80;

      if (!_state.isRefreshing &&
          _state.cellCount != 0 &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              1 - (height / controller.positions.first.maxScrollExtent)) {
        _state._loadNext(context);
      }
    });
  }

  @override
  void dispose() {
    ticker?.cancel();

    controller.dispose();
    widget.belowMainFocus?.requestFocus();
    fakeController.dispose();

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (!_state.isRefreshing) {
        widget.refreshInterface?.reset();
      }

      widget.refreshInterface?.unregister(_refreshCallbackUpdate);
    });

    widget.onDispose?.call();

    super.dispose();
  }

  Future refresh([Future<int> Function()? overrideRefresh]) {
    selection.selected.clear();
    selection.glue.close();
    updateFab(fab: false, foreground: inImageView);

    _state._cellCount = 0;

    return _state._refresh(overrideRefresh);
  }

  void _scrollUntill(int p) {
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
      target = contentSize * p / _state.cellCount;
    } else {
      target = contentSize *
          (p / picPerRow!.number - 1) /
          (_state.cellCount / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      widget.updateScrollPosition?.call(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (widget.hasReachedEnd()) {
        widget.updateScrollPosition?.call(controller.position.maxScrollExtent);
        return;
      }
    }

    widget.updateScrollPosition?.call(target);

    controller.jumpTo(target);
  }

  void onPressed(BuildContext gridContext, T cell, int startingCell,
      {double? offset}) {
    if (widget.overrideOnPress != null) {
      widget.mainFocus.requestFocus();
      widget.overrideOnPress!(gridContext, cell);
      return;
    }
    inImageView = true;

    widget.mainFocus.requestFocus();

    final offsetGrid = controller.offset;
    final overlayColor =
        Theme.of(gridContext).colorScheme.background.withOpacity(0.5);

    widget.selectionGlue.hideNavBar(true);

    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) {
      return ImageView<T>(
          key: imageViewKey,
          gridContext: gridContext,
          statistics: widget.statistics,
          registerNotifiers: widget.registerNotifiers,
          systemOverlayRestoreColor: overlayColor,
          updateTagScrollPos: (pos, selectedCell) => widget.updateScrollPosition
              ?.call(offsetGrid, infoPos: pos, selectedCell: selectedCell),
          scrollUntill: _scrollUntill,
          pageChange: widget.pageChangeImage,
          onExit: () {
            inImageView = false;
            widget.onExitImageView?.call();
          },
          ignoreEndDrawer: widget.ignoreImageViewEndDrawer,
          addIcons: widget.addIconsImage,
          focusMain: () {
            widget.mainFocus.requestFocus();
          },
          infoScrollOffset: offset,
          predefinedIndexes: segTranslation,
          getCell: _state.getCell,
          noteInterface: widget.noteInterface,
          cellCount: _state.cellCount,
          download: widget.download,
          startingCell: segTranslation != null
              ? () {
                  for (final (i, e) in segTranslation!.indexed) {
                    if (e == startingCell) {
                      return i;
                    }
                  }

                  return 0;
                }()
              : startingCell,
          onNearEnd: widget.loadNext == null ? null : _state._onNearEnd);
    })).then((value) => widget.selectionGlue.hideNavBar(false));
  }

  Map<SingleActivatorDescription, void Function()> _makeBindings(
          BuildContext context) =>
      {
        SingleActivatorDescription(AppLocalizations.of(context)!.refresh,
            const SingleActivator(LogicalKeyboardKey.f5)): _state._f5,
        if (widget.searchWidget != null &&
            widget.searchWidget!.onPressed != null)
          SingleActivatorDescription(
                  AppLocalizations.of(context)!.selectSuggestion,
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true)):
              () {
            widget.searchWidget?.onPressed!();
          },
        if (widget.searchWidget != null)
          SingleActivatorDescription(
              AppLocalizations.of(context)!.focusSearch,
              const SingleActivator(LogicalKeyboardKey.keyF,
                  control: true)): () {
            if (widget.searchWidget == null) {
              return;
            }

            if (widget.searchWidget!.focus.hasFocus) {
              widget.mainFocus.requestFocus();
            } else {
              widget.searchWidget!.focus.requestFocus();
            }
          },
        if (widget.onBack != null)
          SingleActivatorDescription(AppLocalizations.of(context)!.back,
              const SingleActivator(LogicalKeyboardKey.escape)): () {
            selection.selected.clear();
            selection.glue.close();
            widget.onBack!();
          },
        if (widget.additionalKeybinds != null) ...widget.additionalKeybinds!,
      };

  GridCell<T> makeGridCell(BuildContext context, T cell, int indx,
          {required bool hideAlias, required bool tightMode}) =>
      GridCell(
        cell: cell,
        hidealias: hideAlias,
        isList: widget.description.layout.isList,
        indx: indx,
        download: widget.download,
        lines: widget.description.titleLines,
        tight: tightMode,
        labelAtBottom: widget.description.cellTitleAtBottom,
        onPressed: (context) => onPressed(context, cell, indx),
        onLongPress: indx.isNegative
            ? null
            : () {
                selection.selectOrUnselect(
                    context, indx, cell, widget.systemNavigationInsets.bottom);
              }, //extend: maxExtend,
      );

  GridCell<T> makeGridCellAnimate(BuildContext context, T cell, int indx,
          {required bool hideAlias, required bool tightMode}) =>
      GridCell(
        cell: cell,
        animate: true,
        hidealias: hideAlias,
        isList: widget.description.layout.isList,
        indx: indx,
        download: widget.download,
        lines: widget.description.titleLines,
        tight: tightMode,
        labelAtBottom: widget.description.cellTitleAtBottom,
        onPressed: (context) => onPressed(context, cell, indx),
        onLongPress: indx.isNegative
            ? null
            : () {
                selection.selectOrUnselect(
                    context, indx, cell, widget.systemNavigationInsets.bottom);
              }, //extend: maxExtend,
      );

  Widget? _makeTitle(BuildContext context) {
    return widget.searchWidget?.search ??
        Badge.count(
          count: _state.cellCount,
          isLabelVisible: widget.showCount,
          child: Text(
            widget.description.pageName ?? "探",
            style: widget.description.pageName != null
                ? null
                : TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: "ZenKurenaido"),
          ),
        );
  }

  List<Widget> _makeActions(BuildContext context) {
    if (widget.menuButtonItems == null) {
      return [];
    }

    return (!widget.inlineMenuButtonItems && widget.menuButtonItems!.length > 1)
        ? [
            PopupMenuButton(
                position: PopupMenuPosition.under,
                itemBuilder: (context) {
                  return widget.menuButtonItems!
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
            ...widget.menuButtonItems!,
          ];
  }

  Widget? _makeLeading(BuildContext context) {
    if (selection.selected.isNotEmpty) {
      return IconButton(
          onPressed: () {
            selection.selected.clear();
            selection.glue.close();
            setState(() {});
          },
          icon: Badge.count(
              count: selection.selected.length,
              child: const Icon(
                Icons.close_rounded,
              )));
    }

    if (widget.onBack != null) {
      return IconButton(
          onPressed: () {
            setState(() {
              selection.selected.clear();
              selection.glue.close();
            });
            if (widget.onBack != null) {
              widget.onBack!();
            }
          },
          icon: widget.backButtonBadge != null
              ? Badge.count(
                  count: widget.backButtonBadge!,
                  child: const Icon(Icons.arrow_back))
              : const Icon(Icons.arrow_back));
    } else if (widget.overrideBackButton != null) {
      return widget.overrideBackButton;
    } else if (widget.scaffoldKey.currentState?.hasDrawer ?? false) {
      return GestureDetector(
        onLongPress: () {
          setState(() {
            selection.selected.clear();
            selection.glue.close();
          });
        },
        child: IconButton(
            onPressed: () {
              widget.scaffoldKey.currentState!.openDrawer();
            },
            icon: const Icon(Icons.menu)),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bindings = _makeBindings(context);
    segTranslation = null;

    final child = _BodyWrapping(
      bindings: bindings,
      mainFocus: widget.mainFocus,
      pageName: widget.description.keybindsDescription,
      children: [
        RefreshIndicator(
          onRefresh: _state.onRefresh,
          child: Scrollbar(
            interactive: false,
            thumbVisibility:
                Platform.isAndroid || Platform.isIOS ? false : true,
            controller: controller,
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.description.showAppBar)
                  FocusNotifier(
                    notifier: widget.searchWidget?.focus,
                    focusMain: () {
                      widget.mainFocus.requestFocus();
                    },
                    child: _AppBar(
                      leading: _makeLeading(context),
                      title: _makeTitle(context),
                      actions: _makeActions(context),
                      isSelecting: selection.selected.isNotEmpty,
                      bottomWidget: widget.description.bottomWidget != null
                          ? widget.description.bottomWidget!
                          : _BottomWidget<T>(
                              preferredSize: const Size.fromHeight(4),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: SizedBox(),
                              ),
                            ),
                    ),
                  ),
                if (!_state.isRefreshing &&
                    _state.cellCount == 0 &&
                    !widget.description.ignoreEmptyWidgetOnNoContent)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EmptyWidget(
                            error: _state.refreshingError == null
                                ? null
                                : EmptyWidget.unwrapDioError(
                                    _state.refreshingError),
                          ),
                          if (widget.onError != null &&
                              _state.refreshingError != null)
                            widget.onError!(_state.refreshingError!),
                        ],
                      ),
                    ),
                  ),
                ...widget.description.layout(context, this),
                _WrapPadding<T>(
                  systemNavigationInsets: widget.systemNavigationInsets.bottom,
                  footer: widget.footer,
                  selectionGlue: widget.selectionGlue,
                  child: null,
                )
              ],
            ),
          ),
        ),
        if (widget.footer != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.systemNavigationInsets.bottom,
              ),
              child: widget.footer!,
            ),
          ),
        if (!widget.description.showAppBar)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: (widget.selectionGlue.keyboardVisible()
                          ? 0
                          : widget.systemNavigationInsets.bottom +
                              (widget.selectionGlue.isOpen()
                                  ? widget.selectionGlue.barHeight()
                                  : widget.selectionGlue.persistentBarHeight
                                      ? widget.selectionGlue.barHeight()
                                      : 0)) +
                      (widget.footer != null
                          ? widget.footer!.preferredSize.height
                          : 0)),
              child: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: !_state.isRefreshing
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
          child: _Fab(
            key: _fabKey,
            scrollPos: widget.updateScrollPosition,
            controller: controller,
            selectionGlue: widget.selectionGlue,
            systemNavigationInsets: widget.systemNavigationInsets,
            footer: widget.footer,
          ),
        ),
      ],
    );

    return _MutationInterfaceProvider(
      state: mutationInterface,
      child: widget.registerNotifiers == null
          ? child
          : widget.registerNotifiers!(child),
    );
  }
}

class _AppBar<T extends Cell> extends StatelessWidget {
  final bool isSelecting;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottomWidget;

  const _AppBar({
    super.key,
    required this.actions,
    required this.bottomWidget,
    required this.isSelecting,
    required this.leading,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor:
          Theme.of(context).colorScheme.background.withOpacity(0.95),
      automaticallyImplyLeading: false,
      actions: actions,
      centerTitle: true,
      title: title,
      leading: leading,
      pinned: true,
      stretch: true,
      snap: !isSelecting,
      floating: !isSelecting,
      bottom: bottomWidget,
    );
  }
}

class _BottomWidget<T extends Cell> extends PreferredSize {
  const _BottomWidget({
    required super.preferredSize,
    required super.child,
  });

  @override
  Widget build(BuildContext context) {
    return !_MutationInterfaceProvider.of<T>(context).isRefreshing
        ? super.build(context)
        : const LinearProgressIndicator();
  }
}

class _MutationInterfaceProvider<T extends Cell> extends InheritedWidget {
  final GridMutationInterface<T> state;

  const _MutationInterfaceProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static GridMutationInterface<T> of<T extends Cell>(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_MutationInterfaceProvider<T>>();

    return widget!.state;
  }

  @override
  bool updateShouldNotify(_MutationInterfaceProvider<T> oldWidget) =>
      state != oldWidget.state;
}

class _BodyWrapping extends StatelessWidget {
  final FocusNode mainFocus;
  final String pageName;
  final Map<SingleActivatorDescription, void Function()> bindings;
  final List<Widget> children;

  const _BodyWrapping({
    super.key,
    required this.bindings,
    required this.mainFocus,
    required this.pageName,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(
          context,
          describeKeys(bindings),
          pageName,
          () {
            mainFocus.requestFocus();
          },
        )
      },
      child: Focus(
        autofocus: true,
        focusNode: mainFocus,
        child: Column(
          children: [
            Expanded(
                child: Stack(
              children: children,
            ))
          ],
        ),
      ),
    );
  }
}

class _WrapPadding<T extends Cell> extends StatelessWidget {
  final PreferredSizeWidget? footer;
  final SelectionGlue<T> selectionGlue;
  final double systemNavigationInsets;
  final bool sliver;

  final Widget? child;

  const _WrapPadding({
    super.key,
    required this.footer,
    required this.selectionGlue,
    required this.systemNavigationInsets,
    this.sliver = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final insets = EdgeInsets.only(
        bottom: (kFloatingActionButtonMargin * 2 + 24 + 8) +
            (selectionGlue.keyboardVisible()
                ? 0
                : systemNavigationInsets +
                    (selectionGlue.isOpen() //&&
                        ? selectionGlue.barHeight()
                        : selectionGlue.persistentBarHeight
                            ? selectionGlue.barHeight()
                            : 0)) +
            (footer != null ? footer!.preferredSize.height : 0));

    return sliver
        ? SliverPadding(
            padding: insets,
            sliver: child,
          )
        : Padding(
            padding: insets,
            child: child,
          );
  }
}
