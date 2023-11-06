// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../pages/image_view.dart';

class WrapTheme extends StatelessWidget {
  final PaletteGenerator? currentPalette;
  final PaletteGenerator? previousPallete;
  final Widget child;
  final double animationValue;

  const WrapTheme(
      {super.key,
      required this.currentPalette,
      required this.previousPallete,
      required this.animationValue,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          hintColor: ColorTween(
            begin: previousPallete?.mutedColor?.bodyTextColor
                    .harmonizeWith(Theme.of(context).colorScheme.primary) ??
                kListTileColorInInfo,
            end: currentPalette?.mutedColor?.bodyTextColor
                    .harmonizeWith(Theme.of(context).colorScheme.primary) ??
                kListTileColorInInfo,
          ).transform(animationValue),
          drawerTheme: DrawerThemeData(
            backgroundColor: ColorTween(
                    begin: previousPallete?.mutedColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.85) ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    end: currentPalette?.mutedColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.85) ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.5))
                .transform(animationValue),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              color: currentPalette?.dominantColor?.bodyTextColor
                  .harmonizeWith(Theme.of(context).colorScheme.primary)
                  .withOpacity(0.8)),
          appBarTheme: AppBarTheme(
              foregroundColor: ColorTween(
                begin: previousPallete?.dominantColor?.bodyTextColor
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
                end: currentPalette?.dominantColor?.bodyTextColor
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
              ).transform(animationValue),
              backgroundColor: ColorTween(
                begin: previousPallete?.dominantColor?.color
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
                end: currentPalette?.dominantColor?.color
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
              ).transform(animationValue)),
          listTileTheme: ListTileThemeData(
            textColor: ColorTween(
                    begin: previousPallete?.dominantColor?.bodyTextColor
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.8) ??
                        kListTileColorInInfo,
                    end: currentPalette?.dominantColor?.bodyTextColor
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.8) ??
                        kListTileColorInInfo)
                .transform(animationValue),
          ),
          iconTheme: IconThemeData(
              color: ColorTween(
                      begin: previousPallete?.dominantColor?.bodyTextColor
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.8) ??
                          kListTileColorInInfo,
                      end: currentPalette?.dominantColor?.bodyTextColor
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.8) ??
                          kListTileColorInInfo)
                  .transform(animationValue)),
          bottomAppBarTheme: BottomAppBarTheme(
            color: ColorTween(
                    begin: previousPallete?.dominantColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.5) ??
                        Colors.black.withOpacity(0.5),
                    end: currentPalette?.dominantColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.5) ??
                        Colors.black.withOpacity(0.5))
                .transform(animationValue),
          )),
      child: child,
    );
  }
}
