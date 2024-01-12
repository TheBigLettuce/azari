// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/notifiers/cell_provider.dart';
import 'package:gallery/src/widgets/notifiers/grid_footer.dart';

import '../notifiers/selection_glue.dart';
import '../notifiers/state_restoration.dart';
import 'fab.dart';

class CallbackGridBase<T extends Cell> extends StatefulWidget {
  final Widget? appBar;
  final Widget child;

  const CallbackGridBase(
      {super.key, required this.appBar, required this.child});

  @override
  State<CallbackGridBase<T>> createState() => _CallbackGridBaseState();
}

class _CallbackGridBaseState<T extends Cell>
    extends State<CallbackGridBase<T>> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent * 0.95 &&
          scrollController.position.maxScrollExtent != 0 &&
          scrollController.position.pixels != 0) {
        final state = CellProvider.stateOf<T>(context);

        state.next();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.position.isScrollingNotifier
          .addListener(_saveScrollingState);

      final restore = StateRestorationProvider.maybeOf(context);
      if (restore != null) {
        scrollController.jumpTo(restore.copy.scrollPositionGrid);
      }
    });
  }

  void _saveScrollingState() {
    if (!scrollController.position.isScrollingNotifier.value) {
      final restore = StateRestorationProvider.maybeOf(context);
      if (restore != null) {
        restore.updateScrollPosition(scrollController.offset);
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () {
          CellProvider.stateOf<T>(context).reset();
          return Future.value();
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.appBar != null) widget.appBar!,
                _Padding<T>(
                    child: PrimaryScrollController(
                  controller: scrollController,
                  child: widget.child,
                )),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: (MediaQuery.of(context).viewInsets.bottom) +
                      (SelectionGlueNotifier.isOpenOf<T>(context)
                          ? 84
                          : Scaffold.maybeOf(context)
                                      ?.widget
                                      .bottomNavigationBar !=
                                  null
                              ? 84
                              : 0) +
                      (GridFooterNotifier.sizeOf(context) ?? 0)),
              child: PrimaryScrollController(
                controller: scrollController,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CallbackGridFab(),
                ),
              ),
            )
          ],
        ));
  }
}

class _Padding<T extends Cell> extends StatelessWidget {
  final Widget child;

  const _Padding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    PrimaryScrollController.of(context);

    return SliverPadding(
      padding: EdgeInsets.only(
          bottom: (MediaQuery.of(context).viewInsets.bottom) +
              (SelectionGlueNotifier.isOpenOf<T>(context)
                  ? 84
                  : scaffold?.widget.bottomNavigationBar != null
                      ? 84
                      : 0) +
              (GridFooterNotifier.sizeOf(context) ?? 0)),
      sliver: child,
    );
  }
}


// FocusNotifier(
//                     notifier: widget.searchWidget?.focus,
//                     focusMain: () {
//                       widget.mainFocus.requestFocus();
//                     },
//                     child: ,
//                   )



// _Fab(
//                         key: _fabKey,
//                         controller: controller,
//                         selectionGlue: widget.selectionGlue,
//                         systemNavigationInsets: widget.systemNavigationInsets,
//                         addFabPadding: widget.addFabPadding,
//                         footer: widget.footer,
//                       )


//   if (showSearchBar) {
//     return IconButton(
//         onPressed: () {
//           if (widget.searchWidget?.focus.hasFocus ?? false) {
//             widget.mainFocus.requestFocus();
//           } else {
//             setState(() {
//               showSearchBar = !showSearchBar;
//             });
//           }
//         },
//         icon: const Icon(Icons.arrow_back));
//   }

//   if (widget.onBack != null) {
//     return IconButton(
//         onPressed: () {
//           setState(() {
//             selection.selected.clear();
//             selection.glue.close();
//           });
//           if (widget.onBack != null) {
//             widget.onBack!();
//           }
//         },
//         icon: widget.backButtonBadge != null
//             ? Badge.count(
//                 count: widget.backButtonBadge!,
//                 child: const Icon(Icons.arrow_back))
//             : const Icon(Icons.arrow_back));
//   } else if (widget.overrideBackButton != null) {
//     return widget.overrideBackButton;
//   } else if (widget.scaffoldKey.currentState?.hasDrawer ?? false) {
//     return GestureDetector(
//       onLongPress: () {
//         setState(() {
//           selection.selected.clear();
//           selection.glue.close();
//         });
//       },
//       child: IconButton(
//           onPressed: () {
//             widget.scaffoldKey.currentState!.openDrawer();
//           },
//           icon: const Icon(Icons.menu)),
//     );
//   }

//   return null;
// }


// final SelectionGlue<T> selectionGlue;

/// [updateScrollPosition] gets called when grid first builds and then when scrolling stops,
///  if not null. Useful when it is desirable to persist the scroll position of the grid.
/// [infoPos] represents the scroll position in the "Info" of the image view,
///  and [selectedCell] represents the inital page of the image view.
/// State restoration takes this info into the account.
// final void Function(double pos, {double? infoPos, int? selectedCell})?
//     updateScrollPosition;

/// If the elemnts of the grid arrive in batches [progressTicker] can be set to not null,
/// grid will subscribe to it and set the cell count from this ticker's events.
// final Stream<int>? progressTicker;

/// If [initalCellCount] is not 0, then the grid won't call [refresh].
// final int initalCellCount;

// /// [initalCell] is needed for the state restoration.
// /// If [initalCell] is not null the grid will launch image view setting [ImageView.startingCell] as this value.
// final int? initalCell;

// /// [initalScrollPosition] is needed for the state restoration.
// /// If [initalScrollPosition] is not 0, then it is set as the starting scrolling position.
// final double initalScrollPosition;

// /// [pageViewScrollingOffset] is needed for the state restoration.
// /// If not null, [pageViewScrollingOffset] gets supplied to the [ImageView.infoScrollOffset].
// final double? pageViewScrollingOffset;

// /// If [tightMode] is true, removes extra padding around the cells.
// final bool tightMode;

// /// If [hideAlias] is true, hides the cell names.
// final bool? hideAlias;

// /// Used for enabling bottom sheets and the drawer.
// final GlobalKey<ScaffoldState> scaffoldKey;

// Mark the grid as immutable.
/// If [immutable] is false then [CallbackGridShellState.mutationInterface] will return not null
/// [GridMutationInterface] with which some of the grid behaviour can be augumented.
// final bool immutable;

// final NoteInterface<T>? noteInterface;

//   final bool showCount;
// final bool showSearchBarFirst;

// final bool addFabPadding;

// final int? backButtonBadge;

// final bool unpressable;

/// Supplied to [ImageView.addIcons].
// final List<GridAction<T>> Function(T)? addIconsImage;

/// Supplied to [ImageView.pageChange].
// final void Function(ImageViewState<T> state)? pageChangeImage;

/// Some additional metadata about the grid.
// final GridDescription<T> description;

// /// Grid gets the cell from [getCell].
// final T Function(int) getCell;

/// Overrides the default behaviour of launching the image view on cell pressed.
/// [overrideOnPress] can, for example, include calls to [Navigator.push] of routes.
// final void Function(BuildContext context, T cell)? overrideOnPress;

// Future refresh([Future<int> Function()? overrideRefresh]) {
//   selection.selected.clear();
//   selection.glue.close();
//   updateFab(fab: false, foreground: inImageView);

//   _state._cellCount = 0;

//   return _state._refresh(overrideRefresh);
// }

// void _scrollUntill(int p) {
//   if (controller.position.maxScrollExtent.isInfinite) {
//     return;
//   }

//   final picPerRow = widget.description.layout.columns;
//   // Get the full content height.
//   final contentSize = controller.position.viewportDimension +
//       controller.position.maxScrollExtent;
//   // Estimate the target scroll position.
//   double target;
//   if (widget.description.layout.isList) {
//     target = contentSize * p / _state.cellCount;
//   } else {
//     target = contentSize *
//         (p / picPerRow!.number - 1) /
//         (_state.cellCount / picPerRow.number);
//   }

//   if (target < controller.position.minScrollExtent) {
//     widget.updateScrollPosition?.call(controller.position.minScrollExtent);
//     return;
//   } else if (target > controller.position.maxScrollExtent) {
//     if (widget.hasReachedEnd()) {
//       widget.updateScrollPosition?.call(controller.position.maxScrollExtent);
//       return;
//     }
//   }

//   widget.updateScrollPosition?.call(target);

//   controller.jumpTo(target);
// }

// void onPressed(BuildContext context, T cell, int startingCell,
//     {double? offset}) {
//   if (widget.overrideOnPress != null) {
//     widget.mainFocus.requestFocus();
//     widget.overrideOnPress!(context, cell);
//     return;
//   }
//   inImageView = true;

//   widget.mainFocus.requestFocus();

//   final offsetGrid = controller.offset;
//   final overlayColor =
//       Theme.of(context).colorScheme.background.withOpacity(0.5);


// }

// late final controller =
//     ScrollController(initialScrollOffset: widget.initalScrollPosition);
// final fakeController = ScrollController();

// final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();

// late final selection = SelectionInterface<T>._(
//     setState, widget.description.actions, widget.selectionGlue, controller);

// StreamSubscription<int>? ticker;

// GridMutationInterface<T>? get mutationInterface =>
//     widget.immutable ? null : _state;

// bool inImageView = false;
// late bool showSearchBar =
//     widget.searchWidget == null ? false : widget.showSearchBarFirst;

/// Makes [menuButtonItems] appear as app bar items.
// final bool inlineMenuButtonItems;

// final Widget? overrideBackButton;

// final Widget Function(Object error)? onError;

// final void Function()? onExitImageView;

// final void Function()? beforeImageViewRestore;

/// [loadNext] gets called when the grid is scrolled around the end of the viewport.
/// If this is null, then the grid is assumed to be not able to incrementally add posts
/// by scrolling at the near end of the viewport.
// final Future<int> Function()? loadNext;

/// In case if the cell represents an online resource which can be downloaded,
/// setting [download] enables buttons to download the resource.
// final Future<void> Function(int indx)? download;

/// Refresh the grid.
/// If [refresh] returns null, it means no posts can be loaded more,
/// which means that if [loadNext] is not null it wont be called more.
// final Future<int>? Function() refresh;

/// If not null, [searchWidget] is displayed in the appbar.
// final SearchAndFocus? searchWidget;

/// Items added in the menu button's children, after the [searchWidget], or the page name
/// if [searchWidget] is null. If [menuButtonItems] includes only one widget,
/// it is displayed directly.
// final List<Widget>? menuButtonItems;

/// [hasReachedEnd] should return true when the cell loading cannot load more.
// final bool Function() hasReachedEnd;

// late final _Mutation<T> _state = _Mutation(
//   updateImageView: () {
//     imageViewKey.currentState?.update(context, _state.cellCount);
//   },
//   scrollUp: () {
//     updateFab(fab: false, foreground: inImageView);
//   },
//   unselectall: () {
//     selection.selected.clear();
//     selection.glue.close();
//   },
//   immutable: widget.immutable,
//   widget: () => widget,
//   update: (f) {
//     try {
//       if (context.mounted) {
//         f?.call();

//         setState(() {});
//       }
//     } catch (_) {}
//   },
// );

// ticker = widget.progressTicker?.listen((event) {
//   setState(() {
//     _state._cellCount = event;
//   });
// });

// if (widget.initalCellCount != 0 &&
//     widget.pageViewScrollingOffset != null &&
//     widget.initalCell != null) {
//   WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
//     widget.beforeImageViewRestore?.call();

//     onPressed(
//         context, _state.getCell(widget.initalCell!), widget.initalCell!,
//         offset: widget.pageViewScrollingOffset);
//   });
// } else if (widget.initalCellCount != 0 && widget.initalCell != null) {
//   WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
//     widget.beforeImageViewRestore?.call();

//     onPressed(
//       context,
//       _state.getCell(widget.initalCell!),
//       widget.initalCell!,
//     );
//   });
// } else {
//   widget.beforeImageViewRestore?.call();
// }

// if (widget.initalCellCount != 0) {
//   _state._cellCount = widget.initalCellCount;
// } else {
//   refresh();
// }

// if (widget.loadNext == null) {
//   return;
// }


// controller.position.isScrollingNotifier.addListener(() {
//   if (!_state.isRefreshing) {
//     widget.updateScrollPosition?.call(controller.offset);
//   }

//   if (controller.offset == 0) {
//     updateFab(fab: false, foreground: inImageView);
//   } else {
//     updateFab(
//         fab: !controller.position.isScrollingNotifier.value,
//         foreground: inImageView);
//   }
// });

// SingleActivatorDescription(AppLocalizations.of(context)!.refresh,
//     const SingleActivator(LogicalKeyboardKey.f5)): _state._f5,
// if (widget.searchWidget != null &&
//     widget.searchWidget!.onPressed != null)
//   SingleActivatorDescription(
//           AppLocalizations.of(context)!.selectSuggestion,
//           const SingleActivator(LogicalKeyboardKey.enter, shift: true)):
//       () {
//     widget.searchWidget?.onPressed!();
//   },
// if (widget.searchWidget != null)
//   SingleActivatorDescription(
//       AppLocalizations.of(context)!.focusSearch,
//       const SingleActivator(LogicalKeyboardKey.keyF,
//           control: true)): () {
//     if (widget.searchWidget == null) {
//       return;
//     }

//     if (widget.searchWidget!.focus.hasFocus) {
//       widget.mainFocus.requestFocus();
//     } else {
//       widget.searchWidget!.focus.requestFocus();
//     }
//   },
// if (widget.onBack != null)
//   SingleActivatorDescription(AppLocalizations.of(context)!.back,
//       const SingleActivator(LogicalKeyboardKey.escape)): () {
//     selection.selected.clear();
//     selection.glue.close();
//     widget.onBack!();
//   },

// List<int>? segTranslation;

// final _fabKey = GlobalKey<__FabState>();

// void updateFab({required bool fab, required bool foreground}) {
//   if (fab != _fabKey.currentState?.showFab) {
//     _fabKey.currentState?.showFab = fab;
//     if (!foreground) {
//       try {
//         // widget.hideShowNavBar(!showFab);
//         _fabKey.currentState?.setState(() {});
//       } catch (_) {}
//     }
//   }
// }

// Map<SingleActivatorDescription, Null Function()> _makeBindings(
//         BuildContext context) =>
//     {
//       if (widget.additionalKeybinds != null) ...widget.additionalKeybinds!,
//     };

// WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//   final b = _makeBindings(context);

//   bindings = {
//     ...b.map((key, value) => MapEntry(key.a, value)),
//     ...keybindDescription(
//         context, describeKeys(b), widget.keybindsDescription, () {
//       widget.mainFocus.requestFocus();
//     })
//   };
// });

/// If [belowMainFocus] is not null, then when the grid gets disposed
/// [belowMainFocus.requestFocus] get called.
// final FocusNode? belowMainFocus;

/// Displayed in the keybinds info page name.
// final String keybindsDescription;

/// If [onBack] is not null, then a back button will be displayed in the appbar,
/// which would call this callback when pressed.
// final void Function()? onBack;


