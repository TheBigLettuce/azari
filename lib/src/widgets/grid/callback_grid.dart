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
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/schemas/settings.dart';
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
part 'filter.dart';
part 'mutation.dart';

class CloudflareBlockInterface {
  final BooruAPI api;

  const CloudflareBlockInterface(this.api);
}

class GridBottomSheetAction<B> {
  final IconData icon;
  final void Function(List<B> selected) onPress;
  final bool closeOnPress;
  final bool showOnlyWhenSingle;

  const GridBottomSheetAction(this.icon, this.onPress, this.closeOnPress,
      {this.showOnlyWhenSingle = false});
}

class GridDescription<B> {
  final int drawerIndex;
  final String keybindsDescription;
  final String? pageName;
  final List<GridBottomSheetAction<B>> actions;
  final GridColumn columns;
  final DateTime? time;

  const GridDescription(this.drawerIndex, this.actions, this.columns,
      {required this.keybindsDescription, this.pageName, this.time});
}

abstract class SearchFilter<T extends Cell<B>, B> {
  void setValue(String s);
  int count();
  T getCell(int i);
}

class CallbackGrid<T extends Cell<B>, B> extends StatefulWidget {
  final Future<int> Function()? loadNext;
  final Future<void> Function(int indx)? download;
  final Future<int>? Function() refresh;
  final void Function({required bool fab, required bool foreground})?
      hideShowFab;
  final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;
  final void Function()? onBack;
  final void Function(BuildContext context, int indx)? overrideOnPress;
  final T Function(int) getCell;
  final bool Function() hasReachedEnd;
  final Map<SingleActivatorDescription, Null Function()>? additionalKeybinds;

  final SearchAndFocus? searchWidget;

  final int initalCellCount;
  final int? initalCell;
  final double initalScrollPosition;
  final double aspectRatio;
  final double? pageViewScrollingOffset;
  final bool tightMode;
  final bool? hideAlias;

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? menuButtonItems;
  final EdgeInsets systemNavigationInsets;
  final FocusNode mainFocus;
  final Stream<int>? progressTicker;
  final bool immutable;

  final GridDescription<B> description;
  final FocusNode? belowMainFocus;
  final List<IconButton> Function(ImageViewState<T> icons)? addIconsImage;
  final void Function(ImageViewState<T> state)? pageChangeImage;

  final CloudflareBlockInterface Function()? cloudflareHook;
  final void Function(int from)? loadThumbsDirectly;

  const CallbackGrid(
      {Key? key,
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
      this.immutable = true,
      this.tightMode = false,
      this.loadThumbsDirectly,
      this.belowMainFocus,
      this.progressTicker,
      this.menuButtonItems,
      this.searchWidget,
      this.initalCell,
      this.pageViewScrollingOffset,
      this.loadNext,
      required this.refresh,
      required this.updateScrollPosition,
      this.hideShowFab,
      this.download,
      this.hideAlias,
      this.onBack,
      this.initalCellCount = 0,
      this.overrideOnPress,
      required this.description})
      : super(key: key);

  @override
  State<CallbackGrid<T, B>> createState() => CallbackGridState<T, B>();
}

class SearchAndFocus {
  final Widget search;
  final FocusNode focus;
  final void Function()? onPressed;

  const SearchAndFocus(this.search, this.focus, {this.onPressed});
}

class CallbackGridState<T extends Cell<B>, B> extends State<CallbackGrid<T, B>>
    with _Selection<T, B>, _Filter<T, B>, SingleTickerProviderStateMixin {
  late ScrollController controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);

  Settings settings = settingsIsar().settings.getSync(0)!;

  late final StreamSubscription<Settings?> settingsWatcher;

  StreamSubscription<int>? ticker;

  bool inImageView = false;

  double height = 0;
  late final _Mutation<T, B> _state = _Mutation(
    scrollUp: () {
      if (widget.hideShowFab != null) {
        widget.hideShowFab!(fab: false, foreground: inImageView);
      }
    },
    unselectAll: () {
      selected.clear();
      currentBottomSheet?.close();
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

  GridMutationInterface<T, B>? get mutationInterface =>
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
      height = MediaQuery.sizeOf(context).height;
      controller.position.isScrollingNotifier.addListener(() {
        if (!_state.isRefreshing) {
          widget.updateScrollPosition(controller.offset);
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

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      // if (settings.selectedBooru != event!.selectedBooru) {
      //   _state._cellCount = 0;
      //   return;
      // }

      // not perfect, but fine
      /* if (lastGridColCount != event.picturesPerRow) {
        controller.position.jumpTo(controller.offset *
            lastGridColCount.number /
            event.picturesPerRow.number);
      }*/

      setState(() {
        settings = event!;
        //lastGridColCount = event.picturesPerRow;
      });
    });

    if (settings.autoRefresh &&
        settings.autoRefreshMicroseconds != 0 &&
        widget.description.time != null &&
        widget.description.time!.isBefore(DateTime.now()
            .subtract(settings.autoRefreshMicroseconds.microseconds))) {
      refresh();
    } else if (widget.initalCellCount != 0) {
      _state._cellCount = widget.initalCellCount;
      //  refreshing = false;
    } else {
      refresh();
    }

    // var offset = controller.offset;
    // if (offset != 0) {
    //   final contentSize = controller.position.viewportDimension +
    //       controller.position.maxScrollExtent;
    //   final cellHeight =
    //       contentSize / (_state.cellCount / widget.description.columns.number);
    //   final firstVisible =
    //       offset * widget.description.columns.number ~/ cellHeight;

    //   widget.scrollCallback!(firstVisible);
    // }

    if (widget.loadNext == null) {
      return;
    }

    controller.addListener(() {
      if (widget.hasReachedEnd()) {
        return;
      }

      var hh = height - height * 0.90;

      if (!_state.isRefreshing &&
          _state.cellCount != 0 &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              1 - (hh / controller.positions.first.maxScrollExtent)) {
        _state._loadNext();
      }
    });
  }

  @override
  void dispose() {
    ticker?.cancel();

    // animation.dispose();
    controller.dispose();
    settingsWatcher.cancel();
    widget.belowMainFocus?.requestFocus();

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
    if (settings.listViewBooru) {
      target = contentSize * p / _state.cellCount;
    } else {
      target = contentSize *
          (p / picPerRow.number - 1) /
          (_state.cellCount / picPerRow.number);
    }

    if (target < controller.position.minScrollExtent) {
      widget.updateScrollPosition(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      if (widget.hasReachedEnd()) {
        widget.updateScrollPosition(controller.position.maxScrollExtent);
        return;
      }
    }

    widget.updateScrollPosition(target);

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
          systemOverlayRestoreColor: overlayColor,
          updateTagScrollPos: (pos, selectedCell) =>
              widget.updateScrollPosition(offsetGrid,
                  infoPos: pos, selectedCell: selectedCell),
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
                  interactive: true,
                  thumbVisibility:
                      Platform.isAndroid || Platform.isIOS ? false : true,
                  thickness: 6,
                  controller: controller,
                  child: CustomScrollView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(0.90),
                        expandedHeight: 152,
                        collapsedHeight: 64,
                        automaticallyImplyLeading: false,
                        actions: [Container()],
                        flexibleSpace: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: FlexibleSpaceBar(
                                      titlePadding: EdgeInsetsDirectional.only(
                                          start: widget.onBack != null ? 48 : 0,
                                          bottom: 8),
                                      title: widget.searchWidget?.search ??
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              widget.description.pageName ??
                                                  widget.description
                                                      .keybindsDescription,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))),
                              if (Platform.isAndroid || Platform.isIOS)
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
                              if (widget.menuButtonItems != null)
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
                        bottom: _state.isRefreshing
                            ? const PreferredSize(
                                preferredSize: Size.fromHeight(4),
                                child: LinearProgressIndicator(),
                              )
                            : null,
                      ),
                      !_state.isRefreshing && _state.cellCount == 0
                          ? SliverToBoxAdapter(
                              child: _state.cloudflareBlocked == true &&
                                      widget.cloudflareHook != null
                                  ? CloudflareBlock(
                                      interface: widget.cloudflareHook!(),
                                    )
                                  : const EmptyWidget())
                          : settings.listViewBooru
                              ? SliverPadding(
                                  padding: EdgeInsets.only(
                                      bottom:
                                          widget.systemNavigationInsets.bottom),
                                  sliver: SliverList.separated(
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                      height: 1,
                                    ),
                                    itemCount: _state.cellCount,
                                    itemBuilder: (context, index) {
                                      var cell = _state.getCell(index);
                                      var cellData = cell
                                          .getCellData(settings.listViewBooru);
                                      if (cellData.loaded != null &&
                                          cellData.loaded == false) {
                                        widget.loadThumbsDirectly?.call(index);
                                      }

                                      return _WrappedSelection(
                                        selectUntil: _selectUnselectUntil,
                                        thisIndx: index,
                                        isSelected: _isSelected(index),
                                        selectionEnabled: selected.isNotEmpty,
                                        selectUnselect: () =>
                                            _selectOrUnselect(index, cell),
                                        child: ListTile(
                                          onLongPress: () =>
                                              _selectOrUnselect(index, cell),
                                          onTap: () =>
                                              _onPressed(context, index),
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .background,
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
                                )
                              : SliverPadding(
                                  padding: EdgeInsets.only(
                                      bottom:
                                          widget.systemNavigationInsets.bottom),
                                  sliver: SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            childAspectRatio:
                                                widget.aspectRatio,
                                            crossAxisCount: widget
                                                .description.columns.number),
                                    itemCount: _state.cellCount,
                                    itemBuilder: (context, indx) {
                                      var m = _state.getCell(indx);
                                      var cellData =
                                          m.getCellData(settings.listViewBooru);
                                      if (cellData.loaded != null &&
                                          cellData.loaded == false) {
                                        widget.loadThumbsDirectly?.call(indx);
                                      }

                                      return _WrappedSelection(
                                        selectionEnabled: selected.isNotEmpty,
                                        thisIndx: indx,
                                        selectUntil: _selectUnselectUntil,
                                        selectUnselect: () =>
                                            _selectOrUnselect(indx, m),
                                        isSelected: _isSelected(indx),
                                        child: GridCell(
                                          cell: cellData,
                                          hidealias: widget.hideAlias,
                                          indx: indx,
                                          tight: widget.tightMode,
                                          onPressed: _onPressed,
                                          onLongPress: () => _selectOrUnselect(
                                              indx, m), //extend: maxExtend,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
                  ))),
        ));
  }
}
