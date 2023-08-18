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
import 'package:gallery/src/widgets/booru/autocomplete_tag.dart';
import 'package:gallery/src/widgets/cloudflare_block.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../../cell/cell.dart';
import '../../keybinds/keybinds.dart';
import 'cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'selection.dart';
part 'wrapped_selection.dart';
part 'mutation.dart';

class CloudflareBlockInterface {
  final BooruAPI api;

  const CloudflareBlockInterface(this.api);
}

/// Action which can be taken upon a selected group of cells.
class GridBottomSheetAction<T> {
  /// Icon of the button.
  final IconData icon;

  /// [onPress] is called when the button gets pressed,
  /// if [showOnlyWhenSingle] is true then this is guranteed to be called
  /// with [selected] elements zero or one.
  final void Function(List<T> selected) onPress;

  /// If [closeOnPress] is true, then the bottom sheet will be closed immediately after this
  /// button has been pressed.
  final bool closeOnPress;

  /// If [showOnlyWhenSingle] is true, then this button will be only active if only a single
  /// element is currently selected.
  final bool showOnlyWhenSingle;

  const GridBottomSheetAction(this.icon, this.onPress, this.closeOnPress,
      {this.showOnlyWhenSingle = false});
}

/// Segments of the grid.
class Segments<T> {
  /// Under [unsegmentedLabel] appear cells on which [segment] returns null,
  /// or are single standing.
  final String unsegmentedLabel;

  /// Segmentation function.
  /// If [sticky] is true, then even if the cell is single standing it will appear
  /// as a single element segment on the grid.
  final (String? segment, bool sticky) Function(T cell) segment;

  /// If [addToSticky] is not null. then it will be possible to make
  /// segments sticky on the grid.
  /// If [unsticky] is true, then instead of stickying, unstickying should happen.
  final void Function(String seg, {bool? unsticky})? addToSticky;

  const Segments(this.segment, this.unsegmentedLabel, {this.addToSticky});
}

/// Metadata about the grid.
class GridDescription<T> {
  /// Index of the element in the drawer.
  /// Useful if the grid is displayed in the page which have entry in the drawer.
  final int drawerIndex;

  /// Displayed in the keybinds info page name.
  final String keybindsDescription;

  /// If [pageName] is not null, and [CallbackGrid.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [CallbackGrid.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridBottomSheetAction<T>> actions;

  final GridColumn columns;

  /// If [listView] is true, then grid becomes a list.
  /// [CallbackGrid.segments] gets ignored if [listView] is true.
  final bool listView;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  const GridDescription(
    this.drawerIndex,
    this.actions,
    this.columns, {
    required this.keybindsDescription,
    this.bottomWidget,
    this.pageName,
    required this.listView,
  });
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
  final void Function(BuildContext context, int indx)? overrideOnPress;

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
  final void Function(int from)? loadThumbsDirectly;

  /// Segments of the grid.
  /// If [segments] is not null, then the grid will try to group the cells together
  /// by a common category name.
  final Segments<T>? segments;

  /// Makes [menuButtonItems] appear as app bar items.
  final bool inlineMenuButtonItems;

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
      required this.mainFocus,
      this.addIconsImage,
      this.segments,
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

class SearchAndFocus {
  final Widget search;
  final FocusNode focus;
  final void Function()? onPressed;

  const SearchAndFocus(this.search, this.focus, {this.onPressed});
}

class CallbackGridState<T extends Cell> extends State<CallbackGrid<T>>
    with _Selection<T> {
  late ScrollController controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);
  final ScrollController fakeController = ScrollController();

  StreamSubscription<int>? ticker;

  GridMutationInterface<T>? get mutationInterface =>
      widget.immutable ? null : _state;

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
        _onPressed(context, widget.initalCell!,
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

      var h = MediaQuery.sizeOf(context).height;

      var height = h - h * 0.90;

      if (!_state.isRefreshing &&
          _state.cellCount != 0 &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              1 - (height / controller.positions.first.maxScrollExtent)) {
        _state._loadNext();
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
    currentBottomSheet?.close();
    selected.clear();
    if (widget.hideShowFab != null) {
      widget.hideShowFab!(fab: false, foreground: inImageView);
    }

    return _state._refresh();
  }

  void _scrollUntill(int p) {
    var picPerRow = widget.description.columns;
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

  void _onPressed(BuildContext context, int i, {double? offset}) {
    if (widget.overrideOnPress != null) {
      widget.overrideOnPress!(context, i);
      return;
    }
    inImageView = true;

    widget.mainFocus.requestFocus();

    var offsetGrid = controller.offset;
    var overlayColor =
        Theme.of(context).colorScheme.background.withOpacity(0.5);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageView<T>(
          key: imageViewKey,
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
          startingCell: i,
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
            selected.clear();
            currentBottomSheet?.close();
            widget.onBack!();
          },
        if (widget.additionalKeybinds != null) ...widget.additionalKeybinds!,
        ...digitAndSettings(
            context, widget.description.drawerIndex, widget.scaffoldKey),
      };

  Widget _segmentLabel(String text, bool sticky) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16, left: 8, right: 8),
      child: GestureDetector(
        onLongPress: widget.segments!.addToSticky != null &&
                text != widget.segments!.unsegmentedLabel
            ? () {
                HapticFeedback.vibrate();
                widget.segments!.addToSticky!(text,
                    unsticky: sticky ? true : null);
                _state._onRefresh();
              }
            : null,
        child: SizedBox.fromSize(
          size: Size.fromHeight(
              (Theme.of(context).textTheme.headlineLarge?.fontSize ?? 24) + 8),
          child: Stack(
            children: [
              Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(letterSpacing: 2),
              ),
              if (sticky)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.push_pin_outlined),
                ),
            ],
          ),
        ),
      ));

  Widget _makeList(BuildContext context) => SliverPadding(
        padding: EdgeInsets.only(
            bottom: widget.systemNavigationInsets.bottom +
                MediaQuery.viewPaddingOf(context).bottom),
        sliver: SliverList.separated(
          separatorBuilder: (context, index) => const Divider(
            height: 1,
          ),
          itemCount: _state.cellCount,
          itemBuilder: (context, index) {
            var cell = _state.getCell(index);
            var cellData = cell.getCellData(widget.description.listView);
            if (cellData.loaded != null && cellData.loaded == false) {
              widget.loadThumbsDirectly?.call(index);
            }

            return _WrappedSelection(
              selectUntil: _selectUnselectUntil,
              thisIndx: index,
              isSelected: _isSelected(index),
              selectionEnabled: selected.isNotEmpty,
              selectUnselect: () => _selectOrUnselect(index, cell),
              child: ListTile(
                onLongPress: () => _selectOrUnselect(index, cell),
                onTap: () => _onPressed(context, index),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  foregroundImage: cellData.thumb,
                  onForegroundImageError: (_, __) {},
                ),
                title: Text(
                  cellData.name,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ).animate().fadeIn();
          },
        ),
      );

  Widget _makeGrid(BuildContext context) => SliverPadding(
        padding: EdgeInsets.only(
            bottom: widget.systemNavigationInsets.bottom +
                MediaQuery.viewPaddingOf(context).bottom +
                (currentBottomSheet != null ? 48 + 4 : 0)),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: widget.aspectRatio,
              crossAxisCount: widget.description.columns.number),
          itemCount: _state.cellCount,
          itemBuilder: (context, indx) {
            var m = _state.getCell(indx);
            var cellData = m.getCellData(widget.description.listView);
            if (cellData.loaded != null && cellData.loaded == false) {
              widget.loadThumbsDirectly?.call(indx);
            }

            return _WrappedSelection(
              selectionEnabled: selected.isNotEmpty,
              thisIndx: indx,
              selectUntil: _selectUnselectUntil,
              selectUnselect: () => _selectOrUnselect(indx, m),
              isSelected: _isSelected(indx),
              child: GridCell(
                cell: cellData,
                hidealias: widget.hideAlias,
                indx: indx,
                download: widget.download,
                tight: widget.tightMode,
                onPressed: _onPressed,
                onLongPress: () =>
                    _selectOrUnselect(indx, m), //extend: maxExtend,
              ),
            );
          },
        ),
      );

  Widget _makeSegmentedRow(
    BuildContext context,
    List<int> val,
    double constraints,
    void Function(int) selectUntil,
    void Function(int, T) selectUnselect,
    bool Function(int) isSelected,
  ) =>
      Row(
        children: val.map((indx) {
          // indx = indx - 1;
          var m = _state.getCell(indx);
          var cellData = m.getCellData(widget.description.listView);
          if (cellData.loaded != null && cellData.loaded == false) {
            widget.loadThumbsDirectly?.call(indx);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints),
            child: material.AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: _WrappedSelection(
                selectionEnabled: selected.isNotEmpty,
                thisIndx: indx,
                selectUntil: selectUntil,
                selectUnselect: () => selectUnselect(indx, m),
                isSelected: isSelected(indx),
                child: GridCell(
                  cell: cellData,
                  hidealias: widget.hideAlias,
                  indx: indx,
                  download: widget.download,
                  tight: widget.tightMode,
                  onPressed: _onPressed,
                  onLongPress: () =>
                      selectUnselect(indx, m), //extend: maxExtend,
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _makeSegments(BuildContext context) {
    final segRows = <dynamic>[];
    final segMap = <String, List<int>>{};
    final stickySegs = <String, List<int>>{};

    final unsegmented = <int>[];

    for (var i = 0; i < _state.cellCount; i++) {
      final (res, sticky) = widget.segments!.segment(_state.getCell(i));
      if (res == null) {
        unsegmented.add(i);
      } else {
        if (sticky) {
          final previous = (stickySegs[res]) ?? [];
          previous.add(i);
          stickySegs[res] = previous;
        } else {
          final previous = (segMap[res]) ?? [];
          previous.add(i);
          segMap[res] = previous;
        }
      }
    }

    segMap.removeWhere((key, value) {
      if (value.length == 1) {
        unsegmented.add(value[0]);
        return true;
      }

      return false;
    });

    makeRows(List<int> value) {
      var row = <int>[];

      for (final i in value) {
        row.add(i);
        if (row.length == widget.description.columns.number) {
          segRows.add(row);
          row = [];
        }
      }

      if (row.isNotEmpty) {
        segRows.add(row);
      }
    }

    stickySegs.forEach((key, value) {
      segRows.add(_SegSticky(key, true));

      makeRows(value);
    });

    segMap.forEach(
      (key, value) {
        segRows.add(_SegSticky(key, false));

        makeRows(value);
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(_SegSticky(widget.segments!.unsegmentedLabel, false));

      makeRows(unsegmented);
    }

    final constraints =
        MediaQuery.of(context).size.width / widget.description.columns.number;

    return SliverPadding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom +
              MediaQuery.of(context).viewPadding.bottom),
      sliver: SliverList.builder(
        itemBuilder: (context, indx) {
          if (indx >= segRows.length) {
            return null;
          }
          final val = segRows[indx];
          if (val is _SegSticky) {
            return _segmentLabel(val.seg, val.sticky);
          } else if (val is List<int>) {
            return _makeSegmentedRow(context, val, constraints, (cellindx) {},
                (i, cell) {
              _selectOrUnselect(i, cell);
            }, (i) {
              return _isSelected(i);
            });
          }

          throw "invalid type";
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var bindings = _makeBindings(context);

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
          child: RefreshIndicator(
              onRefresh: _state._onRefresh,
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
                                        : 152,
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
                                                  EdgeInsetsDirectional.only(
                                                start: widget.onBack != null
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
                                                          .searchWidget?.search,
                                                    )
                                                  : Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8,
                                                              bottom: 16,
                                                              right: 8,
                                                              left: 8),
                                                      child: Text(
                                                        widget.description
                                                                .pageName ??
                                                            widget.description
                                                                .keybindsDescription,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ))),
                                      if (Platform.isAndroid || Platform.isIOS)
                                        if (widget.menuButtonItems != null &&
                                            (widget.menuButtonItems!.length ==
                                                    1 ||
                                                widget.inlineMenuButtonItems))
                                          ...widget.menuButtonItems!
                                              .map((e) => wrapAppBarAction(e)),
                                      if (widget.scaffoldKey.currentState
                                              ?.hasDrawer ??
                                          false)
                                        wrapAppBarAction(GestureDetector(
                                          onLongPress: () {
                                            setState(() {
                                              selected.clear();
                                              currentBottomSheet?.close();
                                            });
                                          },
                                          child: IconButton(
                                              onPressed: () {
                                                widget.scaffoldKey.currentState!
                                                    .openDrawer();
                                              },
                                              icon: const Icon(Icons.menu)),
                                        )),
                                      if (widget.menuButtonItems != null &&
                                          widget.menuButtonItems!.length != 1 &&
                                          !widget.inlineMenuButtonItems)
                                        wrapAppBarAction(PopupMenuButton(
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
                                            }))
                                    ]),
                                leading: widget.onBack != null
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selected.clear();
                                            currentBottomSheet?.close();
                                          });
                                          if (widget.onBack != null) {
                                            widget.onBack!();
                                          }
                                        },
                                        icon: const Icon(Icons.arrow_back))
                                    : Container(),
                                pinned: true,
                                stretch: true,
                                bottom: widget.description.bottomWidget != null
                                    ? widget.description.bottomWidget!
                                    : _state.isRefreshing
                                        ? const PreferredSize(
                                            preferredSize: Size.fromHeight(4),
                                            child: LinearProgressIndicator(),
                                          )
                                        : null,
                              );
                            },
                          )),
                      if (widget.segments == null)
                        !_state.isRefreshing && _state.cellCount == 0
                            ? SliverToBoxAdapter(
                                child: _state.cloudflareBlocked == true &&
                                        widget.cloudflareHook != null
                                    ? CloudflareBlock(
                                        interface: widget.cloudflareHook!(),
                                      )
                                    : const EmptyWidget())
                            : widget.description.listView
                                ? _makeList(context)
                                : _makeGrid(context)
                      else
                        _makeSegments(context),
                    ],
                  ))),
        ));
  }
}

class _SegSticky {
  final String seg;
  final bool sticky;

  const _SegSticky(this.seg, this.sticky);
}
