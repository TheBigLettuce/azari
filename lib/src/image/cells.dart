// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/image/view.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:logging/logging.dart';
import '../cell/cell.dart';
import '../cell/image_widget.dart';

class CellsWidget<T extends Cell> extends StatefulWidget {
  final T Function(int) getCell;
  final int initalCellCount;
  final Future<int> Function()? loadNext;
  final Future<void> Function(int indx)? onLongPress;
  final Future<int> Function() refresh;
  final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;
  final double initalScrollPosition;
  final void Function(String value) search;
  final List<String> Function(String value)? searchFilter;
  final String searchStartingValue;
  final void Function()? onBack;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool Function() hasReachedEnd;

  final bool? hideAlias;
  final void Function(BuildContext context, int indx)? overrideOnPress;
  final double? pageViewScrollingOffset;
  final int? initalCell;

  final Stream<int>? progressTicker;

  const CellsWidget({
    Key? key,
    required this.getCell,
    required this.initalScrollPosition,
    required this.scaffoldKey,
    required this.hasReachedEnd,
    this.progressTicker,
    this.searchFilter,
    this.initalCell,
    this.pageViewScrollingOffset,
    this.loadNext,
    required this.search,
    required this.refresh,
    required this.updateScrollPosition,
    this.onLongPress,
    this.hideAlias,
    this.searchStartingValue = "",
    this.onBack,
    this.initalCellCount = 0,
    this.overrideOnPress,
  }) : super(key: key);

  @override
  State<CellsWidget<T>> createState() => _CellsWidgetState<T>();
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}

class _CellsWidgetState<T extends Cell> extends State<CellsWidget<T>> {
  late ScrollController controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);

  late int cellCount = 0;
  bool refreshing = true;
  _ScrollHack scrollHack = _ScrollHack();
  Settings settings = isar().settings.getSync(0)!;
  late final StreamSubscription<Settings?> settingsWatcher;
  late int lastGridColCount = settings.picturesPerRow;

  late TextEditingController textEditingController =
      TextEditingController(text: widget.searchStartingValue);
  FocusNode focus = FocusNode();

  StreamSubscription<int>? ticker;

  @override
  void initState() {
    super.initState();

    if (widget.progressTicker != null) {
      ticker = widget.progressTicker!.listen((event) {
        setState(() {
          cellCount = event;
        });
      });
    }

    if (widget.pageViewScrollingOffset != null && widget.initalCell != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        _onPressed(context, widget.initalCell!,
            offset: widget.pageViewScrollingOffset);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.position.isScrollingNotifier.addListener(() {
        if (!refreshing) {
          widget.updateScrollPosition(controller.offset);
        }
      });
    });

    settingsWatcher = isar().settings.watchObject(0).listen((event) {
      // not perfect, but fine
      if (lastGridColCount != event!.picturesPerRow) {
        controller.position.jumpTo(
            controller.offset * lastGridColCount / event.picturesPerRow);
      }

      setState(() {
        settings = event;
        lastGridColCount = event.picturesPerRow;
      });
    });

    widget.updateScrollPosition(0);

    if (widget.initalCellCount != 0) {
      cellCount = widget.initalCellCount;
      refreshing = false;
    } else {
      _refresh();
    }

    if (widget.loadNext == null) {
      return;
    }

    controller.addListener(() {
      if (widget.hasReachedEnd()) {
        return;
      }

      if (!refreshing &&
          cellCount != 0 &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              0.8) {
        setState(() {
          refreshing = true;
        });
        widget.loadNext!().then((value) {
          if (context.mounted) {
            setState(() {
              cellCount = value;
              refreshing = false;
            });
          }
        }).onError((error, stackTrace) {
          log("loading next cells in the grid",
              level: Level.WARNING.value, error: error, stackTrace: stackTrace);
        });
      }
    });
  }

  @override
  void dispose() {
    if (ticker != null) {
      ticker!.cancel();
    }

    textEditingController.dispose();
    controller.dispose();
    settingsWatcher.cancel();
    scrollHack.dispose();

    focus.dispose();

    super.dispose();
  }

  Future _refresh() {
    return widget.refresh().then((value) {
      if (context.mounted) {
        setState(() {
          cellCount = value;
          refreshing = false;
        });
      }
    }).onError((error, stackTrace) {
      log("refreshing cells in the grid",
          level: Level.WARNING.value, error: error, stackTrace: stackTrace);
    });
  }

  void _scrollUntill(int p) {
    var picPerRow = settings.picturesPerRow;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (settings.listViewBooru) {
      target = contentSize * p / cellCount;
    } else {
      target = contentSize * (p / picPerRow - 1) / (cellCount / picPerRow);
    }

    if (target < controller.position.minScrollExtent) {
      widget.updateScrollPosition(controller.position.minScrollExtent);
      return;
    } else if (target > controller.position.maxScrollExtent) {
      widget.updateScrollPosition(controller.position.maxScrollExtent);
      return;
    }

    widget.updateScrollPosition(target);

    controller.jumpTo(target);
  }

  void _onPressed(BuildContext context, int i, {double? offset}) {
    if (widget.overrideOnPress != null) {
      widget.overrideOnPress!(context, i);
      return;
    }

    var offsetGrid = controller.offset;
    var overlayColor =
        Theme.of(context).colorScheme.background.withOpacity(0.5);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageView<T>(
        systemOverlayRestoreColor: overlayColor,
        updateTagScrollPos: (pos, selectedCell) => widget.updateScrollPosition(
            offsetGrid,
            infoPos: pos,
            selectedCell: selectedCell),
        scrollUntill: _scrollUntill,
        infoScrollOffset: offset,
        getCell: widget.getCell,
        cellCount: cellCount,
        download: widget.onLongPress,
        startingCell: i,
        onNearEnd: widget.loadNext == null
            ? null
            : () async {
                return widget.loadNext!().then((value) {
                  if (context.mounted) {
                    setState(() {
                      cellCount = value;
                    });
                  }

                  return value;
                });
              },
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () {
          if (!refreshing) {
            setState(() {
              cellCount = 0;
              refreshing = true;
            });
            return _refresh();
          }

          return Future.value();
        },
        child: Stack(
          children: [
            Scrollbar(
                interactive: true,
                thickness: 6,
                controller: controller,
                child: CustomScrollView(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      title: autocompleteWidget(
                        textEditingController,
                        (s) {
                          if (refreshing) {
                            return;
                          }

                          widget.search(s);
                        },
                        focus,
                        scrollHack: scrollHack,
                      ),
                      actions: widget.onBack != null
                          ? [
                              IconButton(
                                  onPressed: () {
                                    widget.scaffoldKey.currentState!
                                        .openDrawer();
                                  },
                                  icon: const Icon(Icons.menu))
                            ]
                          : null,
                      leading: widget.onBack != null
                          ? IconButton(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back))
                          : null,
                      snap: true,
                      floating: true,
                      bottom: refreshing
                          ? const PreferredSize(
                              preferredSize: Size.fromHeight(4),
                              child: LinearProgressIndicator(),
                            )
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    settings.listViewBooru
                        ? SliverList.separated(
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                            ),
                            itemCount: cellCount,
                            itemBuilder: (context, index) {
                              var cell = widget
                                  .getCell(index)
                                  .getCellData(settings.listViewBooru);

                              return ListTile(
                                onTap: () => _onPressed(context, index),
                                leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    foregroundImage: cell.thumb()),
                                title: Text(
                                  cell.name,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ).animate().fadeIn();
                            },
                          )
                        : SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: settings.picturesPerRow),
                            itemCount: cellCount,
                            itemBuilder: (context, indx) {
                              var m = widget
                                  .getCell(indx)
                                  .getCellData(settings.listViewBooru);
                              return CellImageWidget(
                                cell: m,
                                hidealias: widget.hideAlias,
                                indx: indx,
                                onPressed: _onPressed,
                                onLongPress: widget.onLongPress == null
                                    ? null
                                    : () async {
                                        widget.onLongPress!(indx)
                                            .onError((error, stackTrace) {
                                          log("onLongPress in the grid callback to CellImageWidget",
                                              level: Level.WARNING.value,
                                              error: error,
                                              stackTrace: stackTrace);
                                        });
                                      }, //extend: maxExtend,
                              );
                            },
                          )
                  ],
                ))
          ],
        ));
  }
}
