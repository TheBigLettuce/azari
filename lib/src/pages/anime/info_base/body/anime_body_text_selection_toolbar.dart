// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class AnimeBodyTextSelectionToolbar extends StatelessWidget {
  const AnimeBodyTextSelectionToolbar({
    super.key,
    required this.editableTextState,
    required this.search,
  });
  final EditableTextState editableTextState;
  final void Function(String selectedText) search;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: [
        ...editableTextState.contextMenuButtonItems,
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.hideToolbar();

            search(
              editableTextState.currentTextEditingValue.selection
                  .textInside(editableTextState.currentTextEditingValue.text),
            );
          },
          label: AppLocalizations.of(context)!.searchHint,
        ),
      ],
      anchors: editableTextState.contextMenuAnchors,
    );
  }
}
