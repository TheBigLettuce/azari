// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

sealed class ShellAppBarType {
  const ShellAppBarType({
    required this.leading,
    required this.trailingItems,
    this.bottomWidget,
  });

  final Widget? leading;
  final List<Widget>? trailingItems;
  final PreferredSizeWidget? bottomWidget;
}

class TitleAppBarType extends ShellAppBarType {
  const TitleAppBarType({
    required this.title,
    super.leading,
    super.trailingItems,
    super.bottomWidget,
  });

  final String title;
}

class RawAppBarType implements ShellAppBarType {
  const RawAppBarType(this.sliver);

  @override
  Widget? get leading => null;

  @override
  List<Widget>? get trailingItems => null;

  @override
  PreferredSizeWidget? get bottomWidget => null;

  final Widget Function(
    BuildContext context,
    Widget? gridSettingsButton,
    PreferredSizeWidget? bottomWidget,
  ) sliver;
}

class NoShellAppBar extends ShellAppBarType {
  const NoShellAppBar()
      : super(leading: null, trailingItems: null, bottomWidget: null);
}

class SearchBarAppBarType extends ShellAppBarType {
  const SearchBarAppBarType({
    this.onSubmitted,
    this.textEditingController,
    required this.onChanged,
    this.complete,
    this.filterWidget,
    this.hintText,
    super.leading,
    super.trailingItems,
    super.bottomWidget,
    this.enableCount = false,
    this.filterFocus,
    this.onPressed,
  });

  factory SearchBarAppBarType.fromFilter(
    ChainedFilterResourceSource<dynamic, dynamic> filter, {
    required TextEditingController textEditingController,
    required FocusNode focus,
    String? hintText,
    Future<List<BooruTag>> Function(String string)? complete,
    Widget? leading,
    List<Widget>? trailingItems,
    void Function(BuildContext context)? onPressed,
    PreferredSizeWidget? bottomWidget,
  }) {
    return SearchBarAppBarType(
      textEditingController: textEditingController,
      hintText: hintText,
      complete: complete,
      leading: leading,
      enableCount: true,
      filterFocus: focus,
      trailingItems: trailingItems,
      onPressed: onPressed,
      bottomWidget: bottomWidget,
      onChanged: (str) => filter.clearRefresh(),
      filterWidget: filter.allowedFilteringModes.isNotEmpty
          ? ChainedFilterIcon(
              filter: filter,
              controller: textEditingController,
              focusNode: focus,
            )
          : null,
    );
  }

  final bool enableCount;

  final String? hintText;

  final TextEditingController? textEditingController;
  final Widget? filterWidget;

  final ContextCallback? onPressed;
  final FocusNode? filterFocus;

  final Future<List<BooruTag>> Function(String string)? complete;
  final void Function(String? str)? onChanged;
  final void Function(String? str)? onSubmitted;
}

class ChainedFilterIcon extends StatelessWidget {
  const ChainedFilterIcon({
    super.key,
    required this.filter,
    required this.controller,
    required this.focusNode,
    // this.onChange,
    this.complete,
  });

  final ChainedFilterResourceSource<dynamic, dynamic> filter;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<List<BooruTag>> Function(String string)? complete;
  // final void Function(String?)? onChange;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet<void>(
          useRootNavigator: true,
          isScrollControlled: true,
          showDragHandle: true,
          context: context,
          builder: (context) {
            return SafeArea(
              child: _FilteringWidget(
                complete: complete,
                selectSorting: (e) => filter.sortingMode = e,
                currentSorting: filter.sortingMode,
                enabledSorting: filter.allowedSortingModes,
                select: (e) => filter.filteringMode = e,
                currentFilter: filter.filteringMode,
                enabledModes: filter.allowedFilteringModes,
                // onChange: onChange,
                onChange: null,
                controller: controller,
                focusNode: focusNode,
              ),
            );
          },
        );
      },
      icon: _FilterIcon(filter: filter),
      padding: EdgeInsets.zero,
    );
  }
}

class _FilterIcon extends StatefulWidget {
  const _FilterIcon({
    // super.key,
    required this.filter,
  });

  final ChainedFilterResourceSource<dynamic, dynamic> filter;

  @override
  State<_FilterIcon> createState() => __FilterIconState();
}

class __FilterIconState extends State<_FilterIcon>
    with SingleTickerProviderStateMixin {
  late FilteringMode filteringMode = widget.filter.filteringMode;

  late final StreamSubscription<void> subscr;
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);

    subscr = widget.filter.watchFilter((f) {
      if (filteringMode != f.filteringMode) {
        controller.reverse().then((_) {
          filteringMode = f.filteringMode;

          setState(() {});

          controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      controller: controller,
      effects: const [
        SlideEffect(
          duration: Durations.short4,
          curve: Easing.emphasizedDecelerate,
          begin: Offset(-1, 0),
          end: Offset.zero,
        ),
        FadeEffect(
          delay: Durations.short1,
          duration: Durations.short4,
          curve: Easing.standard,
          begin: 0,
          end: 1,
        ),
      ],
      child: Icon(filteringMode.icon),
    );
  }
}

class _FilteringWidget extends StatefulWidget {
  const _FilteringWidget({
    required this.currentFilter,
    required this.enabledModes,
    required this.select,
    required this.currentSorting,
    required this.enabledSorting,
    required this.selectSorting,
    required this.onChange,
    required this.controller,
    required this.complete,
    required this.focusNode,
  });

  final void Function(String?)? onChange;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FilteringMode currentFilter;
  final SortingMode currentSorting;
  final Set<FilteringMode> enabledModes;
  final Set<SortingMode> enabledSorting;
  final FilteringMode Function(FilteringMode) select;
  final void Function(SortingMode) selectSorting;
  final Future<List<BooruTag>> Function(String string)? complete;

  @override
  State<_FilteringWidget> createState() => __FilteringWidgetState();
}

class __FilteringWidgetState extends State<_FilteringWidget> {
  late FilteringMode currentFilter = widget.currentFilter;
  late SortingMode currentSorting = widget.currentSorting;

  void _selectFilter(FilteringMode? mode) {
    if (mode == null) {
      if (widget.enabledModes.contains(FilteringMode.noFilter)) {
        currentFilter = widget.select(FilteringMode.noFilter);

        setState(() {});
      }

      return;
    } else {
      currentFilter = widget.select(mode);

      setState(() {});
    }
  }

  void _selectSorting(SortingMode? sort) {
    if (sort != null) {
      currentSorting = sort;

      widget.selectSorting(sort);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.filteringLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.onChange != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: widget.complete != null
                    ? SearchBarAutocompleteWrapper(
                        search: SearchBarAppBarType(
                          onChanged: widget.onChange,
                          complete: widget.complete,
                          textEditingController: widget.controller,
                        ),
                        searchFocus: widget.focusNode,
                        child: (
                          context,
                          controller,
                          focus,
                          onSubmitted,
                        ) =>
                            SearchBar(
                          onSubmitted: (str) {
                            onSubmitted();
                            widget.onChange?.call(str);
                          },
                          elevation: const WidgetStatePropertyAll(0),
                          focusNode: focus,
                          controller: controller,
                          onChanged: widget.onChange,
                          hintText: l10n.filterHint,
                          leading: const Icon(Icons.search_rounded),
                          trailing: [
                            IconButton(
                              onPressed: () {
                                controller.text = "";
                                widget.onChange?.call("");
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      )
                    : SearchBar(
                        elevation: const WidgetStatePropertyAll(0),
                        controller: widget.controller,
                        onChanged: widget.onChange,
                        hintText: l10n.filterHint,
                        leading: const Icon(Icons.search_rounded),
                        trailing: [
                          IconButton(
                            onPressed: () {
                              widget.controller.text = "";
                              widget.onChange?.call("");
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
              ),
            SegmentedButtonGroup<FilteringMode>(
              variant: SegmentedButtonVariant.chip,
              select: _selectFilter,
              selected: currentFilter,
              allowUnselect: true,
              reorder: false,
              values: widget.enabledModes
                  .where((element) => element != FilteringMode.noFilter)
                  .map(
                    (e) => SegmentedButtonValue(
                      e,
                      e.translatedString(l10n),
                      icon: e.icon,
                    ),
                  ),
              title: l10n.filteringModesLabel,
            ),
            SegmentedButtonGroup<SortingMode>(
              variant: SegmentedButtonVariant.chip,
              select: _selectSorting,
              selected: currentSorting,
              showSelectedIcon: false,
              reorder: false,
              values: widget.enabledSorting.isEmpty
                  ? <SegmentedButtonValue<SortingMode>>[
                      SegmentedButtonValue(
                        currentSorting,
                        currentSorting.translatedString(l10n),
                      ),
                    ]
                  : widget.enabledSorting.map(
                      (e) => SegmentedButtonValue(
                        e,
                        e.translatedString(l10n),
                        icon: e.icons(currentSorting),
                      ),
                    ),
              title: l10n.sortingModesLabel,
            ),
            const Padding(padding: EdgeInsets.only(bottom: 8)),
          ],
        ),
      ),
    );
  }
}
