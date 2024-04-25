// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/widgets/notifiers/focus.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_tag.dart";
import "package:logging/logging.dart";

class AutocompleteWidget extends StatelessWidget {
  const AutocompleteWidget(
    this.controller,
    this.highlightChanged,
    this.onSubmit,
    this.focusMain,
    this.complF,
    this.focus, {
    super.key,
    this.scrollHack,
    this.noSticky = false,
    this.submitOnPress = false,
    this.roundBorders = false,
    this.searchTextOverride,
    this.customHint,
    required this.swapSearchIcon,
    this.showSearch = false,
    this.plainSearchBar = false,
    this.searchCount,
    this.disable = false,
    this.noUnfocus = false,
    this.onChanged,
    this.addItems,
  });

  final TextEditingController? controller;
  final void Function(String) highlightChanged;
  final void Function(String) onSubmit;
  final void Function() focusMain;
  final Future<List<BooruTag>> Function(String) complF;
  final FocusNode? focus;
  final ScrollController? scrollHack;
  final bool noSticky;
  final bool submitOnPress;
  final bool roundBorders;
  final String? customHint;
  final bool showSearch;
  final int? searchCount;
  final bool noUnfocus;
  final void Function()? onChanged;
  final List<Widget>? addItems;
  final String? searchTextOverride;
  final bool plainSearchBar;
  final bool swapSearchIcon;
  final bool disable;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focus,
      optionsViewBuilder: (context, onSelected, options) {
        final tiles = options
            .map(
              (elem) => ListTile(
                onTap: () {
                  if (controller == null) {
                    if (submitOnPress) {
                      onSubmit(elem);
                    }
                    return;
                  }

                  if (submitOnPress) {
                    focusMain();
                    controller!.text = "";
                    onSubmit(elem);
                    return;
                  }

                  if (noSticky) {
                    onSelected(elem);
                    return;
                  }

                  final tags = List.from(controller!.text.split(" "));

                  if (tags.isNotEmpty) {
                    tags.removeLast();
                    tags.remove(elem);
                  }

                  tags.add(elem);

                  onSelected(tags.join(" "));
                  onChanged?.call();
                },
                title: Text(elem),
              ),
            )
            .toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(25),
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
              child: ListView.builder(
                itemCount: tiles.length,
                itemBuilder: (context, index) {
                  return Builder(
                    builder: (context) {
                      final highlight =
                          AutocompleteHighlightedOption.of(context) == index;
                      if (highlight) {
                        highlightChanged(options.elementAt(index));
                        WidgetsBinding.instance
                            .scheduleFrameCallback((timeStamp) {
                          Scrollable.ensureVisible(context);
                        });
                      }

                      return Container(
                        color: highlight ? Theme.of(context).focusColor : null,
                        child: tiles[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return plainSearchBar
            ? SearchBar(
                controller: textEditingController,
                focusNode: focusNode,
                hintText: AppLocalizations.of(context)!.searchHint,
                leading: const Icon(Icons.search),
                onChanged: disable ? null : (_) => onChanged,
                onSubmitted: onSubmit,
              )
            : makeSearchBar(
                context,
                focusNode: focusNode,
                disable: disable,
                addItems: addItems,
                textController: textEditingController,
                onChanged: onChanged,
                onSubmit: onSubmit,
                count: searchCount,
                swapSearchIcon: swapSearchIcon,
                searchTextOverride: searchTextOverride,
                customHint: customHint,
              );
      },
      optionsBuilder: (textEditingValue) async {
        if (disable) {
          return const [];
        }

        try {
          return (await autocompleteTag(textEditingValue.text, complF))
              .map((e) => e.tag);
        } catch (e, trace) {
          log(
            "autocomplete in search, excluded tags",
            level: Level.WARNING.value,
            error: e,
            stackTrace: trace,
          );

          return const [];
        }
      },
    );
  }
}

Widget makeSearchBar(
  BuildContext context, {
  String? searchTextOverride,
  String? customHint,
  int? count,
  required FocusNode focusNode,
  required List<Widget>? addItems,
  required TextEditingController textController,
  required void Function()? onChanged,
  required void Function(String) onSubmit,
  required bool swapSearchIcon,
  required bool disable,
  bool darkenColors = false,
  double maxWidth = double.infinity,
}) {
  final theme = Theme.of(context);

  final notifier = FocusNotifier.of(context);
  final onPrimary = theme.colorScheme.onPrimary;
  final onSurface = theme.colorScheme.onSurface;
  final surface = theme.colorScheme.surface;
  final surfaceTint = darkenColors
      ? theme.colorScheme.secondary
      : theme.colorScheme.surfaceTint;
  final primaryContainer = theme.colorScheme.primaryContainer;
  final onPrimaryContainer = theme.colorScheme.onPrimaryContainer;

  return AbsorbPointer(
    absorbing: disable,
    child: DefaultSelectionStyle(
      cursorColor: onPrimary.withOpacity(0.8),
      child: Theme(
        data: theme.copyWith(
          searchBarTheme: SearchBarThemeData(
            overlayColor: MaterialStatePropertyAll(onPrimary.withOpacity(0.05)),
            textStyle: MaterialStatePropertyAll(
              TextStyle(
                color: disable ? onSurface.withOpacity(0.4) : onPrimary,
              ),
            ),
            elevation: const MaterialStatePropertyAll(0),
            backgroundColor: MaterialStatePropertyAll(
              disable ? surface.withOpacity(0.4) : surfaceTint.withOpacity(0.8),
            ),
            hintStyle: MaterialStatePropertyAll(
              TextStyle(
                color: onPrimary.withOpacity(0.5),
              ),
            ),
          ),
          badgeTheme: BadgeThemeData(
            backgroundColor: primaryContainer,
            textColor: onPrimaryContainer.withOpacity(0.8),
          ),
          inputDecorationTheme: InputDecorationTheme(
            iconColor: disable ? onSurface.withOpacity(0.4) : onPrimary,
            prefixIconColor: disable ? onSurface.withOpacity(0.4) : onPrimary,
            suffixIconColor: disable ? onSurface.withOpacity(0.4) : onPrimary,
          ),
          iconTheme: IconThemeData(
            size: 18,
            color: disable ? onSurface.withOpacity(0.4) : onPrimary,
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const MaterialStatePropertyAll(EdgeInsets.zero),
              iconColor: MaterialStatePropertyAll(onPrimary),
            ),
          ),
          hintColor: onPrimary.withOpacity(0.5),
        ),
        child: SearchBar(
          side: const MaterialStatePropertyAll(BorderSide.none),
          leading: !notifier.hasFocus
              ? swapSearchIcon && addItems != null && addItems.length == 1
                  ? addItems.first
                  : const Icon(Icons.search_rounded)
              : BackButton(
                  onPressed: () {
                    FocusNotifier.of(context).unfocus();
                  },
                ),
          constraints: BoxConstraints(
            maxHeight: 38,
            minHeight: 38,
            maxWidth: !notifier.hasFocus || disable
                ? 114 + (count != null ? 38 : 0)
                : maxWidth,
          ),
          hintText: notifier.hasFocus && !disable
              ? "${searchTextOverride ?? AppLocalizations.of(context)!.searchHint} ${customHint ?? ''}"
              : customHint ??
                  searchTextOverride ??
                  AppLocalizations.of(context)!.searchHint,
          controller: textController,
          focusNode: focusNode,
          trailing: notifier.hasFocus && !disable
              ? [
                  if (addItems != null) ...addItems,
                  IconButton(
                    onPressed: () {
                      textController.clear();
                      onChanged?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ]
              : count != null
                  ? [Badge(label: Text(count.toString()))]
                  : null,
          onChanged: disable
              ? null
              : (value) {
                  onChanged?.call();
                },
          onSubmitted: disable
              ? null
              : (value) {
                  onSubmit(value);
                },
        ),
      ),
    ),
  );
}
