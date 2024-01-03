// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show AspectRatio;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/base/note_base.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';
import 'package:logging/logging.dart';
import '../../interfaces/cell.dart';
import '../../interfaces/grid_mutation_interface.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import '../notifiers/focus.dart';
import '../shimmer_loading_indicator.dart';
import 'cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'enums/grid_aspect_ratio.dart';
import 'enums/grid_column.dart';

part 'selection_interface.dart';
part 'wrapped_selection.dart';
part 'mutation.dart';
part 'segments.dart';
part 'grid_action.dart';
part 'grid_description.dart';
part 'search_and_focus.dart';
part 'grid_layout.dart';

class RefreshingStatusInterface {
  final void Function(Future<int>) save;
  final void Function(void Function(int?, bool)) register;
  final void Function() reset;
  final void Function(void Function(int?, bool)) unregister;

  const RefreshingStatusInterface(
      {required this.save,
      required this.register,
      required this.reset,
      required this.unregister});
}

class _SegSticky {
  final String seg;
  final bool sticky;
  final void Function()? onLabelPressed;
  final bool unstickable;

  const _SegSticky(this.seg, this.sticky, this.onLabelPressed,
      {this.unstickable = true});
}

class SelectionGlue<T extends Cell> {
  final void Function(
      List<GridAction<T>> actions, SelectionInterface<T> selection) open;
  final void Function(int) updateCount;
  final void Function() close;
  final bool Function() isOpen;
  final bool Function() keyboardVisible;

  static SelectionGlue<T> empty<T extends Cell>(BuildContext context) =>
      SelectionGlue(
          close: () {},
          updateCount: (_) {},
          open: (_, __) {},
          isOpen: () => false,
          keyboardVisible: () => MediaQuery.viewInsetsOf(context).bottom != 0);

  const SelectionGlue(
      {required this.close,
      required this.updateCount,
      required this.open,
      required this.isOpen,
      required this.keyboardVisible});
}

/// The grid of images.
class CallbackGrid<T extends Cell> extends StatefulWidget {
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

  final bool unpressable;

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

  /// If [tightMode] is true, removes extra padding around the cells.
  final bool tightMode;

  /// If [hideAlias] is true, hides the cell names.
  final bool? hideAlias;

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

  // Mark the grid as immutable.
  /// If [immutable] is false then [CallbackGridState.mutationInterface] will return not null
  /// [GridMutationInterface] with which some of the grid behaviour can be augumented.
  final bool immutable;

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
  final bool showSearchBarFirst;

  final bool addFabPadding;

  final SelectionGlue<T> selectionGlue;
  final Widget? overrideBackButton;

  final NoteInterface<T>? noteInterface;

  final ImageViewStatistics? statistics;

  final bool ignoreImageViewEndDrawer;

  final RefreshingStatusInterface? refreshInterface;

  const CallbackGrid(
      {required super.key,
      this.additionalKeybinds,
      required this.getCell,
      required this.initalScrollPosition,
      required this.scaffoldKey,
      required this.systemNavigationInsets,
      required this.hasReachedEnd,
      this.pageChangeImage,
      this.onError,
      this.statistics,
      required this.selectionGlue,
      this.showCount = false,
      this.overrideBackButton,
      this.addFabPadding = false,
      this.showSearchBarFirst = false,
      this.beforeImageViewRestore,
      required this.mainFocus,
      this.addIconsImage,
      this.onExitImageView,
      this.refreshInterface,
      this.footer,
      this.registerNotifiers,
      this.immutable = true,
      this.backButtonBadge,
      this.tightMode = false,
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
      this.hideAlias,
      this.onBack,
      this.initalCellCount = 0,
      this.overrideOnPress,
      this.unpressable = false,
      required this.description});

  @override
  State<CallbackGrid<T>> createState() => CallbackGridState<T>();
}

class CallbackGridState<T extends Cell> extends State<CallbackGrid<T>> {
  late final controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);
  final fakeController = ScrollController();

  final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();

  late final selection = SelectionInterface<T>._(
      setState, widget.description.actions, widget.selectionGlue, controller);

  StreamSubscription<int>? ticker;

  GridMutationInterface<T>? get mutationInterface =>
      widget.immutable ? null : _state;

  bool inImageView = false;
  // late bool showSearchBar =
  // widget.searchWidget == null ? false : widget.showSearchBarFirst;

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
    immutable: widget.immutable,
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

    // widget.updateScrollPosition?.call(0);

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

        onPressed(
            context, _state.getCell(widget.initalCell!), widget.initalCell!,
            offset: widget.pageViewScrollingOffset);
      });
    } else if (widget.initalCellCount != 0 && widget.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        widget.beforeImageViewRestore?.call();

        onPressed(
          context,
          _state.getCell(widget.initalCell!),
          widget.initalCell!,
        );
      });
    } else {
      widget.beforeImageViewRestore?.call();
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.refreshInterface?.register(_refreshCallbackUpdate);

      controller.position.isScrollingNotifier.addListener(() {
        if (!_state.isRefreshing) {
          widget.updateScrollPosition?.call(controller.offset);
        }

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
    } else {
      refresh();
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

  void onPressed(BuildContext context, T cell, int startingCell,
      {double? offset}) {
    if (widget.overrideOnPress != null) {
      widget.mainFocus.requestFocus();
      widget.overrideOnPress!(context, cell);
      return;
    }
    inImageView = true;

    widget.mainFocus.requestFocus();

    final offsetGrid = controller.offset;
    final overlayColor =
        Theme.of(context).colorScheme.background.withOpacity(0.5);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageView<T>(
          key: imageViewKey,
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
    }));
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

  Widget _withPadding(BuildContext context, Widget child) {
    return SliverPadding(
      padding: EdgeInsets.only(
          bottom: widget.systemNavigationInsets.bottom +
              (widget.selectionGlue.isOpen() &&
                      !widget.selectionGlue.keyboardVisible()
                  ? 84
                  : 0) +
              (widget.footer != null
                  ? widget.footer!.preferredSize.height
                  : 0)),
      sliver: child,
    );
  }

  GridCell makeGridCell(BuildContext context, T cell, int indx) => GridCell(
        cell: cell.getCellData(widget.description.layout.isList,
            context: context),
        hidealias: widget.hideAlias,
        indx: indx,
        download: widget.download,
        tight: widget.tightMode,
        onPressed: widget.unpressable
            ? null
            : (context) => onPressed(context, cell, indx),
        onLongPress: indx.isNegative
            ? null
            : () {
                selection.selectOrUnselect(
                    context, indx, cell, widget.systemNavigationInsets.bottom);
              }, //extend: maxExtend,
      );

  Widget? _makeTitle1(BuildContext context) {
    // Widget make() {
    //   // Outline
    //   return Padding(
    //     padding: EdgeInsets.all(4),
    //     child: Container(
    //       height: 38,
    //       // width: 400,
    //       decoration: ShapeDecoration(
    //         color: Theme.of(context).colorScheme.inverseSurface,
    //         shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.all(Radius.circular(5))),
    //       ),
    //       child: Align(
    //         alignment: Alignment.centerLeft,
    //         child: Padding(
    //           padding: EdgeInsets.only(left: 2, right: 2),
    //           child: Row(children: [
    //             Icon(
    //               Icons.search,
    //               color: Theme.of(context).colorScheme.onInverseSurface,
    //               size: 18,
    //             ),
    //             Text(
    //               "Search",
    //               style: TextStyle(
    //                   fontSize: 18,
    //                   color: Theme.of(context)
    //                       .colorScheme
    //                       .onInverseSurface
    //                       .withOpacity(0.5)),
    //             )
    //           ]),
    //         ),
    //       ),
    //     ),
    //   );
    // }

    // if (widget.searchWidget == null) {
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
    // }

    // return Animate(
    //   effects: [
    //     const FadeEffect(begin: 1, end: 0),
    //     SwapEffect(builder: (context, _) {
    //       return Padding(
    //         padding: const EdgeInsets.only(bottom: 4),
    //         child: widget.searchWidget!.search,
    //       );
    //     })
    //   ],
    //   target: showSearchBar ? 1 : 0,
    //   child: GestureDetector(
    //     onTap: () {
    //       if (!showSearchBar) {
    //         widget.searchWidget?.focus.requestFocus();
    //       }
    //       setState(() {
    //         showSearchBar = !showSearchBar;
    //       });
    //     },
    //     child: AbsorbPointer(
    //       child: SizedBox(
    //         width: 36 * 4,
    //         height: 64,
    //         child: Center(child: make()),
    //       ),
    //     ),
    //   ),
    // );
  }

  // Widget? _makeTitle(BuildContext context) {
  //   Widget make() {
  //     return Badge.count(
  //       count: _state.cellCount,
  //       isLabelVisible: widget.showCount,
  //       child: Text(
  //         widget.description.pageName ?? "探",
  //         style: widget.description.pageName != null
  //             ? null
  //             : TextStyle(
  //                 color: Theme.of(context).colorScheme.primary,
  //                 fontFamily: "ZenKurenaido"),
  //       ),
  //     );
  //   }

  //   if (widget.searchWidget == null) {
  //     return make();
  //   }

  //   return Animate(
  //     effects: [
  //       const FadeEffect(begin: 1, end: 0),
  //       SwapEffect(builder: (context, _) {
  //         return Padding(
  //           padding: const EdgeInsets.only(bottom: 4),
  //           child: widget.searchWidget!.search,
  //         );
  //       })
  //     ],
  //     target: showSearchBar ? 1 : 0,
  //     child: GestureDetector(
  //       onTap: () {
  //         if (!showSearchBar) {
  //           widget.searchWidget?.focus.requestFocus();
  //         }
  //         setState(() {
  //           showSearchBar = !showSearchBar;
  //         });
  //       },
  //       child: AbsorbPointer(
  //         child: SizedBox(
  //           width: 64,
  //           height: 64,
  //           child: Center(child: make()),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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

    // if (showSearchBar) {
    //   return IconButton(
    //       onPressed: () {
    //         if (widget.searchWidget?.focus.hasFocus ?? false) {
    //           widget.mainFocus.requestFocus();
    //         } else {
    //           setState(() {
    //             showSearchBar = !showSearchBar;
    //           });
    //         }
    //       },
    //       icon: const Icon(Icons.arrow_back));
    // }

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

  Widget _makeGrid(BuildContext context) => CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.description.showAppBar)
            FocusNotifier(
                notifier: widget.searchWidget?.focus,
                focusMain: () {
                  widget.mainFocus.requestFocus();
                },
                child: Builder(
                  builder: (context) {
                    return SliverAppBar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .background
                          .withOpacity(0.95),
                      automaticallyImplyLeading: false,
                      actions: _makeActions(context),
                      centerTitle: true,

                      // widget.description.pageName == null ? true : false,
                      title: _makeTitle1(context),
                      leading: _makeLeading(context),
                      pinned: true,
                      stretch: true,
                      snap: selection.selected.isEmpty,
                      floating: selection.selected.isEmpty,
                      bottom: widget.description.bottomWidget != null
                          ? widget.description.bottomWidget!
                          : PreferredSize(
                              preferredSize: const Size.fromHeight(4),
                              child: !_state.isRefreshing
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: SizedBox(),
                                    )
                                  : const LinearProgressIndicator(),
                            ),
                    );
                  },
                )),
          !_state.isRefreshing && _state.cellCount == 0
              ? SliverFillRemaining(
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
                )
              : _withPadding(context, widget.description.layout(context, this)),
        ],
      );

  Widget _makeBody(BuildContext context,
          Map<SingleActivatorDescription, void Function()> bindings) =>
      CallbackShortcuts(
          bindings: {
            ...bindings,
            ...keybindDescription(context, describeKeys(bindings),
                widget.description.keybindsDescription, () {
              widget.mainFocus.requestFocus();
            })
          },
          child: Focus(
            autofocus: true,
            focusNode: widget.mainFocus,
            child: Stack(
              children: [
                RefreshIndicator(
                    onRefresh: _state.onRefresh,
                    child: Scrollbar(
                        interactive: false,
                        thumbVisibility:
                            Platform.isAndroid || Platform.isIOS ? false : true,
                        thickness: 6,
                        controller: controller,
                        child: _makeGrid(context))),
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
                Align(
                    alignment: Alignment.bottomRight,
                    child: _Fab(
                      key: _fabKey,
                      scrollPos: widget.updateScrollPosition,
                      controller: controller,
                      selectionGlue: widget.selectionGlue,
                      systemNavigationInsets: widget.systemNavigationInsets,
                      addFabPadding: widget.addFabPadding,
                      footer: widget.footer,
                    )),
              ],
            ),
          ));

  @override
  Widget build(BuildContext context) {
    final bindings = _makeBindings(context);
    segTranslation = null;

    return widget.registerNotifiers == null
        ? _makeBody(context, bindings)
        : widget.registerNotifiers!(_makeBody(context, bindings));
  }
}

class _Fab extends StatefulWidget {
  final ScrollController controller;
  final void Function(double, {double? infoPos, int? selectedCell})? scrollPos;
  final SelectionGlue selectionGlue;
  final EdgeInsets systemNavigationInsets;
  final bool addFabPadding;
  final PreferredSizeWidget? footer;

  const _Fab(
      {super.key,
      required this.controller,
      required this.selectionGlue,
      required this.systemNavigationInsets,
      required this.addFabPadding,
      required this.scrollPos,
      required this.footer});

  @override
  State<_Fab> createState() => __FabState();
}

class __FabState extends State<_Fab> {
  bool showFab = false;

  @override
  Widget build(BuildContext context) {
    return !showFab
        ? const SizedBox.shrink()
        : GestureDetector(
            onLongPress: () {
              final scroll = widget.controller.position.maxScrollExtent;
              if (scroll.isInfinite || scroll == 0) {
                return;
              }

              widget.controller.animateTo(scroll,
                  duration: 200.ms, curve: Easing.emphasizedAccelerate);
              widget.scrollPos?.call(scroll);
            },
            child: Padding(
              padding: EdgeInsets.only(
                  right: 4,
                  bottom: widget.systemNavigationInsets.bottom +
                      (!widget.addFabPadding
                          ? 0
                          : (widget.selectionGlue.isOpen() &&
                                      !widget.selectionGlue.keyboardVisible()
                                  ? 84
                                  : 0) +
                              (widget.footer != null
                                  ? widget.footer!.preferredSize.height
                                  : 0))),
              child: FloatingActionButton(
                onPressed: () {
                  widget.controller.animateTo(0,
                      duration: 200.ms, curve: Easing.emphasizedAccelerate);
                  StatisticsGeneral.addScrolledUp();
                },
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          ).animate().fadeIn(curve: Easing.standard);
  }
}
