// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:transparent_image/transparent_image.dart';
import '../loading_error_widget.dart';
import 'cell_data.dart';
import 'callback_grid.dart';
import 'sticker.dart';

/// The cell of [CallbackGrid].
class GridCell<T extends CellData> extends StatefulWidget {
  final T _data;
  final int indx;
  final void Function(BuildContext context)? onPressed;
  final bool hideAlias;

  /// If [tight] is true, margin between the [GridCell]s on the grid is tight.
  final bool tight;
  final void Function()? onLongPress;
  final Future Function(int)? download;

  /// If [shadowOnTop] is true, then on top of the [GridCell] painted [Colors.black],
  /// with 0.5 opacity.
  final bool shadowOnTop;

  /// [GridCell] is displayed in form as a beveled rectangle.
  /// If [circle] is true, then it's displayed as a circle instead.
  final bool circle;

  /// If [ignoreStickers] is true, then stickers aren't displayed on top of the cell.
  final bool ignoreStickers;

  const GridCell(
      {super.key,
      required T cell,
      required this.indx,
      required this.onPressed,
      required this.tight,
      required this.download,
      bool? hidealias,
      this.shadowOnTop = false,
      this.circle = false,
      this.ignoreStickers = false,
      this.onLongPress})
      : _data = cell,
        hideAlias = hidealias ?? false;

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState<T extends CellData> extends State<GridCell<T>> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15.0),
      onTap: widget.onPressed == null
          ? null
          : () {
              widget.onPressed!(context);
            },
      focusColor: Theme.of(context).colorScheme.primary,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.download != null
          ? () {
              HapticFeedback.selectionClick();
              widget.download!(widget.indx);
            }
          : null,
      child: Card(
          margin: widget.tight ? const EdgeInsets.all(0.5) : null,
          elevation: 0,
          color: Theme.of(context).cardColor.withOpacity(0),
          child: ClipPath(
            clipper: ShapeBorderClipper(
                shape: widget.circle
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0))),
            child: Stack(
              children: [
                Center(child: LayoutBuilder(builder: (context, constraints) {
                  return Image(
                    errorBuilder: (context, error, stackTrace) =>
                        LoadingErrorWidget(
                      error: error,
                    ),
                    frameBuilder: (
                      context,
                      child,
                      frame,
                      wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }

                      return frame == null
                          ? const ShimmerLoadingIndicator()
                          : child.animate().fadeIn();
                    },
                    image: widget._data.thumb ?? MemoryImage(kTransparentImage),
                    alignment: Alignment.center,
                    color: widget.shadowOnTop
                        ? Colors.black.withOpacity(0.5)
                        : null,
                    colorBlendMode: BlendMode.darken,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  );
                })),
                if (widget._data.stickers.isNotEmpty &&
                    !widget.ignoreStickers) ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          direction: Axis.vertical,
                          children: widget._data.stickers
                              .where((element) => element.right)
                              .map((e) => StickerWidget(e))
                              .toList(),
                        )),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        direction: Axis.vertical,
                        children: widget._data.stickers
                            .where((element) => !element.right)
                            .map((e) => StickerWidget(e))
                            .toList(),
                      ))
                ],
                if (!widget.hideAlias && !widget.shadowOnTop)
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
                          maxLines: 1,
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                        )),
                  ),
              ],
            ),
          )),
    );
  }
}

class ShimmerLoadingIndicator extends StatelessWidget {
  const ShimmerLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Animate(
      onComplete: (controller) => controller.repeat(),
      effects: [
        ShimmerEffect(
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            delay: const Duration(seconds: 2),
            duration: const Duration(milliseconds: 500))
      ],
      child: Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)),
    );
  }
}
