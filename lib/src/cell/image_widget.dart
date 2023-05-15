import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

import 'cell.dart';
import 'data.dart';

class CellImageWidget<T extends Cell> extends StatefulWidget {
  final T _data;
  final int indx;
  final void Function(BuildContext context, int cellIndx) onPressed;
  final bool hideAlias;
  final Function()? onLongPress;

  const CellImageWidget(
      {Key? key,
      required T cell,
      required this.indx,
      required this.onPressed,
      bool? hidealias,
      this.onLongPress})
      : _data = cell,
        hideAlias = hidealias ?? false,
        super(key: key);

  @override
  State<CellImageWidget> createState() => _CellImageWidgetState();
}

class _CellImageWidgetState<T extends Cell> extends State<CellImageWidget<T>> {
  late CellData cellData = widget._data.getCellData();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.indigo,
      hoverColor: Colors.indigoAccent,
      borderRadius: BorderRadius.circular(15.0),
      onTap: () {
        widget.onPressed(context, widget.indx);
      },
      onLongPress: widget.onLongPress,
      child: Card(
          elevation: 0,
          child: ClipPath(
            clipper: ShapeBorderClipper(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0))),
            child: Stack(
              children: [
                LayoutBuilder(builder: (context, constraint) {
                  return Center(
                      child: OctoImage(
                    fadeOutDuration: const Duration(milliseconds: 1000),
                    fadeInDuration: const Duration(milliseconds: 500),
                    fadeInCurve: Curves.easeIn,
                    fadeOutCurve: Curves.easeOut,
                    image: cellData.thumb(),
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    width: constraint.maxWidth,
                    height: constraint.maxHeight,
                  ));
                }),
                Container(
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.black.withAlpha(50),
                        Colors.black12,
                        Colors.black45
                      ])),
                  child: widget.hideAlias
                      ? null
                      : Text(
                          cellData.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          )),
    );
  }
}
