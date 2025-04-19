// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class _DefaultOnError extends StatelessWidget {
  const _DefaultOnError({
    super.key,
    required this.refresh,
    required this.error,
  });

  final VoidCallback refresh;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyWidget(
          gridSeed: 0,
          error: EmptyWidget.unwrapDioError(error),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 8)),
        FilledButton(
          onPressed: refresh,
          child: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

class WrapFutureRestartable<T> extends StatefulWidget {
  const WrapFutureRestartable({
    super.key,
    required this.newStatus,
    required this.builder,
    this.bottomSheetVariant = false,
    this.placeholder,
    this.errorBuilder = defaultError,
  });

  final Future<T> Function() newStatus;
  final Widget Function(BuildContext context, T value) builder;
  final Widget? placeholder;
  final bool bottomSheetVariant;

  final Widget Function(Object error, VoidCallback refresh) errorBuilder;

  static Widget defaultError(Object error, VoidCallback refresh) =>
      _DefaultOnError(error: error, refresh: refresh);

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

  void refresh() {
    f = widget.newStatus();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.bottomSheetVariant) {
      return AnimatedSize(
        duration: Durations.long3,
        curve: Easing.standard,
        child: FutureBuilder(
          key: ValueKey(count),
          future: f,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return widget.placeholder ??
                  const SizedBox(
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
              return widget.errorBuilder(snapshot.error!, refresh);
            } else {
              return widget
                  .builder(context, snapshot.data as T)
                  .animate()
                  .fadeIn();
            }
          },
        ),
      );
    }

    return AnimatedSize(
      duration: Durations.long3,
      curve: Easing.standard,
      child: FutureBuilder(
        key: ValueKey(count),
        future: f,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return widget.placeholder ??
                AnnotatedRegion(
                  value: navBarStyleForTheme(theme, highTone: false),
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
              value: navBarStyleForTheme(theme),
              child: Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: widget.errorBuilder(snapshot.error!, refresh),
                ),
              ),
            );
          } else {
            return DecoratedBox(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              child: widget
                  .builder(context, snapshot.data as T)
                  .animate()
                  .fadeIn(),
            );
          }
        },
      ),
    );
  }
}
