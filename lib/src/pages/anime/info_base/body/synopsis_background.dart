// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:gallery/src/pages/anime/info_base/body/anime_body_text_selection_toolbar.dart";
import "package:gallery/src/pages/anime/info_base/body/body_segment_label.dart";
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

  Widget _textSelectionToolbar(
    BuildContext context,
    EditableTextState editableTextState,
  ) =>
      AnimeBodyTextSelectionToolbar(
        editableTextState: editableTextState,
        search: search,
      );

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
                    bulletBuilder: (index, style) {
                      return Transform.rotate(
                        angle: -pi / Random(index).nextInt(100),
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
                : SelectableText(
                    synopsis,
                    contextMenuBuilder: _textSelectionToolbar,
                    style: textTheme.textTheme.bodyMedium,
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
                  : SelectableText(
                      background,
                      contextMenuBuilder: _textSelectionToolbar,
                      style: textTheme.textTheme.bodyMedium,
                    ),
            ),
          ),
      ],
    );
  }
}
