// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:ui";

import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/loading_error_widget.dart";
import "package:azari/src/ui/material/widgets/shell/parts/sticker_widget.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
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
    required Widget Function(Widget child) wrapSelection,
  }) =>
      wrapSelection(
        GridCell(
          data: cell,
          longTitle: isList,
          hideTitle: hideTitle,
          animate: animated,
          blur: blur,
          imageAlign: imageAlign,
        ),
      );
}

class GridCellName extends StatelessWidget {
  const GridCellName({
    // super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
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
            title,
            softWrap: false,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            maxLines: lines,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAlias extends StatelessWidget {
  const _TopAlias({
    // super.key,
    required this.title,
    required this.secondaryTitle,
    required this.lines,
  });

  final String title;
  final String? secondaryTitle;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            secondaryTitle ?? title,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxLines: secondaryTitle != null ? 1 : lines,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

class GridCellImage extends StatefulWidget {
  const GridCellImage({
    super.key,
    required this.blur,
    required this.imageAlign,
    required this.thumbnail,
    this.boxFit = BoxFit.cover,
    this.heroTag,
    this.backgroundColor,
  });

  final bool blur;

  final BoxFit boxFit;
  final Alignment imageAlign;

  final ImageProvider<Object> thumbnail;

  final Color? backgroundColor;
  final Object? heroTag;

  @override
  State<GridCellImage> createState() => _GridCellImageState();
}

class _GridCellImageState extends State<GridCellImage> {
  int _tries = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final blurSigma = constraints.biggest.longestSide * 0.069;

          final image = DecoratedBox(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
            ),
            child: Image(
              key: ValueKey((widget.thumbnail.hashCode, _tries)),
              errorBuilder: (context, error, stackTrace) => LoadingErrorWidget(
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
              image: widget.thumbnail,
              isAntiAlias: true,
              alignment: widget.imageAlign,
              color: widget.blur
                  ? theme.colorScheme.surface.withValues(alpha: 0.2)
                  : null,
              colorBlendMode: widget.blur ? BlendMode.darken : BlendMode.darken,
              fit: widget.boxFit,
              filterQuality:
                  widget.blur ? FilterQuality.none : FilterQuality.medium,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
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
    );

    if (widget.heroTag != null) {
      child = Hero(
        tag: widget.heroTag!,
        child: child,
      );
    }

    return Center(child: child);
  }
}

/// The cell of [ShellElement].
class GridCell extends StatelessWidget {
  const GridCell({
    super.key,
    required this.data,
    this.secondaryTitle,
    required this.hideTitle,
    this.overrideDescription,
    this.animate = false,
    this.longTitle = false,
    this.blur = false,
    this.imageAlign = Alignment.center,
  });

  final CellBase data;

  final bool longTitle;
  final bool hideTitle;
  final bool animate;
  final bool blur;

  final Alignment imageAlign;

  final String? secondaryTitle;

  final CellStaticData? overrideDescription;

  @override
  Widget build(BuildContext context) {
    final description = overrideDescription ?? data.description();
    final alias = hideTitle ? "" : data.alias(longTitle);

    final stickers = description.ignoreStickers
        ? null
        : data.tryAsStickerable(context, false);
    final thumbnail = data.tryAsThumbnailable(context);

    if (alias.isEmpty &&
        (stickers == null || stickers.isEmpty) &&
        thumbnail == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    Widget card = Card(
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
                    GridCellImage(
                      imageAlign: imageAlign,
                      thumbnail: thumbnail,
                      blur: blur,
                    ),
                  if (stickers != null && stickers.isNotEmpty)
                    Align(
                      alignment: description.alignStickersTopCenter
                          ? Alignment.topLeft
                          : Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          textDirection: description.alignStickersTopCenter
                              ? null
                              : TextDirection.rtl,
                          spacing: 2,
                          runSpacing: 2,
                          crossAxisAlignment: description.alignStickersTopCenter
                              ? WrapCrossAlignment.center
                              : WrapCrossAlignment.start,
                          direction: description.alignStickersTopCenter
                              ? Axis.horizontal
                              : Axis.vertical,
                          children: stickers.map(StickerWidget.new).toList(),
                        ),
                      ),
                    ),
                  if ((alias.isNotEmpty && !description.titleAtBottom) ||
                      secondaryTitle != null)
                    description.alignTitleToTopLeft
                        ? _TopAlias(
                            title: alias,
                            secondaryTitle: secondaryTitle,
                            lines: description.titleLines,
                          )
                        : GridCellName(
                            title: alias,
                            lines: description.titleLines,
                          ),
                ],
              ),
      ),
    );
    if (animate) {
      card = card.animate(key: data.uniqueKey()).fadeIn();
    }

    if (!description.titleAtBottom || alias.isEmpty) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 2,
          child: card,
        ),
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

  final ContextCallback onPressed;
  final ContextCallback? onLongPress;

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
