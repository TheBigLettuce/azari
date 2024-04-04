// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import '../../loading_error_widget.dart';
import '../../shimmer_loading_indicator.dart';
import '../grid_frame.dart';
import 'sticker_widget.dart';

/// The cell of [GridFrame].
class GridCell<T extends CellBase> extends StatefulWidget {
  final T _data;
  final int indx;

  final bool longTitle;
  final bool hideTitle;
  final bool animate;
  final bool blur;

  const GridCell({
    super.key,
    required T cell,
    required this.hideTitle,
    required this.indx,
    this.animate = false,
    this.longTitle = false,
    this.blur = false,
  }) : _data = cell;

  static GridCell<T> frameDefault<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required GridFrameState<T> state,
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
  }) {
    return GridCell(
      cell: cell,
      longTitle: isList,
      indx: idx,
      hideTitle: hideTitle,
      animate: animated,
      blur: blur,
    );
  }

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState<T extends CellBase> extends State<GridCell<T>> {
  int _tries = 0;

  Widget aliasWidget(
      BuildContext context, CellStaticData description, String alias) {
    return description.alignTitleToTopLeft
        ? topAlignAlias(context, description, alias)
        : Container(
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
                alias,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                maxLines: description.titleLines,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          );
  }

  Widget topAlignAlias(
      BuildContext context, CellStaticData description, String alias) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Colors.black.withOpacity(0.38),
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.05),
              Colors.black.withOpacity(0),
            ])),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 18),
          child: Text(
            alias,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxLines: description.titleLines,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget._data;
    final description = data.description();
    final alias = widget.hideTitle ? "" : data.alias(widget.longTitle);

    final stickers =
        data is Stickerable ? (data as Stickerable).stickers(context) : null;
    final thumbnail =
        data is Thumbnailable ? (data as Thumbnailable).thumbnail() : null;

    if (alias.isEmpty &&
        (stickers == null || stickers.isEmpty) &&
        thumbnail == null) {
      return const SizedBox.shrink();
    }

    final card = Card(
      margin: description.tightMode ? const EdgeInsets.all(0.5) : null,
      elevation: 0,
      color: Theme.of(context).cardColor.withOpacity(0),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: description.circle
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
        ),
        child: alias.isEmpty &&
                thumbnail == null &&
                (stickers == null || stickers.isEmpty)
            ? null
            : Stack(
                fit: StackFit.loose,
                children: [
                  if (thumbnail != null)
                    Center(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final blurSigma =
                            constraints.biggest.longestSide * 0.069;

                        final image = Image(
                          key: ValueKey((thumbnail.hashCode, _tries)),
                          errorBuilder: (context, error, stackTrace) =>
                              LoadingErrorWidget(
                            error: error.toString(),
                            refresh: () {
                              _tries += 1;

                              setState(() {});
                            },
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
                          image: thumbnail,
                          isAntiAlias: true,
                          alignment: description.imageAlign,
                          color: widget.blur
                              ? Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.2)
                              : null,
                          colorBlendMode:
                              widget.blur ? BlendMode.darken : BlendMode.darken,
                          fit: BoxFit.cover,
                          filterQuality: widget.blur
                              ? FilterQuality.none
                              : FilterQuality.medium,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        );

                        return widget.blur
                            ? ImageFiltered(
                                enabled: true,
                                imageFilter: ImageFilter.compose(
                                  outer: ImageFilter.blur(
                                    sigmaX: blurSigma,
                                    sigmaY: blurSigma,
                                    tileMode: TileMode.mirror,
                                  ),
                                  inner: ImageFilter.dilate(
                                      radiusX: 0.5, radiusY: 0.5),
                                ),
                                child: image,
                              )
                            : image;
                      }),
                    ),
                  if (stickers != null && stickers.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            direction: Axis.vertical,
                            children:
                                stickers.map((e) => StickerWidget(e)).toList(),
                          )),
                    ),
                  ],
                  if (alias.isNotEmpty && !description.titleAtBottom)
                    aliasWidget(
                      context,
                      description,
                      alias,
                    ),
                ],
              ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 2,
          child: widget.animate
              ? card.animate(key: widget._data.uniqueKey()).fadeIn()
              : card,
        ),
        if (description.titleAtBottom && alias.isNotEmpty)
          Expanded(
            flex: 1,
            child: Padding(
              padding: description.tightMode
                  ? const EdgeInsets.only(left: 0.5, right: 0.5)
                  : const EdgeInsets.only(right: 4, left: 4),
              child: Text(
                alias,
                maxLines: description.titleLines,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          )
      ],
    );
  }
}

class CustomGridCellWrapper extends StatelessWidget {
  final void Function(BuildContext) onPressed;
  final void Function(BuildContext)? onLongPress;
  final Widget child;

  const CustomGridCellWrapper({
    super.key,
    this.onLongPress,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onLongPress: onLongPress == null
          ? null
          : () {
              onLongPress!(context);
            },
      onTap: () {
        onPressed(context);
      },
      child: child,
    );
  }
}
