// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cell/data.dart';

class GridCell<T extends CellData> extends StatefulWidget {
  final T _data;
  final int indx;
  final void Function(BuildContext context, int cellIndx) onPressed;
  final bool hideAlias;
  final bool tight;
  final Function()? onLongPress;

  const GridCell(
      {Key? key,
      required T cell,
      required this.indx,
      required this.onPressed,
      required this.tight,
      bool? hidealias,
      this.onLongPress})
      : _data = cell,
        hideAlias = hidealias ?? false,
        super(key: key);

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState<T extends CellData> extends State<GridCell<T>> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15.0),
      onTap: () {
        widget.onPressed(context, widget.indx);
      },
      focusColor: Theme.of(context).colorScheme.primary,
      onLongPress: widget.onLongPress,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Card(
              margin: widget.tight ? const EdgeInsets.all(0.5) : null,
              elevation: 0,
              child: ClipPath(
                clipper: ShapeBorderClipper(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0))),
                child: Stack(
                  children: [
                    if (widget.hideAlias)
                      Container(
                        decoration: const BoxDecoration(color: Colors.black45),
                      ),
                    Center(
                        child: Image(
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error_outline),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child.animate().fadeIn();
                        }

                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.cumulativeBytesLoaded
                                    .toDouble() /
                                loadingProgress.expectedTotalBytes!.toDouble(),
                          ),
                        );
                      },
                      image: widget._data.thumb,
                      alignment: Alignment.center,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    )),
                    if (!widget.hideAlias)
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
                        child: Padding(
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
              ));
        },
      ),
    );
  }
}
