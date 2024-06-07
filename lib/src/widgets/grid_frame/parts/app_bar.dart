// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.bottomWidget,
    required this.searchWidget,
    required this.pageName,
    required this.searchFocus,
    required this.page,
    required this.description,
    required this.atHomePage,
    required this.gridFunctionality,
  });

  final FocusNode searchFocus;
  final PreferredSizeWidget? bottomWidget;
  final GridSearchWidget searchWidget;
  final String pageName;
  final PageDescription? page;
  final GridDescription description;
  final bool atHomePage;
  final GridFunctionality gridFunctionality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final search = searchWidget;

    final pageSettingsButton = page?.settingsButton;

    final List<Widget>? pageActions = page != null
        ? [
            ...page!.appIcons,
            if (pageSettingsButton != null) pageSettingsButton,
          ]
        : null;

    // if (!atHomePage && page?.search == null) {
    //   return description.pages!.switcherWidget(context, state);
    // } else if (page?.search != null) {
    //   return page!.search!.search;
    // }
    final backButton = gridFunctionality.backButton;

    final Widget? b = switch (backButton) {
      EmptyGridBackButton() =>
        Navigator.of(context).canPop() && backButton.inherit
            ? const BackButton()
            : null,
      CallbackGridBackButton() => BackButton(onPressed: backButton.onPressed),
      OverrideGridBackButton() => backButton.child,
    };

    Widget wrapAutocomplete(
      BarSearchWidget search,
      Widget Function(
        BuildContext,
        TextEditingController,
        FocusNode,
        void Function(),
      ) child,
    ) =>
        RawAutocomplete<String>(
          textEditingController: search.textEditingController,
          focusNode: search.textEditingController == null ? null : searchFocus,
          optionsBuilder: (textEditingValue) async {
            if (search.complete == null) {
              return [];
            }
            try {
              return (await autocompleteTag(
                textEditingValue.text,
                search.complete!,
              ))
                  .map((e) => e.tag);
            } catch (e) {
              return [];
            }
          },
          fieldViewBuilder: child,
          optionsViewBuilder: (
            BuildContext context,
            void Function(String) onSelected,
            Iterable<String> options,
          ) {
            final tiles = options
                .map(
                  (elem) => ListTile(
                    onTap: () {
                      if (search.textEditingController == null) {
                        return;
                      }

                      // if (submitOnPress) {
                      //   focusMain();
                      //   controller!.text = "";
                      //   onSubmit(elem);
                      //   return;
                      // }

                      // if (noSticky) {
                      //   onSelected(elem);
                      //   return;
                      // }

                      final tags = List<String>.from(
                        search.textEditingController!.text.split(" "),
                      );

                      if (tags.isNotEmpty) {
                        tags.removeLast();
                        tags.remove(elem);
                      }

                      tags.add(elem);

                      onSelected(tags.join(" "));
                      search.onChange?.call(search.textEditingController!.text);
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
                  constraints:
                      const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: ListView.builder(
                    itemCount: tiles.length,
                    itemBuilder: (context, index) {
                      return Builder(
                        builder: (context) {
                          final highlight =
                              AutocompleteHighlightedOption.of(context) ==
                                  index;
                          if (highlight) {
                            // highlightChanged(options.elementAt(index));
                            WidgetsBinding.instance
                                .scheduleFrameCallback((timeStamp) {
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
        );

    return switch (search) {
      PageNameSearchWidget() => SliverAppBar.large(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          title: Text(pageName),
          leading: search.leading,
          actions: search.trailingItems,
          automaticallyImplyLeading: false,
          bottom: bottomWidget,
        ),
      BarSearchWidget() => SliverAppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: theme.colorScheme.surface.withOpacity(0.95),
          ),
          toolbarHeight: 80,
          backgroundColor: theme.colorScheme.surface.withOpacity(0),
          centerTitle: true,
          title: Center(
            child: search.complete != null
                ? wrapAutocomplete(
                    search,
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) =>
                        SearchBar(
                      onTapOutside: (_) => focusNode.unfocus(),
                      onChanged: search.onChange,
                      focusNode: focusNode,
                      controller: textEditingController,
                      // elevation: const WidgetStatePropertyAll(0),
                      onSubmitted: (_) => onFieldSubmitted(),
                      leading: search.leading ??
                          b ??
                          const Icon(Icons.search_rounded),
                      hintText: search.hintText ?? l10n.searchHint,
                      trailing: [
                        ...?search.trailingItems,
                        // if (search.enableCount)
                        //   _Badge(
                        //     source: gridFunctionality.source.backingStorage,
                        //     child: SizedBox.shrink(),
                        //   ),
                        if (search.filterWidget != null) search.filterWidget!,
                        if (gridFunctionality.settingsButton != null)
                          gridFunctionality.settingsButton!,
                      ],
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  )
                : SearchBar(
                    onChanged: search.onChange,
                    focusNode: searchFocus,
                    onTapOutside: (_) => searchFocus.unfocus(),
                    controller: search.textEditingController,
                    // elevation: const WidgetStatePropertyAll(0),
                    leading:
                        search.leading ?? b ?? const Icon(Icons.search_rounded),
                    hintText: search.hintText ?? l10n.searchHint,
                    trailing: [
                      ...?search.trailingItems,
                      // if (search.enableCount)
                      //   _Badge(
                      //     source: gridFunctionality.source.backingStorage,
                      //     child: SizedBox.shrink(),
                      //   ),
                      if (search.filterWidget != null) search.filterWidget!,
                      if (gridFunctionality.settingsButton != null)
                        gridFunctionality.settingsButton!,
                    ],
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
          ),
          pinned: true,
          stretch: true,
          snap: true,
          floating: true,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          bottom: bottomWidget,
        ),
      RawSearchWidget() =>
        search.sliver(gridFunctionality.settingsButton, bottomWidget),
    };
  }
}

// class _Badge extends StatefulWidget {
//   const _Badge({super.key, required this.source, required this.child});

//   final ReadOnlyStorage<dynamic, dynamic> source;
//   final Widget child;

//   @override
//   State<_Badge> createState() => __BadgeState();
// }

// class __BadgeState extends State<_Badge> {
//   late final StreamSubscription<void> subsc;

//   @override
//   void initState() {
//     super.initState();

//     subsc = widget.source.watch((_) {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     subsc.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Badge.count(
//       largeSize: 20,
//       padding: const EdgeInsets.symmetric(horizontal: 6),
//       backgroundColor: theme.colorScheme.surfaceContainer.withOpacity(0),
//       textColor: theme.colorScheme.onSurface.withOpacity(0.6),
//       count: widget.source.count,
//     );
//   }
// }
