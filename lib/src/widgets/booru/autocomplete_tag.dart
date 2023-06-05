// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/isar.dart';

Future<List<String>> autoCompleteTag(
    String tagString, Future<List<String>> Function(String) complF) {
  if (tagString.isEmpty) {
    return Future.value([]);
  } else if (tagString.characters.last == " ") {
    return Future.value([]);
  }

  var tags = tagString.trim().split(" ");

  return complF(tags.isEmpty ? "" : tags.last);
}

Widget autocompleteWidget(
    TextEditingController controller,
    void Function(String) highlightChanged,
    void Function(String) onSubmit,
    Future<List<String>> Function(String) complF,
    FocusNode focus,
    {ScrollController? scrollHack,
    bool noSticky = false,
    bool submitOnPress = false,
    bool roundBorders = false,
    bool showSearch = false}) {
  return RawAutocomplete<String>(
    textEditingController: controller,
    focusNode: focus,
    optionsViewBuilder: (context, onSelected, options) {
      var tiles = options
          .map((elem) => ListTile(
                onTap: () {
                  if (submitOnPress) {
                    focus.unfocus();
                    controller.text = "";
                    onSubmit(elem);
                    return;
                  }

                  if (noSticky) {
                    onSelected(elem);
                    return;
                  }

                  List<String> tags = List.from(controller.text.split(" "));

                  if (tags.isNotEmpty) {
                    tags.removeLast();
                    tags.remove(elem);
                  }

                  tags.add(elem);

                  var tagsString =
                      tags.reduce((value, element) => "$value $element");

                  onSelected(tagsString);
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
                  var highlight =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlight) {
                    highlightChanged(options.elementAt(index));
                    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
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
      return TextField(
        scrollController: scrollHack,
        cursorOpacityAnimates: true,
        decoration: InputDecoration(
            prefixIcon: showSearch ? const Icon(Icons.search_rounded) : null,
            suffixIcon: IconButton(
              onPressed: () {
                textEditingController.clear();
                focus.unfocus();
              },
              icon: const Icon(Icons.close),
            ),
            hintText: AppLocalizations.of(context)!.searchHint,
            border: roundBorders
                ? const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)))
                : InputBorder.none,
            isDense: false),
        controller: textEditingController,
        focusNode: focusNode,
        onSubmitted: (value) {
          onSubmit(value);
        },
      );
    },
    optionsBuilder: (textEditingValue) async {
      List<String> options = [];
      try {
        options = await autoCompleteTag(textEditingValue.text, complF);
      } catch (e, trace) {
        log("autocomplete in search, excluded tags",
            level: Level.WARNING.value, error: e, stackTrace: trace);
      }

      return options;
    },
  );
}
