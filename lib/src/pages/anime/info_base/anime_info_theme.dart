// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';

class AnimeInfoTheme extends StatelessWidget {
  final AnimeSafeMode mode;
  final Color? overlayColor;
  final Widget child;

  const AnimeInfoTheme({
    super.key,
    required this.mode,
    required this.overlayColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color.fromARGB(255, 52, 26, 27);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: mode == AnimeSafeMode.h || mode == AnimeSafeMode.ecchi
            ? ColorScheme.fromSeed(
                seedColor: Colors.pink,
                brightness: Brightness.dark,
                background: mode == AnimeSafeMode.h ? bgColor : null,
              )
            : null,
      ),
      child: _ButtonsThemes(
        mode: mode,
        child: _RestoreSysOvColor(
          color: overlayColor,
          child: child,
        ),
      ),
    );
  }
}

class _ButtonsThemes extends StatelessWidget {
  final AnimeSafeMode mode;
  // final AnimeEntry entry;
  final Widget child;

  const _ButtonsThemes({
    super.key,
    required this.mode,
    // required this.entry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Theme.of(context).colorScheme.background,
        chipTheme: mode == AnimeSafeMode.h
            ? ChipThemeData(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                disabledColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.4),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.8),
                    ),
              )
            : null,
        filledButtonTheme: FilledButtonThemeData(
            style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(
              Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)),
          visualDensity: VisualDensity.compact,
          backgroundColor: MaterialStatePropertyAll(
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
        )),
        // buttonTheme: const ButtonThemeData(),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
              textStyle: MaterialStatePropertyAll(
                Theme.of(context).textTheme.bodyMedium,
              ),
              foregroundColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              )),
        ),
      ),
      child: child,
    );
  }
}

class _RestoreSysOvColor extends StatefulWidget {
  final Color? color;
  final Widget child;

  const _RestoreSysOvColor({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  State<_RestoreSysOvColor> createState() => __RestoreSysOvColorState();
}

class __RestoreSysOvColorState extends State<_RestoreSysOvColor> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(null, widget.color);
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
