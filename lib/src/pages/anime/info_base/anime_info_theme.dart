// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';

class AnimeInfoTheme extends StatelessWidget {
  final AnimeSafeMode mode;
  final Widget child;

  const AnimeInfoTheme({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == AnimeSafeMode.safe) {
      return child;
    }

    final oldTheme = Theme.of(context);
    Color bgColor = const Color.fromARGB(255, 52, 26, 27);

    final newTheme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness:
            mode == AnimeSafeMode.h ? Brightness.dark : oldTheme.brightness,
        background: mode == AnimeSafeMode.h ? bgColor : null,
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
  final AnimeSafeMode mode;
  final Widget child;

  const _ButtonsThemes({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: theme.colorScheme.background,
        chipTheme: mode == AnimeSafeMode.h
            ? ChipThemeData(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                disabledColor: theme.colorScheme.primary.withOpacity(0.4),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              )
            : null,
        filledButtonTheme: FilledButtonThemeData(
            style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(
              theme.colorScheme.onPrimary.withOpacity(0.8)),
          visualDensity: VisualDensity.compact,
          backgroundColor: MaterialStatePropertyAll(
            theme.colorScheme.primary.withOpacity(0.8),
          ),
        )),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
              textStyle: MaterialStatePropertyAll(
                theme.textTheme.bodyMedium,
              ),
              foregroundColor: MaterialStatePropertyAll(
                theme.colorScheme.primary.withOpacity(0.8),
              )),
        ),
      ),
      child: child,
    );
  }
}
