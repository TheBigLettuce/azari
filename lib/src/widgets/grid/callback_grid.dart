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
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../../cell/cell.dart';
import '../../keybinds/keybinds.dart';
import '../notifiers/focus.dart';
import 'cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'selection_interface.dart';
part 'wrapped_selection.dart';
part 'mutation.dart';
part 'segments.dart';
part 'grid_bottom_sheet_action.dart';
part 'grid_description.dart';
part 'search_and_focus.dart';
part 'grid_layout.dart';
part 'sticker_icon.dart';

class CloudflareBlockInterface {
  final BooruAPI api;

  const CloudflareBlockInterface(this.api);
}

class _SegSticky {
  final String seg;
  final bool sticky;

  const _SegSticky(this.seg, this.sticky);
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

  /// [hideShowFab] gets called when viewport gets scrolled, when not null.
  final void Function({required bool fab, required bool foreground})?
      hideShowFab;

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

  /// Overrides the default behaviour of launching the image view on cell pressed.
  /// [overrideOnPress] can, for example, include calls to [Navigator.push] of routes.
  final void Function(BuildContext context, T cell)? overrideOnPress;

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

  /// Aspect ratio of the cells.
  final double aspectRatio;

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
  final List<IconButton> Function(T)? addIconsImage;

  /// Supplied to [ImageView.pageChange].
  final void Function(ImageViewState<T> state)? pageChangeImage;

  /// Currently useless.
  final CloudflareBlockInterface Function()? cloudflareHook;

  /// If [loadThumbsDirectly] is not null then the grid will call it
  /// in case when [CellData.loaded] is false.
  final void Function(T cell)? loadThumbsDirectly;

  /// Segments of the grid.
  /// If [segments] is not null, then the grid will try to group the cells together
  /// by a common category name.
  final Segments<T>? segments;

  /// Makes [menuButtonItems] appear as app bar items.
  final bool inlineMenuButtonItems;

  final PreferredSizeWidget? footer;

  final Widget Function(Object error)? onError;

  final List<InheritedWidget Function(Widget child)>? registerNotifiers;

  const CallbackGrid(
      {super.key,
      this.additionalKeybinds,
      required this.getCell,
      required this.initalScrollPosition,
      required this.scaffoldKey,
      required this.systemNavigationInsets,
      required this.hasReachedEnd,
      required this.aspectRatio,
      this.cloudflareHook,
      this.pageChangeImage,
      this.onError,
      required this.mainFocus,
      this.addIconsImage,
      this.segments,
      this.footer,
      this.registerNotifiers,
      this.immutable = true,
      this.tightMode = false,
      this.loadThumbsDirectly,
      this.belowMainFocus,
      this.inlineMenuButtonItems = false,
      this.progressTicker,
      this.menuButtonItems,
      this.searchWidget,
      this.initalCell,
      this.pageViewScrollingOffset,
      this.loadNext,
      required this.refresh,
      this.updateScrollPosition,
      this.hideShowFab,
      this.download,
      this.hideAlias,
      this.onBack,
      this.initalCellCount = 0,
      this.overrideOnPress,
      required this.description});

  @override
  State<CallbackGrid<T>> createState() => CallbackGridState<T>();
}

class CallbackGridState<T extends Cell> extends State<CallbackGrid<T>> {
  late final controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);
  final fakeController = ScrollController();

  final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();

  late final selection =
      SelectionInterface<T>._(setState, widget.description.actions);

  StreamSubscription<int>? ticker;

  GridMutationInterface<T>? get mutationInterface =>
      widget.immutable ? null : _state;

  bool inImageView = false;

  late final _Mutation<T> _state = _Mutation(
    updateImageView: () {
      imageViewKey.currentState?.update(_state.cellCount);
    },
    scrollUp: () {
      if (widget.hideShowFab != null) {
        widget.hideShowFab!(fab: false, foreground: inImageView);
      }
    },
    unselectall: () {
      selection.selected.clear();
      selection.currentBottomSheet?.close();
    },
    immutable: widget.immutable,
    widget: () => widget,
    update: (f) {
      try {
        if (context.mounted) {
          if (f != null) {
            f();
          }

          setState(() {});
        }
      } catch (_) {}
    },
  );

  @override
  void initState() {
    super.initState();

    ticker = widget.progressTicker?.listen((event) {
      setState(() {
        _state._cellCount = event;
      });
    });

    if (widget.pageViewScrollingOffset != null && widget.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        _onPressed(
            context, _state.getCell(widget.initalCell!), widget.initalCell!,
            offset: widget.pageViewScrollingOffset);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.position.isScrollingNotifier.addListener(() {
        if (!_state.isRefreshing) {
          widget.updateScrollPosition?.call(controller.offset);
        }

        if (widget.hideShowFab != null) {
          if (controller.offset == 0) {
            widget.hideShowFab!(fab: false, foreground: inImageView);
          } else {
            widget.hideShowFab!(
                fab: !controller.position.isScrollingNotifier.value,
                foreground: inImageView);
          }
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

    super.dispose();
  }

  Future refresh() {
    selection.currentBottomSheet?.close();
    selection.selected.clear();
    if (widget.hideShowFab != null) {
      widget.hideShowFab!(fab: false, foreground: inImageView);
    }

    return _state._refresh();
  }

  void _scrollUntill(int p) {
    final picPerRow = widget.description.columns;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (widget.description.listView) {
      target = contentSize * p / _state.cellCount;
    } else {
      target = contentSize *
          (p / picPerRow.number - 1) /
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

  void _onPressed(BuildContext context, T cell, int startingCell,
      {double? offset}) {
    if (widget.overrideOnPress != null) {
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
          registerNotifiers: widget.registerNotifiers,
          systemOverlayRestoreColor: overlayColor,
          updateTagScrollPos: (pos, selectedCell) => widget.updateScrollPosition
              ?.call(offsetGrid, infoPos: pos, selectedCell: selectedCell),
          scrollUntill: _scrollUntill,
          pageChange: widget.pageChangeImage,
          onExit: () {
            inImageView = false;
          },
          addIcons: widget.addIconsImage,
          focusMain: () {
            widget.mainFocus.requestFocus();
          },
          infoScrollOffset: offset,
          getCell: _state.getCell,
          cellCount: _state.cellCount,
          download: widget.download,
          startingCell: startingCell,
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
            selection.currentBottomSheet?.close();
            widget.onBack!();
          },
        if (widget.additionalKeybinds != null) ...widget.additionalKeybinds!,
        ...digitAndSettings(
            context, widget.description.drawerIndex, widget.scaffoldKey),
      };

  Widget _withPadding(Widget child) {
    return SliverPadding(
      padding: EdgeInsets.only(
          bottom: widget.systemNavigationInsets.bottom +
              MediaQuery.viewPaddingOf(context).bottom +
              (selection.currentBottomSheet != null ? 48 + 4 : 0) +
              (widget.footer != null
                  ? widget.footer!.preferredSize.height
                  : 0)),
      sliver: child,
    );
  }

  GridCell _makeGridCell(T cell, int indx) => GridCell(
        cell: cell.getCellData(widget.description.listView),
        hidealias: widget.hideAlias,
        indx: indx,
        download: widget.download,
        tight: widget.tightMode,
        onPressed: (context) => _onPressed(context, cell, indx),
        onLongPress: () => selection.selectOrUnselect(context, indx, cell,
            widget.systemNavigationInsets.bottom), //extend: maxExtend,
      );

  static Widget wrapNotifiers(
      BuildContext context,
      List<InheritedWidget Function(Widget child)>? notifiers,
      Widget Function(BuildContext context) child) {
    if (notifiers == null || notifiers.isEmpty) {
      return child(context);
    }

    Widget registerRecursion(int idx, Widget currentChild) {
      if (idx <= -1) {
        return currentChild;
      }
      final f = notifiers[idx];
      return registerRecursion(idx - 1, f(currentChild));
    }

    return registerRecursion(notifiers.length - 1, Builder(
      builder: (context) {
        return child(context);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bindings = _makeBindings(context);

    return wrapNotifiers(context, widget.registerNotifiers, (context) {
      return CallbackShortcuts(
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
                        child: CustomScrollView(
                          controller: controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
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
                                          .withOpacity(0.90),
                                      expandedHeight:
                                          FocusNotifier.of(context).hasFocus
                                              ? 64
                                              : 152 +
                                                  (widget
                                                          .description
                                                          .bottomWidget
                                                          ?.preferredSize
                                                          .height ??
                                                      0),
                                      collapsedHeight: 64,
                                      automaticallyImplyLeading: false,
                                      actions: [Container()],
                                      flexibleSpace: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                child: FlexibleSpaceBar(
                                                    titlePadding:
                                                        EdgeInsetsDirectional
                                                            .only(
                                                      start:
                                                          widget.onBack != null
                                                              ? 48
                                                              : 0,
                                                    ),
                                                    title: widget.searchWidget
                                                                ?.search !=
                                                            null
                                                        ? Padding(
                                                            padding: EdgeInsets.only(
                                                                bottom: widget
                                                                        .description
                                                                        .bottomWidget
                                                                        ?.preferredSize
                                                                        .height ??
                                                                    0 +
                                                                        (_state.isRefreshing
                                                                            ? 4
                                                                            : 0)),
                                                            child: widget
                                                                .searchWidget
                                                                ?.search,
                                                          )
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 8,
                                                                    bottom: 16,
                                                                    right: 8,
                                                                    left: 8),
                                                            child: Text(
                                                              widget.description
                                                                      .pageName ??
                                                                  widget
                                                                      .description
                                                                      .keybindsDescription,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ))),
                                            if (Platform.isAndroid ||
                                                Platform.isIOS)
                                              if (widget.menuButtonItems !=
                                                      null &&
                                                  (widget.menuButtonItems!
                                                              .length ==
                                                          1 ||
                                                      widget
                                                          .inlineMenuButtonItems))
                                                ...widget.menuButtonItems!.map(
                                                    (e) => wrapAppBarAction(e)),
                                            if (widget.scaffoldKey.currentState
                                                    ?.hasDrawer ??
                                                false)
                                              wrapAppBarAction(GestureDetector(
                                                onLongPress: () {
                                                  setState(() {
                                                    selection.selected.clear();
                                                    selection.currentBottomSheet
                                                        ?.close();
                                                  });
                                                },
                                                child: IconButton(
                                                    onPressed: () {
                                                      widget.scaffoldKey
                                                          .currentState!
                                                          .openDrawer();
                                                    },
                                                    icon:
                                                        const Icon(Icons.menu)),
                                              )),
                                            if (widget.menuButtonItems !=
                                                    null &&
                                                widget.menuButtonItems!
                                                        .length !=
                                                    1 &&
                                                !widget.inlineMenuButtonItems)
                                              wrapAppBarAction(PopupMenuButton(
                                                  position:
                                                      PopupMenuPosition.under,
                                                  itemBuilder: (context) {
                                                    return widget
                                                        .menuButtonItems!
                                                        .map(
                                                          (e) => PopupMenuItem(
                                                            enabled: false,
                                                            child: e,
                                                          ),
                                                        )
                                                        .toList();
                                                  }))
                                          ]),
                                      leading: widget.onBack != null
                                          ? IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  selection.selected.clear();
                                                  selection.currentBottomSheet
                                                      ?.close();
                                                });
                                                if (widget.onBack != null) {
                                                  widget.onBack!();
                                                }
                                              },
                                              icon:
                                                  const Icon(Icons.arrow_back))
                                          : Container(),
                                      pinned: true,
                                      stretch: true,
                                      bottom: widget.description.bottomWidget !=
                                              null
                                          ? widget.description.bottomWidget!
                                          : _state.isRefreshing
                                              ? const PreferredSize(
                                                  preferredSize:
                                                      Size.fromHeight(4),
                                                  child:
                                                      LinearProgressIndicator(),
                                                )
                                              : null,
                                    );
                                  },
                                )),
                            if (widget.segments == null)
                              !_state.isRefreshing && _state.cellCount == 0
                                  ? SliverToBoxAdapter(
                                      child: Column(
                                      children: [
                                        EmptyWidget(
                                          error: _state.refreshingError,
                                        ),
                                        if (widget.onError != null &&
                                            _state.refreshingError != null)
                                          widget.onError!(
                                              _state.refreshingError!),
                                      ],
                                    ))
                                  : _withPadding(widget.description.listView
                                      ? GridLayout.list<T>(
                                          context,
                                          _state,
                                          selection,
                                          widget.systemNavigationInsets.bottom,
                                          widget.description.listView,
                                          loadThumbsDirectly:
                                              widget.loadThumbsDirectly,
                                          onPressed: _onPressed)
                                      : GridLayout.grid<T>(
                                          context,
                                          _state,
                                          selection,
                                          widget.description.columns.number,
                                          widget.description.listView,
                                          widget.loadThumbsDirectly,
                                          _makeGridCell,
                                          systemNavigationInsets: widget
                                              .systemNavigationInsets.bottom,
                                          aspectRatio: widget.aspectRatio,
                                        ))
                            else
                              _withPadding(GridLayout.segments<T>(
                                  context,
                                  widget.segments!,
                                  _state,
                                  selection,
                                  widget.description.listView,
                                  widget.description.columns.number,
                                  _makeGridCell,
                                  systemNavigationInsets:
                                      widget.systemNavigationInsets.bottom,
                                  aspectRatio: widget.aspectRatio,
                                  loadThumbsDirectly:
                                      widget.loadThumbsDirectly)),
                          ],
                        ))),
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
              ],
            ),
          ));
    });
  }
}
