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

import '../../schemas/tags.dart';

Future<List<String>> autoCompleteTag(
    String tagString, Future<List<String>> Function(String) complF) {
  if (tagString.isEmpty) {
    return Future.value([]);
  } else if (tagString.characters.last == " ") {
    return Future.value([]);
  }

  final tags = tagString.trim().split(" ");

  return tags.isEmpty || tags.last.isEmpty
      ? Future.value([])
      : complF(tags.last);
}

Widget autocompleteWidget(
    TextEditingController controller,
    void Function(String) highlightChanged,
    void Function(Tag) onSubmit,
    void Function() focusMain,
    Future<List<String>> Function(String) complF,
    FocusNode focus,
    {ScrollController? scrollHack,
    bool noSticky = false,
    bool submitOnPress = false,
    bool roundBorders = false,
    String? customHint,
    bool showSearch = false,
    int? searchCount,
    bool noUnfocus = false,
    void Function()? onChanged,
    List<Widget>? addItems}) {
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
      return FocusNotifier(
          focusMain: focusMain,
          notifier: focus,
          child: Builder(
            builder: (context) {
              return TextField(
                scrollController: scrollHack,
                cursorOpacityAnimates: true,
                decoration: autocompleteBarDecoration(
                  context,
                  () {
                    textEditingController.clear();
                    //focus.unfocus();
                    if (!noUnfocus) {
                      focusMain();
                    }
                    onChanged?.call();
                  },
                  addItems,
                  searchCount: searchCount,
                  showSearch: showSearch,
                  roundBorders: roundBorders,
                  hint: customHint ?? AppLocalizations.of(context)!.searchHint,
                ),
                controller: textEditingController,
                focusNode: focusNode,
                onChanged: (value) {
                  onChanged?.call();
                },
                onSubmitted: (value) {
                  onSubmit(Tag.string(tag: value));
                },
              );
            },
          ));
    },
    optionsBuilder: (textEditingValue) async {
      try {
        return await autoCompleteTag(textEditingValue.text, complF);
      } catch (e, trace) {
        log("autocomplete in search, excluded tags",
            level: Level.WARNING.value, error: e, stackTrace: trace);

        return [];
      }
    },
  );
}

InputDecoration autocompleteBarDecoration(
    BuildContext context, void Function() iconOnPressed, List<Widget>? addItems,
    {required bool showSearch,
    int? searchCount,
    required bool roundBorders,
    required String hint}) {
  return InputDecoration(
      prefixIcon: FocusNotifier.of(context).hasFocus
          ? IconButton(
              onPressed: FocusNotifier.of(context).unfocus,
              icon: Badge.count(
                count: searchCount ?? 0,
                isLabelVisible: searchCount != null,
                child: const Icon(Icons.arrow_back),
              ),
              padding: EdgeInsets.zero,
            )
          : showSearch
              ? IconButton(
                  onPressed: null,
                  icon: Badge.count(
                    count: searchCount ?? 0,
                    isLabelVisible: searchCount != null,
                    child: const Icon(Icons.search_rounded),
                  ),
                  padding: EdgeInsets.zero,
                )
              : null,
      suffixIcon: addItems == null || addItems.isEmpty
          ? null
          : Wrap(
              children: addItems,
            ),
      suffix: IconButton(
        onPressed: iconOnPressed,
        icon: const Icon(Icons.close),
      ),
      hintText: hint,
      border: roundBorders
          ? const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(50)))
          : InputBorder.none,
      isDense: false);
}

class FilterValueNotifier extends InheritedNotifier<TextEditingController> {
  const FilterValueNotifier(
      {super.key, required super.notifier, required super.child});

  static String maybeOf(BuildContext context) {
    var widget =
        context.dependOnInheritedWidgetOfExactType<FilterValueNotifier>();
    return widget?.notifier?.value.text ?? "";
  }
}

class TagRefreshNotifier extends InheritedWidget {
  final void Function() notify;

  const TagRefreshNotifier(
      {super.key, required this.notify, required super.child});

  static void Function()? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagRefreshNotifier>();

    return widget?.notify;
  }

  @override
  bool updateShouldNotify(TagRefreshNotifier oldWidget) =>
      oldWidget.notify != notify;
}

class FilterNotifier extends InheritedWidget {
  final FilterNotifierData data;

  const FilterNotifier({super.key, required this.data, required super.child});

  static FilterNotifierData? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FilterNotifier>();

    return widget?.data;
  }

  @override
  bool updateShouldNotify(FilterNotifier oldWidget) => data != oldWidget.data;
}

class FilterNotifierData {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final void Function() focusMain;

  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
  }

  const FilterNotifierData(
      this.focusMain, this.searchController, this.searchFocus);
}

class FocusNotifier extends InheritedNotifier<FocusNode> {
  final void Function() focusMain;
  const FocusNotifier(
      {super.key,
      required super.notifier,
      required this.focusMain,
      required super.child});

  static FocusNotifierData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FocusNotifier>()!;

    return FocusNotifierData(
        hasFocus: widget.notifier?.hasFocus ?? false,
        unfocus: widget.focusMain);
  }
}

class FocusNotifierData {
  final void Function() unfocus;
  final bool hasFocus;
  const FocusNotifierData({required this.hasFocus, required this.unfocus});
}
