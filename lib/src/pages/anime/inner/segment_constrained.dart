// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class _SegmentConstrained extends StatelessWidget {
  final AnimeEntry entry;
  final AnimeAPI api;
  final BoxConstraints constraints;

  const _SegmentConstrained({
    required this.entry,
    required this.api,
    this.constraints = const BoxConstraints(maxWidth: 200, maxHeight: 300),
  });

  Widget _selectionToolbar(
      BuildContext context, EditableTextState editableTextState) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: [
        ...editableTextState.contextMenuButtonItems,
        ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();

              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return SearchAnimePage(
                    api: api,
                    initalText: editableTextState
                        .currentTextEditingValue.selection
                        .textInside(
                            editableTextState.currentTextEditingValue.text),
                  );
                },
              ));
            },
            label: "Search")
      ],
      anchors: editableTextState.contextMenuAnchors,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        const BodySegmentLabel(text: "Synopsis"), // TODO: change
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: constraints,
            child: SelectableText(
              entry.synopsis,
              contextMenuBuilder: _selectionToolbar,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  overflow: TextOverflow.fade,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ),
        if (entry.background.isNotEmpty)
          const BodySegmentLabel(text: "Background"), // TODO: change
        if (entry.background.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
            child: AnimatedContainer(
              duration: 200.ms,
              constraints: constraints,
              child: SelectableText(
                entry.background,
                contextMenuBuilder: _selectionToolbar,
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
