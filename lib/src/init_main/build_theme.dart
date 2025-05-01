// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:ui" as ui;

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

ThemeData buildTheme(
  Brightness brightness,
  Color accentColor,
) {
  final type = const SettingsService().current.themeType;
  final pageTransition = PageTransitionsTheme(
    builders: Map.from(const PageTransitionsTheme().builders)
      ..[TargetPlatform.android] = const PredictiveBackPageTransitionsBuilder()
      ..[TargetPlatform.linux] = const FadeForwardsPageTransitionsBuilder(),
  );

  const menuTheme = MenuThemeData(
    style: MenuStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
    ),
  );

  const popupMenuTheme = PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
  );

  var baseTheme = switch (type) {
    ThemeType.main => ThemeData(
        menuTheme: menuTheme,
        popupMenuTheme: popupMenuTheme,
        pageTransitionsTheme: pageTransition,
        useMaterial3: true,
        colorScheme: switch (brightness) {
          ui.Brightness.dark => MaterialTheme.darkScheme(),
          ui.Brightness.light => MaterialTheme.lightScheme(),
        },
      ),
    ThemeType.systemAccent => ThemeData(
        brightness: brightness,
        menuTheme: menuTheme,
        popupMenuTheme: popupMenuTheme,
        pageTransitionsTheme: pageTransition,
        useMaterial3: true,
        colorSchemeSeed: accentColor,
      ),
    ThemeType.pink => ThemeData(
        brightness: Brightness.dark,
        menuTheme: menuTheme,
        popupMenuTheme: popupMenuTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: pageTransition,
        useMaterial3: true,
      ),
  };

  final scrollBarTheme = ScrollbarThemeData(
    radius: const ui.Radius.circular(15),
    mainAxisMargin: 0.75,
    thumbColor: WidgetStatePropertyAll(
      baseTheme.colorScheme.onSurface.withValues(alpha: 0.75),
    ),
  );

  switch (type) {
    case ThemeType.systemAccent || ThemeType.main:
      baseTheme = baseTheme.copyWith(
        progressIndicatorTheme:
            baseTheme.progressIndicatorTheme.copyWith(year2023: false),
        scrollbarTheme: scrollBarTheme,
        listTileTheme: baseTheme.listTileTheme.copyWith(
          isThreeLine: false,
          subtitleTextStyle: baseTheme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
      );

    case ThemeType.pink:
      baseTheme = baseTheme.copyWith(
        sliderTheme: baseTheme.sliderTheme.copyWith(year2023: false),
        progressIndicatorTheme:
            baseTheme.progressIndicatorTheme.copyWith(year2023: false),
        scrollbarTheme: scrollBarTheme,
        scaffoldBackgroundColor: baseTheme.colorScheme.surface,
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              baseTheme.textTheme.bodyMedium,
            ),
            foregroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
  }

  return baseTheme;
}

SystemUiOverlayStyle navBarStyleForTheme(
  ThemeData theme, {
  bool transparent = true,
  bool highTone = true,
}) =>
    SystemUiOverlayStyle(
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: theme.brightness == ui.Brightness.dark
          ? ui.Brightness.light
          : ui.Brightness.dark,
      statusBarColor:
          (highTone ? theme.colorScheme.surfaceDim : theme.colorScheme.surface)
              .withValues(alpha: 0.8),
      systemNavigationBarIconBrightness: theme.brightness == ui.Brightness.dark
          ? ui.Brightness.light
          : ui.Brightness.dark,
      systemNavigationBarColor:
          (highTone ? theme.colorScheme.surfaceDim : theme.colorScheme.surface)
              .withValues(alpha: transparent ? 0.0 : 0.8),
    );
