// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_tag.dart';

import '../../interfaces/cell/cell.dart';
import 'search_launch_grid_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Search mixin which launches a new page with a grid.
class SearchLaunchGrid<T extends Cell> {
  SearchLaunchGrid(this._state) {
    searchController.text = _state.searchText;
  }

  final searchController = SearchController();
  final FocusNode searchFocus = FocusNode();

  final _ScrollHack _scrollHack = _ScrollHack();
  final SearchLaunchGridData _state;

  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    _scrollHack.dispose();
  }

  (Future<List<String>>, String)? previousSearch;

  Widget searchWidget(BuildContext context, {String? hint, int? count}) {
    final addItems = _state.addItems(context);

    return AbsorbPointer(
      absorbing: _state.disabled,
      child: DefaultSelectionStyle(
        child: Theme(
          data: Theme.of(context).copyWith(
              searchBarTheme: SearchBarThemeData(
                overlayColor: MaterialStatePropertyAll(
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
                textStyle: MaterialStatePropertyAll(
                  TextStyle(
                    color: _state.disabled
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4)
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                elevation: const MaterialStatePropertyAll(0),
                backgroundColor: MaterialStatePropertyAll(_state.disabled
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.4)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceTint
                        .withOpacity(0.8)),
                hintStyle: MaterialStatePropertyAll(
                  TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.5),
                  ),
                ),
              ),
              badgeTheme: BadgeThemeData(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                textColor: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withOpacity(0.8),
              ),
              hintColor:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
          child: SearchAnchor.bar(
            searchController: searchController,
            suggestionsBuilder: (suggestionsContext, controller) {
              if (controller.text.isEmpty) {
                return [_state.header];
              }

              if (previousSearch == null) {
                previousSearch = (
                  autocompleteTag(controller.text, _state.completeTag),
                  controller.text
                );
              } else {
                if (previousSearch!.$2 != controller.text) {
                  previousSearch?.$1.ignore();
                  previousSearch = (
                    autocompleteTag(controller.text, _state.completeTag),
                    controller.text
                  );
                }
              }

              return [
                FutureBuilder(
                  key: ValueKey(previousSearch!.$2),
                  future: previousSearch!.$1,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Column(
                        children: [
                          const LinearProgressIndicator(),
                          _state.header,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _state.header,
                        ListBody(
                          children: snapshot.data!
                              .map((e) => ListTile(
                                    title: Text(e),
                                    onTap: () {
                                      final tags =
                                          List.from(controller.text.split(" "));

                                      if (tags.isNotEmpty) {
                                        tags.removeLast();
                                        tags.remove(e);
                                      }

                                      tags.add(e);

                                      final tagsString = tags.reduce(
                                          (value, element) =>
                                              "$value $element");

                                      searchController.text = tagsString + " ";
                                    },
                                  ))
                              .toList(),
                        )
                      ],
                    );
                  },
                )
              ];
            },
            barSide: const MaterialStatePropertyAll(BorderSide.none),
            barLeading:
                _state.swapSearchIconWithAddItems && addItems.length == 1
                    ? addItems.first
                    : Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: _state.disabled
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
            constraints: const BoxConstraints.expand(
              height: 38,
              width: 114 + 38,
            ),
            viewHintText:
                "${AppLocalizations.of(context)!.searchHint} ${hint ?? ''}",
            barHintText: AppLocalizations.of(context)!.searchHint,
            viewTrailing: [
              ...addItems,
              IconButton(
                onPressed: searchController.clear,
                icon: const Icon(Icons.close),
              )
            ],
            onChanged: null,
            onSubmitted: _state.disabled
                ? null
                : (value) {
                    searchController.closeView(null);
                    _state.onSubmit(context, value);
                  },
          ),
        ),
      ),
    );
  }
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
