// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
import "package:flutter/material.dart";

class ShimmerPlaceholdersChips extends StatelessWidget {
  const ShimmerPlaceholdersChips({
    super.key,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
  });

  final EdgeInsets childPadding;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: padding,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return SizedBox(
          key: ValueKey(index),
          height: 42,
          child: Padding(
            padding: childPadding,
            child: const ActionChip(
              labelPadding: EdgeInsets.zero,
              // padding: EdgeInsets.zero,
              label: SizedBox(
                height: 42 / 2,
                width: 58,
                child: ShimmerLoadingIndicator(
                  delay: Duration(milliseconds: 900),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerPlaceholderCarousel extends StatelessWidget {
  const ShimmerPlaceholderCarousel({
    super.key,
    required this.childSize,
    this.cornerRadius = 15,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
    this.weights = const [3, 2, 1],
  });

  final Size childSize;
  final double cornerRadius;
  final EdgeInsets childPadding;
  final EdgeInsets padding;

  final List<int> weights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: childSize.height,
      child: Padding(
        padding: padding,
        child: CarouselView.weighted(
          padding: childPadding,
          flexWeights: weights,
          itemSnapping: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          children: List<Widget>.generate(10, (index) {
            return ShimmerLoadingIndicator(
              key: ValueKey(index),
              delay: const Duration(milliseconds: 900),
            );
          }),
        ),
      ),
    );
  }
}

class ShimmerPlaceholdersHorizontal extends StatefulWidget {
  const ShimmerPlaceholdersHorizontal({
    super.key,
    required this.childSize,
    this.cornerRadius = 15,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
  });

  final Size childSize;
  final double cornerRadius;
  final EdgeInsets childPadding;
  final EdgeInsets padding;

  @override
  State<ShimmerPlaceholdersHorizontal> createState() =>
      _ShimmerPlaceholdersHorizontalState();
}

class _ShimmerPlaceholdersHorizontalState
    extends State<ShimmerPlaceholdersHorizontal> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.childSize.height,
      child: ListView.builder(
        itemCount: 10,
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return SizedBox(
            key: ValueKey(index),
            width: widget.childSize.width,
            child: Padding(
              padding: widget.childPadding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.cornerRadius),
                child: const ShimmerLoadingIndicator(
                  delay: Duration(milliseconds: 900),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
