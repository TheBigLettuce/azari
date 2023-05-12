import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/image/view.dart';
import 'package:gallery/src/schemas/settings.dart';
import '../cell/cell.dart';
import '../cell/image_widget.dart';

class CellsWidget<T extends Cell> extends StatefulWidget {
  final T Function(int) getCell;
  final int initalCellCount;
  final Future<int> Function()? loadNext;
  final Future<void> Function(int indx)? onLongPress;
  final Future<int> Function() refresh;
  final void Function(double pos)? updateScrollPosition;
  final double initalScrollPosition;
  final void Function(String value) search;
  final List<String> Function(String value)? searchFilter;
  final String searchStartingValue;
  final bool showBack;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool Function() hasReachedEnd;

  final bool? hideAlias;
  final void Function(BuildContext context, int indx)? overrideOnPress;

  const CellsWidget({
    Key? key,
    required this.getCell,
    required this.initalScrollPosition,
    required this.scaffoldKey,
    required this.hasReachedEnd,
    this.searchFilter,
    this.loadNext,
    required this.search,
    required this.refresh,
    this.updateScrollPosition,
    this.onLongPress,
    this.hideAlias,
    this.searchStartingValue = "",
    this.showBack = false,
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
  late TextEditingController textController =
      TextEditingController(text: widget.searchStartingValue);
  FocusNode focus = FocusNode();
  late int cellCount = 0;
  MenuController menuController = MenuController();
  bool refreshing = true;
  List<Widget> menuItems = [];
  _ScrollHack scrollHack = _ScrollHack();
  Settings settings = isar().settings.getSync(0)!;
  late final StreamSubscription<Settings?> settingsWatcher;
  late int lastGridColCount = settings.picturesPerRow;

  @override
  void initState() {
    super.initState();

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

    if (widget.initalCellCount != 0) {
      cellCount = widget.initalCellCount;
      refreshing = false;
    } else {
      _refresh();
    }

    if (widget.updateScrollPosition != null) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        controller.positions.first.isScrollingNotifier.addListener(() {
          widget.updateScrollPosition!(controller.offset);
        });
      });
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
          print(error);
        });
      }
    });
  }

  @override
  void dispose() {
    focus.dispose();
    controller.dispose();
    textController.dispose();
    settingsWatcher.cancel();

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
      print(error);
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

    if (widget.updateScrollPosition != null) {
      widget.updateScrollPosition!(target);
    }

    controller.jumpTo(target);
  }

  void _onPressed(BuildContext context, int i) {
    focus.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageView<T>(
        scrollUntill: _scrollUntill,
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
    return WillPopScope(
      onWillPop: () {
        if (focus.hasFocus) {
          focus.unfocus();
          return Future.value(false);
        }

        return Future.value(true);
      },
      child: RefreshIndicator(
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
                        title: MenuAnchor(
                          style: tagCompleteMenuStyle(),
                          controller: menuController,
                          menuChildren: menuItems,
                          child: TextField(
                            scrollController: scrollHack,
                            focusNode: focus,
                            controller: textController,
                            onSubmitted: (s) {
                              if (widget.showBack) {
                                setState(() {
                                  cellCount = 0;
                                });
                              }
                              widget.search(s);
                            },
                            cursorOpacityAnimates: true,
                            onChanged: widget.searchFilter == null
                                ? null
                                : (value) {
                                    menuItems.clear();

                                    autoCompleteTag(
                                            value,
                                            menuController,
                                            textController,
                                            (s) => Future.value(
                                                widget.searchFilter!(s)))
                                        .then((newItems) {
                                      if (newItems.isEmpty) {
                                        menuController.close();
                                      } else {
                                        setState(() {
                                          menuItems = newItems;
                                        });
                                        menuController.open();
                                      }
                                    }).onError((error, stackTrace) {
                                      print(error);
                                    });
                                  },
                            decoration: InputDecoration(
                                suffix: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () {
                                    textController.clear();
                                    focus.unfocus();
                                    menuController.close();
                                  },
                                  child: const Icon(Icons.delete),
                                ),
                                hintText: "Search",
                                border: InputBorder.none,
                                isDense: true),
                          ),
                        ),
                        actions: widget.showBack
                            ? [
                                IconButton(
                                    onPressed: () {
                                      widget.scaffoldKey.currentState!
                                          .openDrawer();
                                    },
                                    icon: const Icon(Icons.menu))
                              ]
                            : null,
                        leading: widget.showBack
                            ? IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
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
                          ? SliverList.builder(
                              itemCount: cellCount,
                              itemBuilder: (context, index) {
                                var cell = widget.getCell(index).getCellData();
                                return ListTile(
                                  onTap: () => _onPressed(context, index),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    backgroundImage: CachedNetworkImageProvider(
                                        cell.thumbUrl),
                                  ),
                                  title: Text(cell.name),
                                );
                              },
                            )
                          : SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: settings.picturesPerRow),
                              itemCount: cellCount,
                              itemBuilder: (context, indx) {
                                var m = widget.getCell(indx);
                                return CellImageWidget<T>(
                                  cell: m,
                                  hidealias: widget.hideAlias,
                                  indx: indx,
                                  onPressed: _onPressed,
                                  onLongPress: widget.onLongPress == null
                                      ? null
                                      : () async {
                                          widget.onLongPress!(indx)
                                              .onError((error, stackTrace) {
                                            print(error);
                                          });
                                        }, //extend: maxExtend,
                                );
                              },
                            )
                    ],
                  ))
            ],
          )),
    );
  }
}
