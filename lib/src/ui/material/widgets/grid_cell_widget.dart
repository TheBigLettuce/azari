// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:ui";

import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/parts/sticker_widget.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

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
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
            decoration: BoxDecoration(color: widget.backgroundColor),
            child: Image(
              key: ValueKey((widget.thumbnail.hashCode, _tries)),
              errorBuilder: (context, error, stackTrace) => LoadingErrorWidget(
                error: error.toString(),
                refresh: () {
                  _tries += 1;

                  setState(() {});
                },
              ),
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
              filterQuality: widget.blur
                  ? FilterQuality.none
                  : FilterQuality.medium,
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
                    inner: ImageFilter.dilate(radiusX: 0.5, radiusY: 0.5),
                  ),
                  child: image,
                )
              : image;
        },
      ),
    );

    if (widget.heroTag != null) {
      child = Hero(tag: widget.heroTag!, child: child);
    }

    return Center(child: child);
  }
}

enum TitleMode { normal, long, topLeft, atBottom }

/// The cell of [ShellElement].
class GridCell extends StatelessWidget {
  const GridCell({
    super.key,
    required this.uniqueKey,
    required this.title,
    required this.thumbnail,
    this.subtitle,
    this.titleMode = TitleMode.normal,
    this.blur = false,
    this.imageAlign = Alignment.center,
    this.stickers = const [],
    this.tightMode = false,
    this.titleLines = 1,
    this.circle = false,
  });

  final Key uniqueKey;

  final ImageProvider? thumbnail;

  final int titleLines;

  final bool tightMode;
  final bool blur;
  final bool circle;

  final Alignment imageAlign;
  final TitleMode titleMode;

  final String? title;
  final String? subtitle;
  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context) {
    final animate = PlayAnimations.maybeOf(context) ?? false;

    final theme = Theme.of(context);

    Widget card = Card(
      margin: tightMode ? const EdgeInsets.all(0.5) : null,
      elevation: 0,
      color: theme.cardColor.withValues(alpha: 0),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: circle
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Stack(
          children: [
            if (thumbnail != null)
              GridCellImage(
                imageAlign: imageAlign,
                thumbnail: thumbnail!,
                blur: blur,
              ),
            if (stickers.isNotEmpty)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 2,
                    runSpacing: 2,
                    direction: Axis.vertical,
                    children: stickers.map(StickerWidget.new).toList(),
                  ),
                ),
              ),
            if ((title == null ||
                    title!.isNotEmpty && !(titleMode == TitleMode.atBottom)) ||
                subtitle != null)
              titleMode == TitleMode.topLeft
                  ? _TopAlias(
                      title: title ?? "",
                      secondaryTitle: subtitle,
                      lines: titleLines,
                    )
                  : GridCellName(title: title ?? "", lines: titleLines),
          ],
        ),
      ),
    );
    if (animate) {
      card = card.animate(key: uniqueKey).fadeIn();
    }

    if (!(titleMode == TitleMode.atBottom) || title == null || title!.isEmpty) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(flex: 2, child: card),
        Expanded(
          child: Padding(
            padding: tightMode
                ? const EdgeInsets.only(left: 0.5, right: 0.5)
                : const EdgeInsets.only(right: 4, left: 4),
            child: Text(
              title ?? "",
              maxLines: titleLines,
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
    required this.circle,
    required this.tightMode,
  });

  final bool circle;
  final bool tightMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: tightMode ? const EdgeInsets.all(0.5) : const EdgeInsets.all(4),
      child: circle
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

class LoadingErrorWidget extends StatefulWidget {
  const LoadingErrorWidget({
    super.key,
    required this.error,
    required this.refresh,
    this.short = true,
  });

  final bool short;

  final String error;

  final VoidCallback refresh;

  @override
  State<LoadingErrorWidget> createState() => _LoadingErrorWidgetState();
}

class _LoadingErrorWidgetState extends State<LoadingErrorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.short) {
      return GestureDetector(
        onTap: () {
          controller.forward().then((value) => widget.refresh());
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.2,
            ),
          ),
          child: SizedBox.expand(
            child: Center(
              child: Animate(
                autoPlay: false,
                effects: [
                  FadeEffect(
                    duration: 200.ms,
                    curve: Easing.standard,
                    begin: 1,
                    end: 0,
                  ),
                  RotateEffect(duration: 200.ms, curve: Easing.standard),
                ],
                controller: controller,
                child: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      child: Center(
        child: InkWell(
          onTap: widget.refresh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(padding: EdgeInsets.only(top: 20)),
              Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 4),
                child: Text(
                  widget.error,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    overflow: TextOverflow.ellipsis,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
