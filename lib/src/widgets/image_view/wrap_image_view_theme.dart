// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'image_view.dart';

class WrapImageViewTheme extends StatefulWidget {
  final PaletteGenerator? currentPalette;
  final PaletteGenerator? previousPallete;
  final Widget child;

  const WrapImageViewTheme(
      {super.key,
      required this.currentPalette,
      required this.previousPallete,
      required this.child});

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
    return Theme(
      data: Theme.of(context).copyWith(
          hintColor: ColorTween(
            begin: widget.previousPallete?.mutedColor?.bodyTextColor
                    .harmonizeWith(Theme.of(context).colorScheme.primary) ??
                kListTileColorInInfo,
            end: widget.currentPalette?.mutedColor?.bodyTextColor
                    .harmonizeWith(Theme.of(context).colorScheme.primary) ??
                kListTileColorInInfo,
          ).transform(_animationController.value),
          drawerTheme: DrawerThemeData(
            backgroundColor: ColorTween(
                    begin: widget.previousPallete?.mutedColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.85) ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    end: widget.currentPalette?.mutedColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.85) ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.5))
                .transform(_animationController.value),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              color: widget.currentPalette?.dominantColor?.bodyTextColor
                  .harmonizeWith(Theme.of(context).colorScheme.primary)
                  .withOpacity(0.8)),
          appBarTheme: AppBarTheme(
              foregroundColor: ColorTween(
                begin: widget.previousPallete?.dominantColor?.bodyTextColor
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
                end: widget.currentPalette?.dominantColor?.bodyTextColor
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
              ).transform(_animationController.value),
              backgroundColor: ColorTween(
                begin: widget.previousPallete?.dominantColor?.color
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
                end: widget.currentPalette?.dominantColor?.color
                        .harmonizeWith(Theme.of(context).colorScheme.primary)
                        .withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
              ).transform(_animationController.value)),
          listTileTheme: ListTileThemeData(
            textColor: ColorTween(
                    begin: widget.previousPallete?.dominantColor?.bodyTextColor
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.8) ??
                        kListTileColorInInfo,
                    end: widget.currentPalette?.dominantColor?.bodyTextColor
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.8) ??
                        kListTileColorInInfo)
                .transform(_animationController.value),
          ),
          iconTheme: IconThemeData(
              color: ColorTween(
                      begin: widget
                              .previousPallete?.dominantColor?.bodyTextColor
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.8) ??
                          kListTileColorInInfo,
                      end: widget.currentPalette?.dominantColor?.bodyTextColor
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.8) ??
                          kListTileColorInInfo)
                  .transform(_animationController.value)),
          bottomAppBarTheme: BottomAppBarTheme(
            color: ColorTween(
                    begin: widget.previousPallete?.dominantColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.5) ??
                        Colors.black.withOpacity(0.5),
                    end: widget.currentPalette?.dominantColor?.color
                            .harmonizeWith(
                                Theme.of(context).colorScheme.primary)
                            .withOpacity(0.5) ??
                        Colors.black.withOpacity(0.5))
                .transform(_animationController.value),
          )),
      child: widget.child,
    );
  }
}
