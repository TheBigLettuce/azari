// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math";

import "package:azari/src/pages/anime/info_base/body/anime_body_text_selection_toolbar.dart";
import "package:azari/src/pages/anime/info_base/body/body_segment_label.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:url_launcher/url_launcher_string.dart";

class SynopsisBackground extends StatelessWidget {
  const SynopsisBackground({
    super.key,
    required this.background,
    required this.synopsis,
    required this.search,
    this.showLabel = true,
    this.markdown = false,
    this.constraints = const BoxConstraints(maxWidth: 200, maxHeight: 300),
  });
  final String background;
  final String synopsis;
  final BoxConstraints constraints;
  final void Function(String) search;
  final bool markdown;
  final bool showLabel;

  void onTapLink(String text, String? href, String title) {
    if (href != null) {
      launchUrlString(href);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(
          overflow: TextOverflow.fade,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );

    return Wrap(
      direction: Axis.vertical,
      children: [
        if (showLabel) BodySegmentLabel(text: l10n.synopsisLabel),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 4),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: constraints,
            child: markdown
                ? MarkdownBody(
                    onTapLink: onTapLink,
                    selectable: true,
                    styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                    data: synopsis,
                    bulletBuilder: (parameters) {
                      return Transform.rotate(
                        angle: -pi / Random(parameters.index).nextInt(100),
                        child: Icon(
                          const IconData(0x2726),
                          size: 12,
                          color: colorScheme.onSurface.withOpacity(0.8),
                          applyTextScaling: true,
                        ),
                      );
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      textTheme,
                    ).copyWith(
                      horizontalRuleDecoration: const UnderlineTabIndicator(
                        borderSide: BorderSide.none,
                      ),
                      a: TextStyle(
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : _BodyTextCollapsible(
                    text: synopsis,
                    textTheme: textTheme,
                    search: search,
                  ),
          ),
        ),
        if (background.isNotEmpty) BodySegmentLabel(text: l10n.backgroundLabel),
        if (background.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4),
            child: AnimatedContainer(
              duration: 200.ms,
              constraints: constraints,
              child: markdown
                  ? MarkdownBody(
                      onTapLink: onTapLink,
                      selectable: true,
                      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                      data: background,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        textTheme,
                      ).copyWith(
                        a: TextStyle(color: colorScheme.primary),
                      ),
                    )
                  : _BodyTextCollapsible(
                      text: background,
                      textTheme: textTheme,
                      search: search,
                    ),
            ),
          ),
      ],
    );
  }
}

class _BodyTextCollapsible extends StatefulWidget {
  const _BodyTextCollapsible({
    // super.key,
    required this.text,
    required this.search,
    required this.textTheme,
  });

  final String text;
  final ThemeData textTheme;

  final void Function(String) search;

  @override
  State<_BodyTextCollapsible> createState() => __BodyTextCollapsibleState();
}

class __BodyTextCollapsibleState extends State<_BodyTextCollapsible> {
  bool collapse = true;

  Widget _textSelectionToolbar(
    BuildContext context,
    EditableTextState editableTextState,
  ) =>
      AnimeBodyTextSelectionToolbar(
        editableTextState: editableTextState,
        search: widget.search,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = SelectableText(
      collapse && widget.text.length > 150
          ? "${widget.text.substring(0, 150)}..."
          : widget.text,
      contextMenuBuilder: _textSelectionToolbar,
      style: widget.textTheme.textTheme.bodyMedium,
    );

    return widget.text.length < 150
        ? child
        : Stack(
            alignment: Alignment.bottomCenter,
            children: [
              child,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: !collapse
                      ? null
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.2),
                            theme.colorScheme.surface.withOpacity(0.4),
                            theme.colorScheme.surface.withOpacity(0.6),
                            theme.colorScheme.surface.withOpacity(0.8),
                          ],
                        ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          collapse = !collapse;
                        });
                      },
                      child: Text(!collapse ? "Collapse" : "More"),
                    ),
                  ),
                ),
              ),
              // Text("data"),
            ],
          );
  }
}
