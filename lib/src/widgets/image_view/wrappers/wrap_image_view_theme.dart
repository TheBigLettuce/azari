// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:gallery/main.dart";
import "package:palette_generator/palette_generator.dart";

class WrapImageViewTheme extends StatefulWidget {
  const WrapImageViewTheme({
    super.key,
    required this.currentPalette,
    required this.previousPallete,
    required this.child,
  });

  final PaletteGenerator? currentPalette;
  final PaletteGenerator? previousPallete;
  final Widget child;

  @override
  State<WrapImageViewTheme> createState() => WrapImageViewThemeState();
}

class WrapImageViewThemeState extends State<WrapImageViewTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

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

    final tweenDominantColor = ColorTween(
      begin: widget.previousPallete?.dominantColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          theme.colorScheme.primary,
      end: widget.currentPalette?.dominantColor?.color
              .harmonizeWith(theme.colorScheme.primary) ??
          theme.colorScheme.primary,
    );

    final colorScheme = ColorScheme.fromSeed(
      brightness: theme.brightness,
      seedColor: tweenDominantColor.lerp(_animationController.value)!,
    );

    final themeData = ThemeData.from(
      colorScheme: colorScheme,
    );

    return Theme(
      data: themeData.copyWith(
        appBarTheme: themeData.appBarTheme.copyWith(
          backgroundColor: colorScheme.surfaceDim.withOpacity(0.95),
        ),
        bottomAppBarTheme: BottomAppBarTheme(
          color: colorScheme.surfaceContainer.withOpacity(0.95),
        ),
        searchBarTheme: SearchBarThemeData(
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest.withOpacity(0.8),
          ),
        ),
      ),
      child: AnnotatedRegion(
        value: navBarStyleForTheme(themeData, transparent: false),
        child: widget.child,
      ),
    );
  }
}
