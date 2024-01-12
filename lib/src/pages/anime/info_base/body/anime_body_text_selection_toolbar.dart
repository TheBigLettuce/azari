// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnimeBodyTextSelectionToolbar extends StatelessWidget {
  final EditableTextState editableTextState;
  final AnimeEntry entry;

  const AnimeBodyTextSelectionToolbar({
    super.key,
    required this.editableTextState,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: [
        ...editableTextState.contextMenuButtonItems,
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.hideToolbar();

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return SearchAnimePage(
                  api: entry.site.api,
                  initalText: editableTextState
                      .currentTextEditingValue.selection
                      .textInside(
                          editableTextState.currentTextEditingValue.text),
                );
              },
            ));
          },
          label: AppLocalizations.of(context)!.searchHint,
        )
      ],
      anchors: editableTextState.contextMenuAnchors,
    );
  }
}
