// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/init_main/build_theme.dart";
import "package:flutter/material.dart";

class ImageViewTheme extends StatefulWidget {
  const ImageViewTheme({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ImageViewTheme> createState() => ImageViewThemeState();
}

class ImageViewThemeState extends State<ImageViewTheme>
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

    // final tweenDominantColor = ColorTween(
    //   begin: widget.previousPallete?.dominantColor?.color
    //           .harmonizeWith(theme.colorScheme.primary) ??
    //       theme.colorScheme.primary,
    //   end: widget.currentPalette?.dominantColor?.color
    //           .harmonizeWith(theme.colorScheme.primary) ??
    //       theme.colorScheme.primary,
    // );

    // final colorScheme = ColorScheme.fromSeed(
    //   brightness: theme.brightness,
    //   seedColor: tweenDominantColor.lerp(_animationController.value)!,
    // );

    // final themeData = ThemeData.from(
    //   colorScheme: colorScheme,
    // );

    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: theme.colorScheme.surfaceDim.withValues(alpha: 0.95),
        ),
        bottomAppBarTheme: BottomAppBarTheme(
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.95),
        ),
        searchBarTheme: SearchBarThemeData(
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: AnnotatedRegion(
        value: navBarStyleForTheme(theme, transparent: false),
        child: widget.child,
      ),
    );
  }
}
