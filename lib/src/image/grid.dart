import 'package:flutter/material.dart';

import '../cell/cell.dart';
import '../cell/image_widget.dart';

class ImageGrid<T extends Cell> extends StatefulWidget {
  final List<T> data;
  final Null Function(BuildContext context, int cellIndx) onPressed;
  final Future Function(int indx)? onLongPress;
  final Future Function() onOverscroll;
  final int? numbRow;
  final bool? hideAlias;
  const ImageGrid(
      {Key? key,
      required this.data,
      required this.onPressed,
      required this.onOverscroll,
      this.numbRow,
      this.onLongPress,
      this.hideAlias})
      : super(key: key);

  @override
  State<ImageGrid> createState() => _ImageGridState<T>();
}

class _ImageGridState<T extends Cell> extends State<ImageGrid<T>> {
  static const maxExtend = 150.0;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onOverscroll,
      child: GridView.builder(
        gridDelegate: widget.numbRow != null
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.numbRow!)
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxExtend,
              ),
        itemCount: widget.data.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, indx) {
          var m = widget.data[indx];
          return CellImageWidget<T>(
            cell: m,
            hidealias: widget.hideAlias,
            indx: indx,
            onPressed: widget.onPressed,
            onLongPress: widget.onLongPress == null
                ? null
                : () async {
                    widget.onLongPress!(indx)
                        .onError((error, stackTrace) => null);
                  }, //extend: maxExtend,
          );
        },
      ),
    );
  }
}
