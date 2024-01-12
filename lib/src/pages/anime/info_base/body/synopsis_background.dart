// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'anime_body_text_selection_toolbar.dart';
import 'body_segment_label.dart';

class SynopsisBackground extends StatelessWidget {
  final AnimeEntry entry;
  final BoxConstraints constraints;

  const SynopsisBackground({
    super.key,
    required this.entry,
    this.constraints = const BoxConstraints(maxWidth: 200, maxHeight: 300),
  });

  Widget _textSelectionToolbar(
          BuildContext context, EditableTextState editableTextState) =>
      AnimeBodyTextSelectionToolbar(
          editableTextState: editableTextState, entry: entry);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        BodySegmentLabel(text: AppLocalizations.of(context)!.synopsisLabel),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: constraints,
            child: SelectableText(
              entry.synopsis,
              contextMenuBuilder: _textSelectionToolbar,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  overflow: TextOverflow.fade,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ),
        if (entry.background.isNotEmpty)
          BodySegmentLabel(text: AppLocalizations.of(context)!.backgroundLabel),
        if (entry.background.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
            child: AnimatedContainer(
              duration: 200.ms,
              constraints: constraints,
              child: SelectableText(
                entry.background,
                contextMenuBuilder: _textSelectionToolbar,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    overflow: TextOverflow.fade,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8)),
              ),
            ),
          ),
      ],
    );
  }
}
