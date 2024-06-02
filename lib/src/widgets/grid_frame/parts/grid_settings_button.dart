// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/notifiers/focus.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart";

class GridSettingsButton extends StatelessWidget {
  const GridSettingsButton({
    required this.add,
    required this.watch,
    this.header,
  });

  factory GridSettingsButton.fromWatchable(
    WatchableGridSettingsData w, [
    Widget? header,
  ]) =>
      GridSettingsButton(
        add: (d) => w.current = d,
        watch: w.watch,
        header: header,
      );

  final void Function(GridSettingsData) add;

  final StreamSubscription<GridSettingsData>
      Function(void Function(GridSettingsData) f, [bool fire]) watch;

  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          isScrollControlled: true,
          showDragHandle: true,
          useRootNavigator: true,
          builder: (context) {
            return SafeArea(
              child: _BottomSheetContent(
                add: add,
                watch: watch,
                header: header,
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.more_horiz_outlined),
    );
  }
}

class SegmentedButtonValue<T> {
  const SegmentedButtonValue(
    this.value,
    this.label, {
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

enum SegmentedButtonVariant {
  chip,
  segments;
}

class SegmentedButtonGroup<T> extends StatefulWidget {
  const SegmentedButtonGroup({
    super.key,
    required this.select,
    required this.selected,
    required this.values,
    required this.title,
    required this.variant,
    this.allowUnselect = false,
    this.enableFilter = false,
  });

  final Iterable<SegmentedButtonValue<T>> values;
  final T? selected;
  final void Function(T?) select;
  final String title;
  final bool allowUnselect;
  final bool enableFilter;

  final SegmentedButtonVariant variant;

  @override
  State<SegmentedButtonGroup<T>> createState() => _SegmentedButtonGroupState();
}

class _SegmentedButtonGroupState<T> extends State<SegmentedButtonGroup<T>> {
  final controller = ScrollController();
  final searchFocus = FocusNode();
  final textController = TextEditingController();

  final List<SegmentedButtonValue<T>> _filter = [];

  @override
  void dispose() {
    controller.dispose();
    searchFocus.dispose();
    textController.dispose();

    super.dispose();
  }

  void select(Set<T> selection) {
    if (widget.allowUnselect && selection.isEmpty) {
      widget.select(null);

      return;
    }

    widget.select(selection.first);

    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Easing.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final newValues =
        textController.text.isNotEmpty ? _filter : widget.values.toList()
          ..sort((e1, e2) {
            return e1.label.compareTo(e2.label);
          });
    final selectedSegment =
        newValues.indexWhere((element) => element.value == widget.selected);
    if (selectedSegment != -1) {
      final s = newValues.removeAt(selectedSegment);
      newValues.insert(0, s);
    }

    final child = newValues.isEmpty
        ? const EmptyWidget(gridSeed: 0, mini: true)
        : switch (widget.variant) {
            SegmentedButtonVariant.segments => SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SegmentedButton<T>(
                    emptySelectionAllowed:
                        widget.selected == null || widget.allowUnselect,
                    onSelectionChanged:
                        newValues.length == 1 && !widget.allowUnselect
                            ? null
                            : select,
                    segments: newValues
                        .map(
                          (e) => ButtonSegment(
                            value: e.value,
                            label: Text(e.label),
                            icon: e.icon != null ? Icon(e.icon) : null,
                          ),
                        )
                        .toList(),
                    selected:
                        widget.selected != null ? {widget.selected as T} : {},
                  ),
                ),
              ),
            SegmentedButtonVariant.chip => SizedBox(
                height: 40,
                child: ListView.builder(
                  controller: controller,
                  shrinkWrap: true,
                  itemCount: newValues.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final e = newValues[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == newValues.length - 1 ? 8 : 4,
                      ),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: e.value == widget.selected,
                        avatar: e.icon != null ? Icon(e.icon) : null,
                        label: Text(e.label),
                        onSelected:
                            newValues.length == 1 && !widget.allowUnselect
                                ? null
                                : (_) {
                                    if (e.value == widget.selected) {
                                      if (!widget.allowUnselect) {
                                        return;
                                      }

                                      select({});
                                      return;
                                    }

                                    select({e.value});
                                  },
                      ),
                    );
                  },
                ),
              ),
          };

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (widget.enableFilter)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FocusNotifier(
                        notifier: searchFocus,
                        child: Builder(
                          builder: (context) {
                            return AutocompleteSearchBar(
                              searchTextOverride:
                                  AppLocalizations.of(context)!.filterHint,
                              focusNode: searchFocus,
                              addItems: const [],
                              textController: textController,
                              onChanged: () {
                                if (textController.text.isEmpty) {
                                  _filter.clear();
                                } else {
                                  final t = textController.text.toLowerCase();

                                  _filter.clear();
                                  _filter.addAll(
                                    widget.values.where(
                                      (element) => element.label
                                          .toLowerCase()
                                          .contains(t),
                                    ),
                                  );
                                }

                                setState(() {});
                              },
                              onSubmit: (s) {},
                              swapSearchIcon: false,
                              disable: false,
                              darkenColors: true,
                              maxWidth: 200,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: child,
          ),
        ],
      ),
    );
  }
}

class SafeModeButton extends StatefulWidget {
  const SafeModeButton({
    super.key,
    this.settingsWatcher,
    this.secondaryGrid,
  }) : assert(settingsWatcher == null || secondaryGrid == null);

  final WatchFire<SettingsData?>? settingsWatcher;
  final SecondaryGridService? secondaryGrid;

  @override
  State<SafeModeButton> createState() => _SafeModeButtonState();
}

class _SafeModeButtonState extends State<SafeModeButton> {
  late final StreamSubscription<SettingsData?>? settingsWatcher;
  late final StreamSubscription<GridState>? stateWatcher;

  SettingsData? _settings;
  GridState? _stateSettings;

  @override
  void initState() {
    super.initState();

    settingsWatcher = widget.settingsWatcher?.call(
      (s) {
        _settings = s;

        setState(() {});
      },
      true,
    );

    stateWatcher = widget.secondaryGrid?.watch(
      (s) {
        _stateSettings = s;

        setState(() {});
      },
      true,
    );
  }

  @override
  void dispose() {
    settingsWatcher?.cancel();
    stateWatcher?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButtonGroup<SafeMode>(
      select: (e) {
        _settings?.copy(safeMode: e).save();
        _stateSettings?.copy(safeMode: e).saveSecondary(widget.secondaryGrid!);
      },
      selected: _settings?.safeMode ?? _stateSettings?.safeMode,
      values: SafeMode.values
          .map((e) => SegmentedButtonValue(e, e.translatedString(l10n))),
      title: l10n.safeModeSetting,
      variant: SegmentedButtonVariant.segments,
    )

        // TextButton(
        // child: Text(),
        //   onPressed: () => radioDialog<SafeMode>(
        //     context,
        //     SafeMode.values.map((e) => (e, e.translatedString(l8n))),
        //     safeMode,
        //     (value) {
        //       (selectSafeMode ??
        //           (value) {
        //             SettingsService.db().current.copy(safeMode: value).save();
        //           })(value);

        //       Navigator.pop(context);
        //     },
        //     title: l8n.safeModeSetting,
        //   ),
        // )
        ;
  }
}

class _BottomSheetContent extends StatefulWidget {
  const _BottomSheetContent({
    required this.add,
    required this.watch,
    required this.header,
  });

  final void Function(GridSettingsData) add;

  final Widget? header;

  final StreamSubscription<GridSettingsData>
      Function(void Function(GridSettingsData) f, [bool fire]) watch;

  @override
  State<_BottomSheetContent> createState() => __BottomSheetContentState();
}

class __BottomSheetContentState extends State<_BottomSheetContent> {
  void Function(GridSettingsData) get add => widget.add;

  late final StreamSubscription<GridSettingsData> watcher;

  GridSettingsData? _gridSettings;

  @override
  void initState() {
    super.initState();

    watcher = widget.watch(
      (newSettings) {
        _gridSettings = newSettings;

        setState(() {});
      },
      true,
    );
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  Widget _ratio(
    BuildContext context,
    GridAspectRatio aspectRatio,
    void Function(GridAspectRatio?) select,
    AppLocalizations l10n,
  ) {
    return SegmentedButtonGroup(
      variant: SegmentedButtonVariant.segments,
      select: select,
      selected: aspectRatio,
      values: GridAspectRatio.values
          .map((e) => SegmentedButtonValue(e, e.value.toString())),
      title: l10n.aspectRatio,
    );
  }

  Widget _columns(
    BuildContext context,
    GridColumn columns,
    void Function(GridColumn?) select,
    AppLocalizations l10n,
  ) {
    return SegmentedButtonGroup(
      variant: SegmentedButtonVariant.segments,
      select: select,
      selected: columns,
      values: GridColumn.values
          .map((e) => SegmentedButtonValue(e, e.number.toString())),
      title: l10n.gridColumns,
    );
  }

  Widget _gridLayout(
    BuildContext context,
    GridLayoutType selectGridLayout,
    void Function(GridLayoutType?) select,
    AppLocalizations l10n,
  ) {
    return SegmentedButtonGroup(
      variant: SegmentedButtonVariant.segments,
      select: select,
      selected: selectGridLayout,
      values: GridLayoutType.values
          .map((e) => SegmentedButtonValue(e, e.translatedString(l10n))),
      title: l10n.layoutLabel,
    );
  }

  Widget _hideName(
    BuildContext context,
    bool hideName,
    void Function(bool) select,
    AppLocalizations l10n,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.hideNames),
      value: hideName,
      onChanged: (_) => select(!hideName),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gridSettings == null) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  l10n.settingsLabel,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (widget.header != null) widget.header!,
              _hideName(
                context,
                _gridSettings!.hideName,
                (n) => add(_gridSettings!.copy(hideName: n)),
                l10n,
              ),
              _gridLayout(
                context,
                _gridSettings!.layoutType,
                (t) => add(_gridSettings!.copy(layoutType: t)),
                l10n,
              ),
              _ratio(
                context,
                _gridSettings!.aspectRatio,
                (r) => add(_gridSettings!.copy(aspectRatio: r)),
                l10n,
              ),
              _columns(
                context,
                _gridSettings!.columns,
                (c) => add(_gridSettings!.copy(columns: c)),
                l10n,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 8)),
            ],
          ),
        ),
      ),
    );
  }
}
