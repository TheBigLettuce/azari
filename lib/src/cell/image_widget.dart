// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'data.dart';

class CellImageWidget<T extends CellData> extends StatefulWidget {
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

class _CellImageWidgetState<T extends CellData>
    extends State<CellImageWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                      child: Image(
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child.animate().fadeIn();
                      }

                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes!
                                  .toDouble() /
                              loadingProgress.cumulativeBytesLoaded.toDouble(),
                        ),
                      );
                    },
                    image: widget._data.thumb(),
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
                      : Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            widget._data.name,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                          )),
                ),
              ],
            ),
          )),
    );
  }
}
/* */