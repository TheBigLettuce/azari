// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../image_view.dart';

class WrapImageViewTheme extends StatefulWidget {
  final PaletteGenerator? currentPalette;
  final PaletteGenerator? previousPallete;
  final Widget child;

  const WrapImageViewTheme({
    super.key,
    required this.currentPalette,
    required this.previousPallete,
    required this.child,
  });

  @override
  State<WrapImageViewTheme> createState() => WrapImageViewThemeState();
}

class WrapImageViewThemeState extends State<WrapImageViewTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));

  void resetAnimation() {
    _animationController.reset();
    _animationController.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();

    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tweenMutedTextColor = ColorTween(
      begin: widget.previousPallete?.mutedColor?.bodyTextColor
              .harmonizeWith(theme.colorScheme.primary) ??
          kListTileColorInInfo,
      end: widget.currentPalette?.mutedColor?.bodyTextColor
              .harmonizeWith(theme.colorScheme.primary) ??
          kListTileColorInInfo,
    );

    final tweenMutedColor = ColorTween(
      begin: widget.previousPallete?.mutedColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          theme.colorScheme.surface,
      end: widget.currentPalette?.mutedColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          theme.colorScheme.surface,
    );

    final tweenDominantTextColor = ColorTween(
      begin: widget.previousPallete?.dominantColor?.bodyTextColor
              .harmonizeWith(theme.colorScheme.primary) ??
          kListTileColorInInfo,
      end: widget.currentPalette?.dominantColor?.bodyTextColor
              .harmonizeWith(theme.colorScheme.primary) ??
          kListTileColorInInfo,
    );

    final tweenDominantColor = ColorTween(
      begin: widget.previousPallete?.dominantColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          Colors.black,
      end: widget.currentPalette?.dominantColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          Colors.black,
    );

    return Theme(
      data: theme.copyWith(
          hintColor: tweenMutedTextColor.transform(_animationController.value),
          drawerTheme: DrawerThemeData(
            backgroundColor: tweenMutedColor
                .transform(_animationController.value)
                ?.withOpacity(0.85),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              color: widget.currentPalette?.dominantColor?.bodyTextColor
                  .harmonizeWith(theme.colorScheme.primary)
                  .withOpacity(0.8)),
          appBarTheme: AppBarTheme(
            foregroundColor: tweenDominantTextColor
                .transform(_animationController.value)
                ?.withOpacity(0.8),
            backgroundColor: tweenDominantColor
                .transform(_animationController.value)
                ?.withOpacity(0.5),
          ),
          listTileTheme: ListTileThemeData(
            textColor: tweenMutedTextColor
                .transform(_animationController.value)
                ?.withOpacity(0.8),
            iconColor: tweenMutedTextColor
                .transform(_animationController.value)
                ?.withOpacity(0.8),
          ),
          filledButtonTheme: FilledButtonThemeData(
              style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(
              tweenDominantTextColor
                  .transform(_animationController.value)
                  ?.withOpacity(0.8),
            ),
            backgroundColor: MaterialStatePropertyAll(
              tweenDominantColor.transform(_animationController.value),
            ),
          )),
          dividerTheme: DividerThemeData(
              color: tweenMutedTextColor
                  .transform(_animationController.value)
                  ?.withOpacity(0.2)),
          iconTheme: IconThemeData(
            color: tweenMutedTextColor
                .transform(_animationController.value)
                ?.withOpacity(0.8),
          ),
          bottomAppBarTheme: BottomAppBarTheme(
            color: tweenDominantColor
                .transform(_animationController.value)
                ?.withOpacity(0.5),
          )),
      child: widget.child,
    );
  }
}
