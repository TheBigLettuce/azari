// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";

sealed class GridSearchWidget {
  const GridSearchWidget({required this.leading, required this.trailingItems});

  final Widget? leading;
  final List<Widget>? trailingItems;
}

class PageNameSearchWidget extends GridSearchWidget {
  const PageNameSearchWidget({
    super.leading,
    super.trailingItems,
  });
}

class RawSearchWidget implements GridSearchWidget {
  const RawSearchWidget(this.sliver);

  @override
  Widget? get leading => null;

  @override
  List<Widget>? get trailingItems => null;

  final Widget Function(
    Widget? gridSettingsButton,
    PreferredSizeWidget? bottomWidget,
  ) sliver;
}

class BarSearchWidget extends GridSearchWidget {
  const BarSearchWidget({
    this.textEditingController,
    required this.onChange,
    this.complete,
    this.filterWidget,
    this.hintText,
    super.leading,
    super.trailingItems,
    this.enableCount = false,
  });

  factory BarSearchWidget.fromFilter(
    ChainedFilterResourceSource<dynamic, dynamic> filter, {
    TextEditingController? textEditingController,
    String? hintText,
    Future<List<BooruTag>> Function(String string)? complete,
    Widget? leading,
    List<Widget>? trailingItems,
  }) {
    return BarSearchWidget(
      textEditingController: textEditingController,
      hintText: hintText,
      complete: complete,
      leading: leading,
      enableCount: true,
      trailingItems: trailingItems,
      onChange: (str) => filter.clearRefresh(),
      filterWidget: filter.allowedFilteringModes.isNotEmpty
          ? ChainedFilterIcon(filter: filter)
          : null,
    );
  }

  final TextEditingController? textEditingController;
  final Widget? filterWidget;
  final String? hintText;
  final bool enableCount;
  final Future<List<BooruTag>> Function(String string)? complete;
  final void Function(String? str)? onChange;
}

class ChainedFilterIcon extends StatelessWidget {
  const ChainedFilterIcon({
    super.key,
    required this.filter,
    this.controller,
    this.onChange,
    this.complete,
  });

  final ChainedFilterResourceSource<dynamic, dynamic> filter;
  final TextEditingController? controller;
  final Future<List<BooruTag>> Function(String string)? complete;
  final void Function(String?)? onChange;

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
                onChange: onChange,
                controller: controller,
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
      if (filteringMode != f) {
        controller.reverse().then((_) {
          filteringMode = f;

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
  });

  final void Function(String?)? onChange;
  final TextEditingController? controller;
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
    final l10n = AppLocalizations.of(context)!;

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
            if (widget.controller != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: widget.complete != null
                    ? SearchBarAutocompleteWrapper(
                        search: BarSearchWidget(
                          onChange: widget.onChange,
                          complete: widget.complete,
                          textEditingController: widget.controller,
                        ),
                        searchFocus: null,
                        child: (
                          context,
                          controller,
                          focus,
                          onSubmitted,
                        ) =>
                            SearchBar(
                          onSubmitted: (_) => onSubmitted(),
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
                        controller: widget.controller,
                        onChanged: widget.onChange,
                        hintText: l10n.filterHint,
                        leading: const Icon(Icons.search_rounded),
                        trailing: [
                          IconButton(
                            onPressed: () {
                              widget.controller!.text = "";
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
              variant: SegmentedButtonVariant.segments,
              select: _selectSorting,
              selected: currentSorting,
              values: widget.enabledSorting.isEmpty
                  ? [
                      SegmentedButtonValue(
                        currentSorting,
                        currentSorting.translatedString(l10n),
                      ),
                    ]
                  : widget.enabledSorting.map(
                      (e) => SegmentedButtonValue(e, e.translatedString(l10n)),
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
