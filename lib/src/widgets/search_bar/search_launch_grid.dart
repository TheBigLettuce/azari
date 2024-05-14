// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_tag.dart";
import "package:gallery/src/widgets/search_bar/search_launch_grid_data.dart";

class LaunchingSearchWidget extends StatefulWidget {
  const LaunchingSearchWidget({
    super.key,
    required this.getTags,
    required this.state,
    required this.searchController,
    required this.hint,
  });

  final String Function() getTags;
  final SearchLaunchGridData state;
  final SearchController searchController;
  final String? hint;

  @override
  State<LaunchingSearchWidget> createState() => _LaunchingSearchWidgetState();
}

class _LaunchingSearchWidgetState extends State<LaunchingSearchWidget> {
  SearchLaunchGridData get state => widget.state;
  SearchController get searchController => widget.searchController;

  (Future<List<BooruTag>>, String)? previousSearch;

  final _ScrollHack _scrollHack = _ScrollHack();

  @override
  void dispose() {
    _scrollHack.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addItems = state.addItems(context);

    return AbsorbPointer(
      absorbing: state.disabled,
      child: DefaultSelectionStyle(
        child: Theme(
          data: Theme.of(context).copyWith(
            searchBarTheme: SearchBarThemeData(
              overlayColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              ),
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: state.disabled
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                      : Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                state.disabled
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.4)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceTint
                        .withOpacity(0.8),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: state.disabled
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Theme.of(context)
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
            hintColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
          ),
          child: SearchAnchor(
            builder: (context, controller) {
              return InkWell(
                splashColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                hoverColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                onTap: controller.openView,
                borderRadius: BorderRadius.circular(25),
                child: AbsorbPointer(
                  child: SearchBar(
                    side: const WidgetStatePropertyAll(BorderSide.none),
                    leading:
                        state.swapSearchIconWithAddItems && addItems.length == 1
                            ? addItems.first
                            : Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: state.disabled
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.4)
                                    : Theme.of(context).colorScheme.onPrimary,
                              ),
                    constraints: const BoxConstraints.expand(
                      height: 38,
                      width: 114,
                    ),
                    hintText: state.disabled || state.searchTextAsLabel
                        ? widget.getTags()
                        : AppLocalizations.of(context)!.searchHint,
                    onSubmitted: state.disabled
                        ? null
                        : (value) {
                            searchController.closeView(null);
                            state.onSubmit(context, value);
                          },
                  ),
                ),
              );
            },
            viewTrailing: [
              ...addItems,
              IconButton(
                onPressed: searchController.clear,
                icon: const Icon(Icons.close),
              ),
            ],
            viewOnSubmitted: (value) {
              state.onSubmit(context, value);
            },
            viewHintText:
                "${AppLocalizations.of(context)!.searchHint} ${widget.hint ?? ''}",
            searchController: searchController,
            suggestionsBuilder: (suggestionsContext, controller) {
              if (controller.text.isEmpty) {
                return [state.header];
              }

              if (previousSearch == null) {
                previousSearch = (
                  autocompleteTag(controller.text, state.completeTag),
                  controller.text
                );
              } else {
                if (previousSearch!.$2 != controller.text) {
                  previousSearch?.$1.ignore();
                  previousSearch = (
                    autocompleteTag(controller.text, state.completeTag),
                    controller.text
                  );
                }
              }

              return [
                FutureBuilder(
                  key: ValueKey(previousSearch!.$2),
                  future: previousSearch!.$1,
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        state.header,
                        if (!snapshot.hasData)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: SizedBox(
                                height: 4,
                                width: 40,
                                child: LinearProgressIndicator(),
                              ),
                            ),
                          )
                        else ...[
                          const Divider(indent: 8, endIndent: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 8, left: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: -4,
                              children: snapshot.data!
                                  .map(
                                    (e) => ActionChip(
                                      label: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(text: e.tag),
                                            TextSpan(
                                              text: "  ${e.count}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.25),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onPressed: () {
                                        final tags = List<String>.from(
                                          controller.text.split(" "),
                                        );

                                        if (tags.isNotEmpty) {
                                          tags.removeLast();
                                          tags.remove(e.tag);
                                        }

                                        tags.add(e.tag);

                                        final tagsString = tags.reduce(
                                          (value, element) => "$value $element",
                                        );

                                        searchController.text = "$tagsString ";
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}

/// Search mixin which launches a new page with a grid.
class SearchLaunchGrid<T extends CellBase> {
  SearchLaunchGrid(this._state) {
    searchController.text = _state.searchText;
    tags = _state.searchText;
  }

  final searchController = SearchController();
  final FocusNode searchFocus = FocusNode();

  final SearchLaunchGridData _state;

  String tags = "";

  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
  }

  String _getTags() => tags;

  Widget searchWidget(BuildContext context, {String? hint}) =>
      LaunchingSearchWidget(
        getTags: _getTags,
        state: _state,
        searchController: searchController,
        hint: hint,
      );
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
