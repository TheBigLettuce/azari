// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/autocomplete_widget.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

class ShellSettingsButton extends StatelessWidget {
  const ShellSettingsButton({
    required this.add,
    required this.watch,
    this.header,
    this.buildHideName = true,
    required this.localizeHideNames,
  });

  factory ShellSettingsButton.fromWatchable(
    GridSettingsData w, {
    Widget? header,
    required String Function(BuildContext) localizeHideNames,
    bool buildHideName = true,
  }) => ShellSettingsButton(
    add: (d) => w.current = d,
    watch: w.watch,
    header: header,
    buildHideName: buildHideName,
    localizeHideNames: localizeHideNames,
  );

  static Widget onlyHeader(Widget header, [ButtonStyle? style]) =>
      _Header(header: header, style: style);

  final void Function(ShellConfigurationData) add;

  final StreamSubscription<ShellConfigurationData> Function(
    void Function(ShellConfigurationData) f, [
    bool fire,
  ])
  watch;

  final String Function(BuildContext) localizeHideNames;

  final bool buildHideName;

  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
          isScrollControlled: true,
          showDragHandle: true,
          useRootNavigator: true,
          builder: (context) {
            return SafeArea(
              child: _BottomSheetContent(
                add: add,
                watch: watch,
                buildHideName: buildHideName,
                header: header,
                localizeHideNames: localizeHideNames,
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.more_horiz_outlined),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    // super.key,
    required this.header,
    required this.style,
  });

  final Widget header;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      style: style,
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
          isScrollControlled: true,
          showDragHandle: true,
          useRootNavigator: true,
          builder: (context) {
            return SafeArea(
              child: _BottomSheetContent(
                add: null,
                watch: null,
                buildHideName: false,
                header: header,
                localizeHideNames: (_) => "",
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
    this.iconColor,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
}

enum SegmentedButtonVariant { chip, segments }

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
    this.showSelectedIcon = true,
    this.reorder = true,
    this.onLongPress,
  });

  final bool allowUnselect;
  final bool enableFilter;
  final bool showSelectedIcon;
  final bool reorder;

  final String title;

  final T? selected;

  final Iterable<SegmentedButtonValue<T>> values;

  final SegmentedButtonVariant variant;

  final void Function(T?) select;
  final void Function(T)? onLongPress;

  @override
  State<SegmentedButtonGroup<T>> createState() => _SegmentedButtonGroupState();
}

class _SegmentedButtonGroupState<T> extends State<SegmentedButtonGroup<T>> {
  final itemScrollController = ItemScrollController();
  final itemPositionListener = ItemPositionsListener.create();
  final controller = ScrollController();
  final searchFocus = FocusNode();
  final textController = TextEditingController();

  final List<SegmentedButtonValue<T>> _filter = [];

  @override
  void initState() {
    super.initState();

    if (!widget.reorder && widget.variant == SegmentedButtonVariant.chip) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        final newValues =
            textController.text.isNotEmpty ? _filter : widget.values.toList()
              ..sort((e1, e2) {
                return e1.label.compareTo(e2.label);
              });

        final idx = newValues.indexWhere((e) => e.value == widget.selected);

        if (idx < 0 || idx == 0) {
          return;
        }

        final positions = itemPositionListener.itemPositions.value.toList();

        final isVisisble =
            positions.indexWhere(
              (e) =>
                  e.index == idx &&
                  !e.itemLeadingEdge.isNegative &&
                  e.itemTrailingEdge < 1,
            ) !=
            -1;

        if (!isVisisble) {
          itemScrollController.scrollTo(
            alignment: 0.5,
            index: idx,
            duration: Durations.extralong1,
            curve: Easing.standard,
          );
        }
      });
    }
  }

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

    if (widget.reorder) {
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Easing.standard,
        );
      } else {
        itemScrollController.scrollTo(
          alignment: 0.5,
          index: 0,
          duration: Durations.medium3,
          curve: Easing.standard,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = context.l10n();

    final newValues =
        textController.text.isNotEmpty ? _filter : widget.values.toList()
          ..sort((e1, e2) {
            return e1.label.compareTo(e2.label);
          });
    if (widget.reorder) {
      final selectedSegment = newValues.indexWhere(
        (element) => element.value == widget.selected,
      );
      if (selectedSegment != -1) {
        final s = newValues.removeAt(selectedSegment);
        newValues.insert(0, s);
      }
    }

    final child = newValues.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                l10n.emptyValue,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        : switch (widget.variant) {
            SegmentedButtonVariant.segments => SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          icon: e.icon != null
                              ? Icon(e.icon, color: e.iconColor)
                              : null,
                        ),
                      )
                      .toList(),
                  showSelectedIcon: widget.showSelectedIcon,
                  selected: widget.selected != null
                      ? {widget.selected as T}
                      : {},
                ),
              ),
            ),
            SegmentedButtonVariant.chip => SizedBox(
              height: 40,
              child: ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionListener,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: newValues.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final e = newValues[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == newValues.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onLongPress: widget.onLongPress == null
                          ? null
                          : () => widget.onLongPress!(e.value),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: e.value == widget.selected,
                        avatar: e.icon != null
                            ? Icon(e.icon, color: e.iconColor)
                            : null,
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
                    ),
                  );
                },
              ),
            ),
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
              top: 4,
              left: 12,
              right: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(widget.title, style: theme.textTheme.bodyLarge),
                ),
                if (widget.enableFilter)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FocusNotifier(
                        notifier: searchFocus,
                        child: AutocompleteSearchBar(
                          searchTextOverride: l10n.filterHint,
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
                                  (element) =>
                                      element.label.toLowerCase().contains(t),
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
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: widget.variant == SegmentedButtonVariant.chip
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: child,
          ),
        ],
      ),
    );
  }
}

class SafeModeState {
  SafeModeState(this._current);

  final _events = StreamController<void>.broadcast();

  SafeMode _current;
  SafeMode get current => _current;

  Stream<void> get events => _events.stream;

  void setCurrent(SafeMode safeMode) {
    _current = safeMode;
    _events.add(null);
  }

  void dispose() {
    _events.close();
  }
}

class SafeModeSegment extends StatefulWidget {
  const SafeModeSegment({super.key, required this.state});

  final SafeModeState state;

  @override
  State<SafeModeSegment> createState() => _SafeModeSegmentState();
}

class _SafeModeSegmentState extends State<SafeModeSegment> {
  SafeModeState get state => widget.state;

  late final StreamSubscription<void> _events;

  @override
  void initState() {
    super.initState();

    _events = widget.state.events.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SegmentedButtonGroup<SafeMode>(
      select: (e) {
        if (e != null) {
          state.setCurrent(e);
        }
      },
      selected: state.current,
      reorder: false,
      values: SafeMode.values.map(
        (e) => SegmentedButtonValue(
          e,
          e.translatedString(l10n),
          icon: switch (e) {
            SafeMode.normal => Icons.no_adult_content_outlined,
            SafeMode.relaxed => Icons.visibility_outlined,
            SafeMode.none => Icons.explicit_outlined,
            SafeMode.explicit => Icons.eighteen_up_rating_outlined,
          },
        ),
      ),
      title: l10n.safeModeSetting,
      variant: SegmentedButtonVariant.chip,
    );
  }
}

class SafeModeButton extends StatefulWidget {
  const SafeModeButton({super.key, this.settingsWatcher, this.secondaryGrid})
    : assert(settingsWatcher == null || secondaryGrid == null);

  final WatchFire<SettingsData?>? settingsWatcher;
  final SecondaryGridHandle? secondaryGrid;

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

    settingsWatcher = widget.settingsWatcher?.call((s) {
      _settings = s;

      setState(() {});
    }, true);

    stateWatcher = widget.secondaryGrid?.watch((s) {
      _stateSettings = s;

      setState(() {});
    }, true);
  }

  @override
  void dispose() {
    settingsWatcher?.cancel();
    stateWatcher?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SegmentedButtonGroup<SafeMode>(
      select: (e) {
        _settings?.copy(safeMode: e).save();
        _stateSettings?.copy(safeMode: e).saveSecondary(widget.secondaryGrid!);
      },
      selected: _settings?.safeMode ?? _stateSettings?.safeMode,
      reorder: false,
      values: SafeMode.values.map(
        (e) => SegmentedButtonValue(
          e,
          e.translatedString(l10n),
          icon: switch (e) {
            SafeMode.normal => Icons.no_adult_content_outlined,
            SafeMode.relaxed => Icons.visibility_outlined,
            SafeMode.none => Icons.explicit_outlined,
            SafeMode.explicit => Icons.eighteen_up_rating_outlined,
          },
        ),
      ),
      title: l10n.safeModeSetting,
      variant: SegmentedButtonVariant.chip,
    );
  }
}

class _BottomSheetContent extends StatefulWidget {
  const _BottomSheetContent({
    required this.add,
    required this.watch,
    required this.header,
    required this.buildHideName,
    required this.localizeHideNames,
  });

  final bool buildHideName;

  final Widget? header;

  final void Function(ShellConfigurationData)? add;
  final String Function(BuildContext) localizeHideNames;

  final StreamSubscription<ShellConfigurationData> Function(
    void Function(ShellConfigurationData) f, [
    bool fire,
  ])?
  watch;

  @override
  State<_BottomSheetContent> createState() => __BottomSheetContentState();
}

class __BottomSheetContentState extends State<_BottomSheetContent> {
  void Function(ShellConfigurationData)? get add => widget.add;

  late final StreamSubscription<ShellConfigurationData>? watcher;

  ShellConfigurationData? _gridSettings;

  @override
  void initState() {
    super.initState();

    watcher = widget.watch?.call((newSettings) {
      _gridSettings = newSettings;

      setState(() {});
    }, true);
  }

  @override
  void dispose() {
    watcher?.cancel();

    super.dispose();
  }

  Widget _ratio(
    BuildContext context,
    GridAspectRatio aspectRatio,
    void Function(GridAspectRatio?) select,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
              top: 4,
              left: 12,
              right: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.aspectRatio,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Slider(
              value: aspectRatio.index.toDouble(),
              max: GridAspectRatio.values.length.toDouble() - 1,
              divisions: GridAspectRatio.values.length - 1,
              label: GridAspectRatio.fromIndex(
                aspectRatio.index,
              ).value.toString(),
              semanticFormatterCallback: (value) =>
                  GridAspectRatio.fromIndex(value.toInt()).value.toString(),
              onChanged: (val) {
                select(GridAspectRatio.fromIndex(val.toInt()));
                // value = val;

                // setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _columns(
    BuildContext context,
    GridColumn columns,
    void Function(GridColumn?) select,
    AppLocalizations l10n,
  ) {
    // return SegmentedButtonGroup(
    //   variant: SegmentedButtonVariant.segments,
    //   select: select,
    //   selected: columns,
    //   values: GridColumn.values
    //       .map((e) => SegmentedButtonValue(e, e.number.toString())),
    //   title: l10n.gridColumns,
    // );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
              top: 4,
              left: 12,
              right: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.gridColumns,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Slider(
              value: columns.index.toDouble(),
              max: GridColumn.values.length.toDouble() - 1,
              divisions: GridColumn.values.length - 1,
              label: GridColumn.fromIndex(columns.index).number.toString(),
              semanticFormatterCallback: (value) =>
                  GridColumn.fromIndex(value.toInt()).number.toString(),
              onChanged: (val) {
                select(GridColumn.fromIndex(val.toInt()));
              },
            ),
          ),
        ],
      ),
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
      showSelectedIcon: false,
      selected: selectGridLayout,
      values: GridLayoutType.values.map(
        (e) => SegmentedButtonValue(
          e,
          e.translatedString(l10n),
          icon: switch (e) {
            GridLayoutType.grid =>
              e == selectGridLayout
                  ? Icons.grid_view_rounded
                  : Icons.grid_view_outlined,
            GridLayoutType.list =>
              e == selectGridLayout
                  ? Icons.view_list_rounded
                  : Icons.view_list_outlined,
            GridLayoutType.gridQuilted =>
              e == selectGridLayout
                  ? Icons.view_quilt_rounded
                  : Icons.view_quilt_outlined,
            // GridLayoutType.gridMasonry => e == selectGridLayout
            //     ? Icons.grid_view_rounded
            //     : Icons.grid_view_outlined,
          },
        ),
      ),
      title: l10n.layoutLabel,
    );
  }

  Widget _hideName(
    BuildContext context,
    bool hideName,
    void Function(bool) select,
    EdgeInsets contentPadding,
    AppLocalizations l10n,
  ) {
    return SwitchListTile(
      contentPadding: contentPadding,
      title: Text(widget.localizeHideNames(context)),
      value: hideName,
      onChanged: (_) => select(!hideName),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gridSettings == null && widget.watch != null) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Theme.of(context);
    final l10n = context.l10n();

    return SizedBox(
      width: double.infinity,
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
            if (widget.add != null) ...[
              if (widget.buildHideName)
                _hideName(
                  context,
                  _gridSettings!.hideName,
                  (n) => add!(_gridSettings!.copy(hideName: n)),
                  const EdgeInsets.symmetric(horizontal: 12),
                  l10n,
                ),
              if (widget.header != null) widget.header!,
              _gridLayout(
                context,
                _gridSettings!.layoutType,
                (t) => add!(_gridSettings!.copy(layoutType: t)),
                l10n,
              ),
              _ratio(
                context,
                _gridSettings!.aspectRatio,
                (r) => add!(_gridSettings!.copy(aspectRatio: r)),
                l10n,
              ),
              _columns(
                context,
                _gridSettings!.columns,
                (c) => add!(_gridSettings!.copy(columns: c)),
                l10n,
              ),
            ] else if (widget.header != null)
              widget.header!,
            const Padding(padding: EdgeInsets.only(bottom: 8)),
          ],
        ),
      ),
    );
  }
}
