// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:ui";

import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/sticker_widget.dart";
import "package:azari/src/widgets/loading_error_widget.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

mixin DefaultBuildCellImpl implements CellBase {
  @override
  Widget buildCell<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
    required Alignment imageAlign,
  }) =>
      GridCell(
        cell: cell,
        longTitle: isList,
        hideTitle: hideTitle,
        animate: animated,
        blur: blur,
        imageAlign: imageAlign,
      );
}

/// The cell of [GridFrame].
class GridCell<T extends CellBase> extends StatefulWidget {
  const GridCell({
    super.key,
    required T cell,
    this.secondaryTitle,
    required this.hideTitle,
    this.overrideDescription,
    this.animate = false,
    this.longTitle = false,
    this.blur = false,
    this.imageAlign = Alignment.center,
  }) : _data = cell;

  // factory GridCell.frameDefault(
  //   BuildContext _,
  //   int __,
  //   T cell, {
  //   required bool isList,
  //   required bool hideTitle,
  //   bool animated = false,
  //   bool blur = false,
  //   required Alignment imageAlign,
  // }) {
  //   return GridCell(
  //     cell: cell,
  //     longTitle: isList,
  //     hideTitle: hideTitle,
  //     animate: animated,
  //     blur: blur,
  //     imageAlign: imageAlign,
  //   );
  // }

  final T _data;

  final bool longTitle;
  final bool hideTitle;
  final bool animate;
  final bool blur;
  final Alignment imageAlign;

  final String? secondaryTitle;

  final CellStaticData? overrideDescription;

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState<T extends CellBase> extends State<GridCell<T>> {
  int _tries = 0;

  Widget aliasWidget(
    BuildContext context,
    CellStaticData description,
    String alias,
    ThemeData theme,
  ) {
    return description.alignTitleToTopLeft
        ? topAlignAlias(context, description, alias, theme)
        : Container(
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(50),
                  Colors.black12,
                  Colors.black45,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                alias,
                softWrap: false,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: description.titleLines,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
  }

  Widget topAlignAlias(
    BuildContext context,
    CellStaticData description,
    String alias,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.38),
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 18),
          child: Text(
            widget.secondaryTitle ?? alias,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxLines:
                widget.secondaryTitle != null ? 1 : description.titleLines,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget._data;
    final description = widget.overrideDescription ?? data.description();
    final alias = widget.hideTitle ? "" : data.alias(widget.longTitle);

    final stickers = description.ignoreStickers
        ? null
        : data.tryAsStickerable(context, false);
    final thumbnail = data.tryAsThumbnailable();

    if (alias.isEmpty &&
        (stickers == null || stickers.isEmpty) &&
        thumbnail == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final card = Card(
      margin: description.tightMode ? const EdgeInsets.all(0.5) : null,
      elevation: 0,
      color: theme.cardColor.withValues(alpha: 0),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: description.circle
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
        ),
        child: alias.isEmpty &&
                thumbnail == null &&
                (stickers == null || stickers.isEmpty)
            ? null
            : Stack(
                children: [
                  if (thumbnail != null)
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
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
                            alignment: widget.imageAlign,
                            color: widget.blur
                                ? theme.colorScheme.surface
                                    .withValues(alpha: 0.2)
                                : null,
                            colorBlendMode: widget.blur
                                ? BlendMode.darken
                                : BlendMode.darken,
                            fit: BoxFit.cover,
                            filterQuality: widget.blur
                                ? FilterQuality.none
                                : FilterQuality.medium,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          );

                          return widget.blur
                              ? ImageFiltered(
                                  imageFilter: ImageFilter.compose(
                                    outer: ImageFilter.blur(
                                      sigmaX: blurSigma,
                                      sigmaY: blurSigma,
                                      tileMode: TileMode.mirror,
                                    ),
                                    inner: ImageFilter.dilate(
                                      radiusX: 0.5,
                                      radiusY: 0.5,
                                    ),
                                  ),
                                  child: image,
                                )
                              : image;
                        },
                      ),
                    ),
                  if (stickers != null && stickers.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          direction: Axis.vertical,
                          children:
                              stickers.map((e) => StickerWidget(e)).toList(),
                        ),
                      ),
                    ),
                  ],
                  if ((alias.isNotEmpty && !description.titleAtBottom) ||
                      widget.secondaryTitle != null)
                    aliasWidget(
                      context,
                      description,
                      alias,
                      theme,
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
            child: Padding(
              padding: description.tightMode
                  ? const EdgeInsets.only(left: 0.5, right: 0.5)
                  : const EdgeInsets.only(right: 4, left: 4),
              child: Text(
                alias,
                maxLines: description.titleLines,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GridCellPlaceholder extends StatelessWidget {
  const GridCellPlaceholder({
    super.key,
    required this.description,
  });

  final CellStaticData description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: description.tightMode
          ? const EdgeInsets.all(0.5)
          : const EdgeInsets.all(4),
      child: description.circle
          ? const ClipPath(
              clipper: ShapeBorderClipper(shape: CircleBorder()),
              child: ShimmerLoadingIndicator(reverse: true),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: const ShimmerLoadingIndicator(reverse: true),
            ),
    );
  }
}

class CustomGridCellWrapper extends StatelessWidget {
  const CustomGridCellWrapper({
    super.key,
    this.onLongPress,
    required this.onPressed,
    required this.child,
  });
  final void Function(BuildContext) onPressed;
  final void Function(BuildContext)? onLongPress;
  final Widget child;

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
