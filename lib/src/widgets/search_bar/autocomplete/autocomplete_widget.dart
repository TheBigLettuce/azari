// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../db/schemas/tags.dart';
import 'autocomplete_tag.dart';

class AutocompleteWidget extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) highlightChanged;
  final void Function(Tag) onSubmit;
  final void Function() focusMain;
  final Future<List<String>> Function(String) complF;
  final FocusNode focus;
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

  const AutocompleteWidget(this.controller, this.highlightChanged,
      this.onSubmit, this.focusMain, this.complF, this.focus,
      {super.key,
      this.scrollHack,
      this.noSticky = false,
      this.submitOnPress = false,
      this.roundBorders = false,
      this.searchTextOverride,
      this.customHint,
      this.showSearch = false,
      this.plainSearchBar = false,
      this.searchCount,
      this.noUnfocus = false,
      this.onChanged,
      this.addItems});

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focus,
      optionsViewBuilder: (context, onSelected, options) {
        final tiles = options
            .map((elem) => ListTile(
                  onTap: () {
                    if (submitOnPress) {
                      focusMain();
                      controller.text = "";
                      onSubmit(Tag.string(tag: elem));
                      return;
                    }

                    if (noSticky) {
                      onSelected(elem);
                      return;
                    }

                    final tags = List.from(controller.text.split(" "));

                    if (tags.isNotEmpty) {
                      tags.removeLast();
                      tags.remove(elem);
                    }

                    tags.add(elem);

                    final tagsString =
                        tags.reduce((value, element) => "$value $element");

                    onSelected(tagsString);
                    onChanged?.call();
                  },
                  title: Text(elem),
                ))
            .toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(25),
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
              child: ListView.builder(
                itemCount: tiles.length,
                itemBuilder: (context, index) {
                  return Builder(builder: (context) {
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
                  });
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
                onChanged: (_) => onChanged,
                // onSubmitted: onFieldSubmitted,
              )
            : makeSearchBar(context,
                focusNode: focusNode,
                addItems: addItems,
                textController: textEditingController,
                onChanged: onChanged,
                onSubmit: onSubmit,
                count: searchCount,
                searchTextOverride: searchTextOverride,
                customHint: customHint);
      },
      optionsBuilder: (textEditingValue) async {
        try {
          return await autocompleteTag(textEditingValue.text, complF);
        } catch (e, trace) {
          log("autocomplete in search, excluded tags",
              level: Level.WARNING.value, error: e, stackTrace: trace);

          return [];
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
  required void Function(Tag) onSubmit,
}) {
  final notifier = FocusNotifier.of(context);

  return DefaultSelectionStyle(
    cursorColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
    child: Theme(
      data: Theme.of(context).copyWith(
          searchBarTheme: SearchBarThemeData(
            overlayColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
            textStyle: MaterialStatePropertyAll(
              TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            elevation: const MaterialStatePropertyAll(0),
            backgroundColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.surfaceTint.withOpacity(0.8)),
            hintStyle: MaterialStatePropertyAll(
              TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
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
          inputDecorationTheme: InputDecorationTheme(
            iconColor: Theme.of(context).colorScheme.onPrimary,
            prefixIconColor: Theme.of(context).colorScheme.onPrimary,
            suffixIconColor: Theme.of(context).colorScheme.onPrimary,
          ),
          iconTheme: IconThemeData(
              size: 18, color: Theme.of(context).colorScheme.onPrimary),
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
                  iconColor: MaterialStatePropertyAll(
                      Theme.of(context).colorScheme.onPrimary))),
          hintColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
      child: SearchBar(
        side: const MaterialStatePropertyAll(BorderSide.none),
        leading: !notifier.hasFocus
            ? addItems != null && addItems.length == 1
                ? addItems.first
                : const Icon(Icons.search_rounded)
            : BackButton(
                onPressed: () {
                  notifier.unfocus();
                },
              ),
        constraints: BoxConstraints.expand(
            height: 38,
            width: !notifier.hasFocus ? 114 + (count != null ? 38 : 0) : null),
        hintText: notifier.hasFocus
            ? "${searchTextOverride ?? AppLocalizations.of(context)!.searchHint} ${customHint ?? ''}"
            : customHint ??
                searchTextOverride ??
                AppLocalizations.of(context)!.searchHint,
        controller: textController,
        focusNode: focusNode,
        trailing: notifier.hasFocus
            ? [
                if (addItems != null) ...addItems,
                IconButton(
                    onPressed: () {
                      textController.clear();
                      onChanged?.call();
                    },
                    icon: const Icon(Icons.close))
              ]
            : count != null
                ? [Badge(label: Text(count.toString()))]
                : null,
        onChanged: (value) {
          onChanged?.call();
        },
        onSubmitted: (value) {
          onSubmit(Tag.string(tag: value));
        },
      ),
    ),
  );
}
