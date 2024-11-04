// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/anime/anime_api.dart";
import "package:flutter/material.dart";

class AnimeInfoTheme extends StatelessWidget {
  const AnimeInfoTheme({
    super.key,
    required this.mode,
    required this.child,
  });
  final AnimeSafeMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (mode == AnimeSafeMode.safe) {
      return child;
    }

    final oldTheme = Theme.of(context);
    const Color bgColor = Color.fromARGB(255, 52, 26, 27);

    final newTheme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness:
            mode == AnimeSafeMode.h ? Brightness.dark : oldTheme.brightness,
        surface: mode == AnimeSafeMode.h ? bgColor : null,
      ),
    );

    return Theme(
      data: newTheme,
      child: _ButtonsThemes(
        mode: mode,
        child: child,
      ),
    );
  }
}

class _ButtonsThemes extends StatelessWidget {
  const _ButtonsThemes({
    required this.mode,
    required this.child,
  });
  final AnimeSafeMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: theme.colorScheme.surface,
        chipTheme: mode == AnimeSafeMode.h
            ? ChipThemeData(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                disabledColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              )
            : null,
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              theme.textTheme.bodyMedium,
            ),
            foregroundColor: WidgetStatePropertyAll(
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
