import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/image/view.dart';

import '../cell/cell.dart';
import '../cell/image_widget.dart';

class ImageGrid<T extends Cell> extends StatefulWidget {
  final T Function(int) getCell;
  final int? initalCellCount;
  final Future<int> Function()? loadNext;
  final Future<void> Function(int indx)? onLongPress;
  final Future<int> Function() refresh;
  final void Function(double pos)? updateScrollPosition;
  final double initalScrollPosition;

  final int? numbRow;
  final bool? hideAlias;
  final void Function(BuildContext context, int indx)? overrideOnPress;

  const ImageGrid({
    Key? key,
    required this.getCell,
    required this.initalScrollPosition,
    this.loadNext,
    required this.refresh,
    this.updateScrollPosition,
    this.numbRow,
    this.onLongPress,
    this.hideAlias,
    this.initalCellCount,
    this.overrideOnPress,
  }) : super(key: key);

  @override
  State<ImageGrid> createState() => _ImageGridState<T>();
}

class _ImageGridState<T extends Cell> extends State<ImageGrid<T>> {
  static const maxExtend = 150.0;
  late ScrollController controller =
      ScrollController(initialScrollOffset: widget.initalScrollPosition);
  late int cellCount = 0;
  bool refreshing = true;

  @override
  void initState() {
    super.initState();

    if (widget.initalCellCount != null) {
      cellCount = widget.initalCellCount!;
      refreshing = false;
    } else {
      _refresh();
    }

    if (widget.updateScrollPosition != null) {
      controller.addListener(() {
        widget.updateScrollPosition!(controller.offset);
      });
    }

    if (widget.loadNext == null) {
      return;
    }

    controller.addListener(() {
      if (!refreshing &&
          cellCount != 0 &&
          controller.offset == controller.positions.first.maxScrollExtent) {
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
    //disposed =true;
    controller.dispose();

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
    return RefreshIndicator(onRefresh: () {
      setState(() {
        refreshing = true;
      });

      return _refresh();
    }, child: Stack(
      children: () {
        List<Widget> list = [
          Scrollbar(
              interactive: true,
              thickness: 6,
              controller: controller,
              child: GridView.builder(
                gridDelegate: widget.numbRow != null
                    ? SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.numbRow!)
                    : const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxExtend,
                      ),
                itemCount: cellCount,
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, indx) {
                  var m = widget.getCell(indx);
                  return CellImageWidget<T>(
                    cell: m,
                    hidealias: widget.hideAlias,
                    indx: indx,
                    onPressed: (context, i) {
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
              )),
        ];

        if (refreshing) {
          list.add(
            const LinearProgressIndicator(),
          );
        }

        return list;
      }(),
    ));
  }
}
