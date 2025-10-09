// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math" as math;

import "package:azari/src/logic/typedefs.dart";
import "package:dio/dio.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

class EmptyWidget extends StatefulWidget {
  const EmptyWidget({
    super.key,
    this.error,
    this.overrideEmpty,
    required this.gridSeed,
  });

  final int gridSeed;

  final String? error;
  final String? overrideEmpty;

  static String unwrapDioError(Object? error) {
    if (error == null) {
      return "";
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.unknown) {
        return error.error.toString();
      }

      final response = error.response;
      if (response == null) {
        return error.message ?? error.toString();
      }

      return "${response.statusCode}${response.statusMessage != null ? ' ${response.statusMessage}' : ''}";
    }

    return error.toString();
  }

  @override
  State<EmptyWidget> createState() => _EmptyWidgetState();
}

class _EmptyWidgetState extends State<EmptyWidget> {
  late final TapGestureRecognizer gestureRecognizer;

  String? get error => widget.error;
  bool get hasError => error != null;

  @override
  void initState() {
    super.initState();

    gestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.of(context, rootNavigator: true).push<void>(
          DialogRoute(
            context: context,
            builder: (context) {
              final theme = Theme.of(context);

              return AlertDialog(
                content: Text(
                  error.toString(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFeatures: const [
                      FontFeature.slashedZero(),
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      };
  }

  @override
  void dispose() {
    gestureRecognizer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return ErrorWidgetBackground(error: error!);
    }

    final l10n = context.l10n();

    return EmptyWidgetBackground(
      subtitle: widget.overrideEmpty ?? l10n.emptyWidgetPlaceholder,
    );
  }
}

class EmptyWidgetWithButton extends StatelessWidget {
  const EmptyWidgetWithButton({
    super.key,
    this.overrideText,
    required this.error,
    required this.onPressed,
    required this.buttonText,
  });

  final String buttonText;
  final String? overrideText;

  final Object? error;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EmptyWidget(
          gridSeed: 0,
          overrideEmpty: overrideText,
          error: error == null ? null : EmptyWidget.unwrapDioError(error),
        ),
        const Padding(padding: EdgeInsets.only(top: 4)),
        FilledButton.tonal(onPressed: onPressed, child: Text(buttonText)),
      ],
    );
  }
}

class EmptyWidgetBackground extends StatelessWidget {
  const EmptyWidgetBackground({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "空",
              style: TextStyle(
                fontSize: 120,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            Text(l10n.emptyValue, style: theme.textTheme.headlineMedium),
            const Padding(padding: EdgeInsets.only(bottom: 12)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorWidgetBackground extends StatelessWidget {
  const ErrorWidgetBackground({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: math.pi / 6.0,
              child: Text(
                "?",
                style: TextStyle(
                  fontSize: 120,
                  color: theme.colorScheme.error.withValues(alpha: 0.9),
                ),
              ),
            ),
            Text(
              l10n.error,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 12)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
