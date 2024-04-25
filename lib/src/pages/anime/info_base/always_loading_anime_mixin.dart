// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/widgets/empty_widget.dart";

class WrapFutureRestartable<T> extends StatefulWidget {
  const WrapFutureRestartable({
    super.key,
    required this.builder,
    required this.newStatus,
    this.bottomSheetVariant = false,
  });
  final Future<T> Function() newStatus;
  final Widget Function(BuildContext context, T value) builder;
  final bool bottomSheetVariant;

  @override
  State<WrapFutureRestartable<T>> createState() =>
      _WrapFutureRestartableState<T>();
}

class _WrapFutureRestartableState<T> extends State<WrapFutureRestartable<T>> {
  late Future<T> f;
  int count = 0;

  @override
  void initState() {
    super.initState();

    f = widget.newStatus();
  }

  @override
  void dispose() {
    f.ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bottomSheetVariant) {
      return FutureBuilder(
        key: ValueKey(count),
        future: f,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const SizedBox(
              width: double.infinity,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyWidget(
                  gridSeed: 0,
                  error: EmptyWidget.unwrapDioError(snapshot.error),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 8)),
                FilledButton(
                  onPressed: () {
                    f = widget.newStatus();
                    count += 1;

                    setState(() {});
                  },
                  child: Text(AppLocalizations.of(context)!.tryAgain),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 8)),
              ],
            );
          } else {
            return widget
                .builder(context, snapshot.data as T)
                .animate()
                .fadeIn();
          }
        },
      );
    }

    return FutureBuilder(
      key: ValueKey(count),
      future: f,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return AnnotatedRegion(
            value: navBarStyleForTheme(Theme.of(context), elevation: false),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return AnnotatedRegion(
            value: navBarStyleForTheme(Theme.of(context)),
            child: Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  children: [
                    EmptyWidget(
                      gridSeed: 0,
                      error: EmptyWidget.unwrapDioError(snapshot.error),
                    ),
                    const Padding(padding: EdgeInsets.only(bottom: 8)),
                    FilledButton(
                      onPressed: () {
                        f = widget.newStatus();
                        count += 1;

                        setState(() {});
                      },
                      child: Text(AppLocalizations.of(context)!.tryAgain),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return DecoratedBox(
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.background),
            child:
                widget.builder(context, snapshot.data as T).animate().fadeIn(),
          );
        }
      },
    );
  }
}
