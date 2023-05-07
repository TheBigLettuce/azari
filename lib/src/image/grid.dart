import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gallery/src/image/view.dart';
import '../cell/cell.dart';
import '../cell/image_widget.dart';

class ImageGrid<T extends Cell> extends StatefulWidget {
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

  final int? numbRow;
  final bool? hideAlias;
  final void Function(BuildContext context, int indx)? overrideOnPress;

  const ImageGrid({
    Key? key,
    required this.getCell,
    required this.initalScrollPosition,
    this.searchFilter,
    this.loadNext,
    required this.search,
    required this.refresh,
    this.updateScrollPosition,
    this.numbRow,
    this.onLongPress,
    this.hideAlias,
    this.searchStartingValue = "",
    this.showBack = false,
    this.initalCellCount = 0,
    this.overrideOnPress,
  }) : super(key: key);

  @override
  State<ImageGrid> createState() => _ImageGridState<T>();
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}

class _ImageGridState<T extends Cell> extends State<ImageGrid<T>> {
  static const maxExtend = 150.0;
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

  @override
  void initState() {
    super.initState();

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
            setState(() {
              cellCount = 0;
              refreshing = true;
            });

            return _refresh();
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
                          style: MenuStyle(
                              side: MaterialStatePropertyAll(BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .background)),
                              shape: MaterialStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)))),
                          controller: menuController,
                          menuChildren: menuItems,
                          child: TextField(
                            scrollController: scrollHack,
                            focusNode: focus,
                            controller: textController,
                            onSubmitted: widget.search,
                            cursorOpacityAnimates: true,
                            onChanged: widget.searchFilter == null
                                ? null
                                : (value) {
                                    var newItems = widget.searchFilter!(value)
                                        .map((e) => ListTile(
                                              title: Text(e),
                                              onTap: () {
                                                menuController.close();
                                                widget.search(e);
                                              },
                                            ))
                                        .toList();
                                    if (newItems.isEmpty) {
                                      menuController.close();
                                    } else {
                                      setState(() {
                                        menuItems = newItems;
                                      });
                                      menuController.open();
                                    }
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
                        leading: widget.showBack
                            ? IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.arrow_back))
                            : null,
                        snap: true,

                        //flexibleSpace: FlexibleSpaceBar(title: Text("")),
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
                      SliverGrid.builder(
                        gridDelegate: widget.numbRow != null
                            ? SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.numbRow!)
                            : const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxExtend,
                              ),
                        itemCount: cellCount,
                        itemBuilder: (context, indx) {
                          var m = widget.getCell(indx);
                          return CellImageWidget<T>(
                            cell: m,
                            hidealias: widget.hideAlias,
                            indx: indx,
                            onPressed: (context, i) {
                              focus.unfocus();
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ImageView<T>(
                                  getCell: widget.getCell,
                                  cellCount: cellCount,
                                  download: widget.onLongPress,
                                  startingCell: i,
                                  onNearEnd: widget.loadNext == null
                                      ? null
                                      : () async {
                                          return widget.loadNext!()
                                              .then((value) {
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
                            },
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
