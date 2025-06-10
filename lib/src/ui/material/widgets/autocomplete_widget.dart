// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:flutter/material.dart";
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

  final bool noSticky;
  final bool submitOnPress;
  final bool roundBorders;
  final bool showSearch;
  final bool plainSearchBar;
  final bool swapSearchIcon;
  final bool noUnfocus;
  final bool disable;

  final int? searchCount;

  final String? searchTextOverride;
  final String? customHint;

  final TextEditingController? controller;

  final FocusNode? focus;
  final ScrollController? scrollHack;

  final List<Widget>? addItems;

  final VoidCallback? onChanged;
  final VoidCallback focusMain;

  final StringCallback highlightChanged;
  final StringCallback onSubmit;

  final CompleteBooruTagFunc complF;

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

                  final tags = List<String>.from(controller!.text.split(" "));

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

        final theme = Theme.of(context);

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surfaceTint,
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
                        WidgetsBinding.instance.scheduleFrameCallback((
                          timeStamp,
                        ) {
                          Scrollable.ensureVisible(context);
                        });
                      }

                      return Container(
                        color: highlight ? theme.focusColor : null,
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
                    elevation: const WidgetStatePropertyAll(0),
                    controller: textEditingController,
                    focusNode: focusNode,
                    hintText: context.l10n().searchHint,
                    leading: const Icon(Icons.search),
                    onChanged: disable ? null : (_) => onChanged,
                    onSubmitted: onSubmit,
                  )
                : AutocompleteSearchBar(
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
          return (await autocompleteTag(
            textEditingValue.text,
            complF,
          )).map((e) => e.tag);
        } catch (e, trace) {
          Logger.root.warning("AutocompleteWidget", e, trace);

          return const [];
        }
      },
    );
  }
}

class AutocompleteSearchBar extends StatelessWidget {
  const AutocompleteSearchBar({
    super.key,
    required this.searchTextOverride,
    this.customHint,
    this.count,
    required this.focusNode,
    required this.addItems,
    required this.textController,
    required this.onChanged,
    required this.onSubmit,
    required this.swapSearchIcon,
    required this.disable,
    this.darkenColors = false,
    this.maxWidth = double.infinity,
  });

  final bool swapSearchIcon;
  final bool disable;
  final bool darkenColors;

  final int? count;

  final double maxWidth;

  final String? searchTextOverride;
  final String? customHint;

  final FocusNode focusNode;
  final List<Widget>? addItems;
  final TextEditingController textController;

  final VoidCallback? onChanged;
  final StringCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
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
        cursorColor: onPrimary.withValues(alpha: 0.8),
        child: Theme(
          data: theme.copyWith(
            searchBarTheme: SearchBarThemeData(
              overlayColor: WidgetStatePropertyAll(
                onPrimary.withValues(alpha: 0.05),
              ),
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: disable ? onSurface.withValues(alpha: 0.4) : onPrimary,
                ),
              ),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                disable
                    ? surface.withValues(alpha: 0.4)
                    : surfaceTint.withValues(alpha: 0.8),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(color: onPrimary.withValues(alpha: 0.5)),
              ),
            ),
            badgeTheme: BadgeThemeData(
              backgroundColor: primaryContainer,
              textColor: onPrimaryContainer.withValues(alpha: 0.8),
            ),
            inputDecorationTheme: InputDecorationTheme(
              iconColor: disable ? onSurface.withValues(alpha: 0.4) : onPrimary,
              prefixIconColor: disable
                  ? onSurface.withValues(alpha: 0.4)
                  : onPrimary,
              suffixIconColor: disable
                  ? onSurface.withValues(alpha: 0.4)
                  : onPrimary,
            ),
            iconTheme: IconThemeData(
              size: 18,
              color: disable ? onSurface.withValues(alpha: 0.4) : onPrimary,
            ),
            iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                iconColor: WidgetStatePropertyAll(onPrimary),
              ),
            ),
            hintColor: onPrimary.withValues(alpha: 0.5),
          ),
          child: SearchBar(
            elevation: const WidgetStatePropertyAll(0),
            side: const WidgetStatePropertyAll(BorderSide.none),
            leading: !notifier.hasFocus
                ? swapSearchIcon && addItems != null && addItems!.length == 1
                      ? addItems!.first
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
                ? "${searchTextOverride ?? l10n.searchHint} ${customHint ?? ''}"
                : customHint ?? searchTextOverride ?? l10n.searchHint,
            controller: textController,
            focusNode: focusNode,
            trailing: notifier.hasFocus && !disable
                ? [
                    if (addItems != null) ...addItems!,
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
}

Future<List<BooruTag>> autocompleteTag(
  String tagString,
  Future<List<BooruTag>> Function(String) complF,
) {
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

class FocusNotifier extends InheritedNotifier<FocusNode> {
  const FocusNotifier({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ({VoidCallback unfocus, bool hasFocus}) of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FocusNotifier>()!;

    return (
      hasFocus: widget.notifier?.hasFocus ?? false,
      unfocus: widget.notifier?.previousFocus ?? () {},
    );
  }

  static FocusNode nodeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FocusNotifier>()!;

    return widget.notifier!;
  }
}
