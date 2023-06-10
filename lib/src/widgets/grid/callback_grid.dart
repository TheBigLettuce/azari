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
import 'package:logging/logging.dart';
import '../../booru/tags/tags.dart';
import '../../cell/cell.dart';
import '../../keybinds/keybinds.dart';
import '../booru/autocomplete_tag.dart';
import 'cell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GridBottomSheetAction<T extends Cell> {
  final IconData icon;
  final void Function(List<T> selected) onPress;
  final bool closeOnPress;
  final bool showOnlyWhenSingle;

  const GridBottomSheetAction(this.icon, this.onPress, this.closeOnPress,
      {this.showOnlyWhenSingle = false});
}

class GridDescription<T extends Cell> {
  final int drawerIndex;
  final String pageDescription;
  final List<GridBottomSheetAction<T>> actions;

  const GridDescription(this.drawerIndex, this.pageDescription, this.actions);
}

class CallbackGrid<T extends Cell> extends StatefulWidget {
  final T Function(int) getCell;
  final int initalCellCount;
  final Future<int> Function()? loadNext;
  final Future<void> Function(int indx)? download;
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
  final List<Widget>? menuButtonItems;
  final EdgeInsets systemNavigationInsets;

  final bool tightMode;
  final double aspectRatio;
  final GridColumn columns;

  final bool? hideAlias;
  final void Function(BuildContext context, int indx)? overrideOnPress;
  final double? pageViewScrollingOffset;
  final int? initalCell;

  final Map<SingleActivatorDescription, Null Function()>? additionalKeybinds;

  final Stream<int>? progressTicker;

  final GridDescription<T> description;

  const CallbackGrid(
      {Key? key,
      this.additionalKeybinds,
      required this.getCell,
      required this.initalScrollPosition,
      required this.scaffoldKey,
      required this.systemNavigationInsets,
      required this.hasReachedEnd,
      required this.aspectRatio,
      required this.columns,
      this.tightMode = false,
      this.progressTicker,
      this.menuButtonItems,
      this.searchFilter,
      this.initalCell,
      this.pageViewScrollingOffset,
      this.loadNext,
      required this.search,
      required this.refresh,
      required this.updateScrollPosition,
      this.download,
      this.hideAlias,
      this.searchStartingValue = "",
      this.onBack,
      this.initalCellCount = 0,
      this.overrideOnPress,
      required this.description})
      : super(key: key);

  @override
  State<CallbackGrid<T>> createState() => CallbackGridState<T>();
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}

class CallbackGridState<T extends Cell> extends State<CallbackGrid<T>> {
  late ScrollController controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);

  int cellCount = 0;
  bool refreshing = true;
  final _ScrollHack _scrollHack = _ScrollHack();
  Settings settings = isar().settings.getSync(0)!;
  late final StreamSubscription<Settings?> settingsWatcher;
  //late GridColumn lastGridColCount = settings.picturesPerRow;

  BooruAPI booru = getBooru();

  late TextEditingController textEditingController =
      TextEditingController(text: widget.searchStartingValue);
  FocusNode focus = FocusNode();
  FocusNode mainFocus = FocusNode();

  Map<int, T> selected = {};

  PersistentBottomSheetController? currentBottomSheet;

  StreamSubscription<int>? ticker;

  int? lastSelected;

  String _currentlyHighlightedTag = "";

  Widget _wrapSheetButton(
      BuildContext context, IconData icon, void Function()? onPressed) {
    var background = Theme.of(context).colorScheme.background;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          background,
          background.withOpacity(0.7),
          background.withOpacity(0.3),
          background.withOpacity(0.1),
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: BoxShape.circle,
      ),
      child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: onPressed == null
                ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                : Theme.of(context).colorScheme.primary.withOpacity(0.9),
          )),
    );
  }

  void _addSelection(int id, T selection) {
    if (currentBottomSheet == null) {
      currentBottomSheet = showBottomSheet(
          context: context,
          enableDrag: false,
          builder: (context) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: widget.systemNavigationInsets.bottom),
              child: BottomSheet(
                  enableDrag: false,
                  onClosing: () {},
                  builder: (context) {
                    return Wrap(
                      spacing: 4,
                      children: [
                        _wrapSheetButton(context, Icons.close_rounded, () {
                          setState(() {
                            selected.clear();
                            currentBottomSheet?.close();
                          });
                        }),
                        ...widget.description.actions
                            .map((e) => _wrapSheetButton(
                                context,
                                e.icon,
                                e.showOnlyWhenSingle && selected.length != 1
                                    ? null
                                    : () {
                                        e.onPress(selected.values.toList());

                                        if (e.closeOnPress) {
                                          setState(() {
                                            selected.clear();
                                            currentBottomSheet?.close();
                                          });
                                        }
                                      }))
                            .toList()
                      ],
                    );
                  }),
            );
          });
    } else {
      if (currentBottomSheet != null && currentBottomSheet!.setState != null) {
        currentBottomSheet!.setState!(() {});
      }
    }

    setState(() {
      selected[id] = selection;
      lastSelected = id;
    });
  }

  void _removeSelection(int id) {
    setState(() {
      selected.remove(id);
      if (selected.isEmpty) {
        currentBottomSheet?.close();
        currentBottomSheet = null;
        lastSelected = null;
      } else {
        if (currentBottomSheet != null &&
            currentBottomSheet!.setState != null) {
          currentBottomSheet!.setState!(() {});
        }
      }
    });
  }

  void _selectUntil(int indx) {
    if (lastSelected != null) {
      if (lastSelected == indx) {
        return;
      }

      if (indx < lastSelected!) {
        for (var i = lastSelected!; i >= indx; i--) {
          selected[i] = widget.getCell(i);
          lastSelected = i;
        }
        setState(() {});
      } else if (indx > lastSelected!) {
        for (var i = lastSelected!; i <= indx; i++) {
          selected[i] = widget.getCell(i);
          lastSelected = i;
        }
        setState(() {});
      }

      if (currentBottomSheet != null && currentBottomSheet!.setState != null) {
        currentBottomSheet!.setState!(() {});
      }
    }
  }

  void _selectOrUnselect(int index, T selection) {
    if (selected[index] == null) {
      _addSelection(index, selection);
    } else {
      _removeSelection(index);
    }
  }

  @override
  void initState() {
    super.initState();

    focus.addListener(() {
      if (!focus.hasFocus) {
        _currentlyHighlightedTag = "";
        mainFocus.requestFocus();
      }
    });

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
      if (settings.selectedBooru != event!.selectedBooru) {
        cellCount = 0;

        return;
      }

      // not perfect, but fine
      /* if (lastGridColCount != event.picturesPerRow) {
        controller.position.jumpTo(controller.offset *
            lastGridColCount.number /
            event.picturesPerRow.number);
      }*/

      setState(() {
        settings = event;
        //lastGridColCount = event.picturesPerRow;
      });
    });

    if (widget.initalCellCount != 0) {
      cellCount = widget.initalCellCount;
      refreshing = false;
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

      if (!refreshing &&
          cellCount != 0 &&
          (controller.offset / controller.positions.first.maxScrollExtent) >=
              0.95) {
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
    _scrollHack.dispose();

    focus.dispose();
    mainFocus.dispose();

    booru.close();

    super.dispose();
  }

  Future refresh() {
    currentBottomSheet?.close();
    selected.clear();

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
    var picPerRow = widget.columns;
    // Get the full content height.
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    // Estimate the target scroll position.
    double target;
    if (settings.listViewBooru) {
      target = contentSize * p / cellCount;
    } else {
      target = contentSize *
          (p / picPerRow.number - 1) /
          (cellCount / picPerRow.number);
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
        download: widget.download,
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
    var bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.refresh,
          const SingleActivator(LogicalKeyboardKey.f5)): () {
        if (!refreshing) {
          setState(() {
            cellCount = 0;
            refreshing = true;
          });
          refresh();
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.selectSuggestion,
          const SingleActivator(LogicalKeyboardKey.enter, shift: true)): () {
        if (_currentlyHighlightedTag != "") {
          mainFocus.unfocus();
          BooruTags().onPressed(context, _currentlyHighlightedTag);
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true)): () {
        if (focus.hasFocus) {
          focus.unfocus();
        } else {
          focus.requestFocus();
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
      ...digitAndSettings(context, widget.description.drawerIndex),
    };

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(context, describeKeys(bindings),
              widget.description.pageDescription)
        },
        child: Focus(
          autofocus: true,
          focusNode: mainFocus,
          child: RefreshIndicator(
              onRefresh: () {
                if (!refreshing) {
                  setState(() {
                    cellCount = 0;
                    refreshing = true;
                  });
                  return refresh();
                }

                return Future.value();
              },
              child: Scrollbar(
                  interactive: true,
                  thickness: 6,
                  controller: controller,
                  child: CustomScrollView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        title: autocompleteWidget(
                          textEditingController,
                          (s) {
                            _currentlyHighlightedTag = s;
                          },
                          (s) {
                            if (refreshing) {
                              return;
                            }

                            widget.search(s);
                          },
                          booru.completeTag,
                          focus,
                          scrollHack: _scrollHack,
                        ),
                        actions: [
                          if (widget.onBack != null &&
                              (Platform.isAndroid || Platform.isIOS))
                            IconButton(
                                onPressed: () {
                                  widget.scaffoldKey.currentState!.openDrawer();
                                },
                                icon: const Icon(Icons.menu)),
                          if (widget.menuButtonItems != null)
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
                                }),
                        ],
                        leading: widget.onBack != null
                            ? IconButton(
                                onPressed: () {
                                  selected.clear();
                                  currentBottomSheet?.close();
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  }
                                },
                                icon: const Icon(Icons.arrow_back))
                            : null,
                        pinned:
                            Platform.isAndroid || Platform.isIOS ? false : true,
                        snap:
                            Platform.isAndroid || Platform.isIOS ? true : false,
                        floating:
                            Platform.isAndroid || Platform.isIOS ? true : false,
                        bottom: refreshing
                            ? const PreferredSize(
                                preferredSize: Size.fromHeight(4),
                                child: LinearProgressIndicator(),
                              )
                            : null,
                        shape: Platform.isAndroid
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))
                            : null,
                      ),
                      settings.listViewBooru
                          ? SliverList.separated(
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                height: 1,
                              ),
                              itemCount: cellCount,
                              itemBuilder: (context, index) {
                                var cell = widget.getCell(index);
                                var cellData =
                                    cell.getCellData(settings.listViewBooru);
                                ;

                                return _WrappedSelection(
                                  selectUntil: _selectUntil,
                                  thisIndx: index,
                                  isSelected: selected[index] != null,
                                  selectionEnabled: selected.isNotEmpty,
                                  selectUnselect: () =>
                                      _selectOrUnselect(index, cell),
                                  child: ListTile(
                                    onLongPress: () =>
                                        _selectOrUnselect(index, cell),
                                    onTap: () => _onPressed(context, index),
                                    leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .background,
                                        foregroundImage: cellData.thumb),
                                    title: Text(
                                      cellData.name,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ).animate().fadeIn();
                              },
                            )
                          : SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      childAspectRatio: widget.aspectRatio,
                                      crossAxisCount: widget.columns.number),
                              itemCount: cellCount,
                              itemBuilder: (context, indx) {
                                var m = widget.getCell(indx);
                                var cellData =
                                    m.getCellData(settings.listViewBooru);

                                return _WrappedSelection(
                                  selectionEnabled: selected.isNotEmpty,
                                  thisIndx: indx,
                                  selectUntil: _selectUntil,
                                  selectUnselect: () =>
                                      _selectOrUnselect(indx, m),
                                  isSelected: selected[indx] != null,
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
                            )
                    ],
                  ))),
        ));
  }
}

/* widget.onLongPress == null
                                        ? null
                                        : () async {
                                            widget.onLongPress!(indx)
                                                .onError((error, stackTrace) {
                                              log("onLongPress in the grid callback to CellImageWidget",
                                                  level: Level.WARNING.value,
                                                  error: error,
                                                  stackTrace: stackTrace);
                                            });
                                          } */

class _WrappedSelection extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool selectionEnabled;
  final int thisIndx;
  final void Function() selectUnselect;
  final void Function(int indx) selectUntil;
  const _WrappedSelection(
      {required this.child,
      required this.isSelected,
      required this.selectUnselect,
      required this.thisIndx,
      required this.selectionEnabled,
      required this.selectUntil});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: selectUnselect,
          onLongPress: () => selectUntil(thisIndx),
          child: AbsorbPointer(
            absorbing: selectionEnabled,
            child: child,
          ),
        ),
        if (isSelected)
          GestureDetector(
            onTap: selectUnselect,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: Theme.of(context).iconTheme.size,
                    height: Theme.of(context).iconTheme.size,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle),
                      child: Icon(
                        Icons.check_outlined,
                        color: Theme.of(context).brightness != Brightness.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primaryContainer,
                        shadows: const [
                          Shadow(blurRadius: 0, color: Colors.black)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
