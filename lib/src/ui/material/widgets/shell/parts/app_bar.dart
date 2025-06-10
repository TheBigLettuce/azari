// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../shell_scope.dart";

sealed class AppBarBackButtonBehaviour {
  const AppBarBackButtonBehaviour();
}

class EmptyAppBarBackButton implements AppBarBackButtonBehaviour {
  const EmptyAppBarBackButton({required this.inherit});

  final bool inherit;
}

class CallbackAppBarBackButton implements AppBarBackButtonBehaviour {
  const CallbackAppBarBackButton({this.onPressed = _doNothing});

  static void _doNothing() {}

  final VoidCallback onPressed;
}

class OverrideAppBarBackButton implements AppBarBackButtonBehaviour {
  const OverrideAppBarBackButton(this.child);

  final Widget child;
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.bottomWidget,
    required this.searchWidget,
    required this.searchFocus,
    required this.backButton,
    required this.settingsButton,
  });

  final FocusNode searchFocus;
  final PreferredSizeWidget? bottomWidget;
  final ShellAppBarType searchWidget;

  final AppBarBackButtonBehaviour backButton;
  final Widget? settingsButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();
    final search = searchWidget;

    final backButton = this.backButton;

    final Widget? b = switch (backButton) {
      EmptyAppBarBackButton() =>
        Navigator.of(context).canPop() && backButton.inherit
            ? const BackButton()
            : null,
      CallbackAppBarBackButton() => BackButton(onPressed: backButton.onPressed),
      OverrideAppBarBackButton() => backButton.child,
    };

    return switch (search) {
      TitleAppBarType() =>
        bottomWidget != null
            ? SliverAppBar(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.95,
                ),
                title: Text(search.title),
                leading: search.leading ?? b,
                actions: [
                  ...?search.trailingItems,
                  if (settingsButton != null) settingsButton!,
                ],
                automaticallyImplyLeading: false,
                pinned: true,
                snap: true,
                floating: true,
                bottom: bottomWidget,
              )
            : SliverAppBar.medium(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.95,
                ),
                title: Text(search.title),
                leading: search.leading ?? b,
                actions: [
                  ...?search.trailingItems,
                  if (settingsButton != null) settingsButton!,
                ],
                automaticallyImplyLeading: false,
                bottom: bottomWidget,
              ),
      SearchBarAppBarType() => SliverAppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarContrastEnforced: false,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarColor: theme.colorScheme.surface.withValues(alpha: 0.95),
        ),
        toolbarHeight: 80,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
        centerTitle: true,
        title: Center(
          child: search.complete != null
              ? SearchBarAutocompleteWrapper(
                  searchFocus: searchFocus,
                  search: search,
                  child:
                      (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) => SearchBar(
                        onTap: search.onPressed == null
                            ? null
                            : () => search.onPressed!(context),
                        onTapOutside: (_) => focusNode.unfocus(),
                        onChanged: search.onChanged,
                        focusNode: focusNode,
                        controller: textEditingController,
                        elevation: const WidgetStatePropertyAll(0),
                        onSubmitted: (_) {
                          search.onSubmitted?.call(textEditingController.text);
                          onFieldSubmitted();
                        },
                        leading:
                            search.leading ??
                            b ??
                            const Icon(Icons.search_rounded),
                        hintText: search.hintText ?? l10n.searchHint,
                        trailing: [
                          ...?search.trailingItems,
                          if (search.filterWidget != null) search.filterWidget!,
                          if (settingsButton != null) settingsButton!,
                        ],
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                )
              : SearchBar(
                  onTap: search.onPressed == null
                      ? null
                      : () => search.onPressed!(context),
                  elevation: const WidgetStatePropertyAll(0),
                  onSubmitted: search.onSubmitted,
                  onChanged: search.onChanged,
                  focusNode: searchFocus,
                  onTapOutside: (_) => searchFocus.unfocus(),
                  controller: search.textEditingController,
                  leading:
                      search.leading ?? b ?? const Icon(Icons.search_rounded),
                  hintText: search.hintText ?? l10n.searchHint,
                  trailing: [
                    ...?search.trailingItems,
                    if (search.filterWidget != null) search.filterWidget!,
                    if (settingsButton != null) settingsButton!,
                  ],
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
        ),
        stretch: true,
        snap: true,
        floating: true,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        bottom: bottomWidget,
      ),
      RawAppBarType() => search.sliver(context, settingsButton, bottomWidget),
      NoShellAppBar() => const SliverPadding(padding: EdgeInsets.zero),
    };
  }
}

class AppBarDivider extends StatefulWidget {
  const AppBarDivider({super.key, required this.controller, this.child});

  final ScrollController controller;
  final Widget? child;

  @override
  State<AppBarDivider> createState() => _AppBarDividerState();
}

class _AppBarDividerState extends State<AppBarDivider>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  bool isOffsetZero = true;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(listener);

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    controller.dispose();

    super.dispose();
  }

  void listener() {
    final newOffsetZero = widget.controller.offset <= 60;
    if (newOffsetZero != isOffsetZero) {
      isOffsetZero = newOffsetZero;

      if (isOffsetZero) {
        controller.reverse();
      } else {
        controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.child != null) widget.child!,
        Animate(
          controller: controller,
          autoPlay: false,
          effects: const [FadeEffect(begin: 0, end: 1)],
          child: Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class SearchBarAutocompleteWrapper extends StatelessWidget {
  const SearchBarAutocompleteWrapper({
    super.key,
    required this.search,
    required this.child,
    required this.searchFocus,
  });

  final SearchBarAppBarType search;
  final FocusNode? searchFocus;
  final Widget Function(
    BuildContext,
    TextEditingController,
    FocusNode,
    void Function(),
  )
  child;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: search.textEditingController,
      focusNode: searchFocus,
      optionsBuilder: (textEditingValue) async {
        if (search.complete == null) {
          return [];
        }
        try {
          return (await autocompleteTag(
            textEditingValue.text,
            search.complete!,
          )).map((e) => e.tag);
        } catch (e) {
          return [];
        }
      },
      fieldViewBuilder: child,
      optionsViewBuilder:
          (
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

                      final tags = List<String>.from(
                        search.textEditingController!.text.split(" "),
                      );

                      if (tags.isNotEmpty) {
                        tags.removeLast();
                        tags.remove(elem);
                      }

                      tags.add(elem);

                      onSelected(tags.join(" "));
                      search.onChanged?.call(
                        search.textEditingController!.text,
                      );
                    },
                    title: Text(elem),
                  ),
                )
                .toList();

            final theme = Theme.of(context);

            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Material(
                  color: theme.colorScheme.surface,
                  surfaceTintColor: theme.colorScheme.surfaceTint,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(25),
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tiles.length,
                      itemBuilder: (context, index) {
                        return Builder(
                          builder: (context) {
                            final highlight =
                                AutocompleteHighlightedOption.of(context) ==
                                index;
                            if (highlight) {
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
              ),
            );
          },
    );
  }
}
