// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/more/settings/radio_dialog.dart';

class GridSettingsButton extends StatefulWidget {
  const GridSettingsButton(
    this.gridSettings, {
    super.key,
    required this.onChanged,
    required this.selectRatio,
    required this.selectHideName,
    required this.selectGridLayout,
    required this.selectGridColumn,
    this.watch,
    this.safeMode,
    this.selectSafeMode,
  });

  final void Function() onChanged;
  final GridSettingsBase Function() gridSettings;
  final void Function(GridAspectRatio?, GridSettingsBase)? selectRatio;
  final void Function(bool, GridSettingsBase)? selectHideName;
  final void Function(GridLayoutType?, GridSettingsBase)? selectGridLayout;
  final void Function(GridColumn?, GridSettingsBase) selectGridColumn;
  final SafeMode? safeMode;
  final void Function(SafeMode?, GridSettingsBase)? selectSafeMode;
  final StreamSubscription<GridSettingsBase> Function(
      void Function(GridSettingsBase) f)? watch;

  @override
  State<GridSettingsButton> createState() => _GridSettingsButtonState();
}

class _GridSettingsButtonState extends State<GridSettingsButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: false,
          useRootNavigator: true,
          builder: (context) {
            return SafeArea(
              child: _BottomSheetContent(button: widget),
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

class SegmentedButtonGroup<T> extends StatefulWidget {
  final Iterable<SegmentedButtonValue<T>> values;
  final T? selected;
  final void Function(T?) select;
  final String title;
  final bool allowUnselect;

  const SegmentedButtonGroup({
    super.key,
    required this.select,
    required this.selected,
    required this.values,
    required this.title,
    this.allowUnselect = false,
  });

  @override
  State<SegmentedButtonGroup<T>> createState() => _SegmentedButtonGroupState();
}

class _SegmentedButtonGroupState<T> extends State<SegmentedButtonGroup<T>> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();

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
    final newValues = widget.values.toList()
      ..sort((e1, e2) {
        return e1.label.compareTo(e2.label);
      });
    final selectedSegment =
        newValues.indexWhere((element) => element.value == widget.selected);
    if (selectedSegment != -1) {
      final s = newValues.removeAt(selectedSegment);
      newValues.insert(0, s);
    }

    final child = newValues.length <= 5
        ? SingleChildScrollView(
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
                selected: widget.selected != null ? {widget.selected as T} : {},
              ),
            ),
          )
        : SizedBox(
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
                      right: index == newValues.length - 1 ? 8 : 4),
                  child: ChoiceChip(
                    selected: e.value == widget.selected,
                    avatar: e.icon != null ? Icon(e.icon) : null,
                    label: Text(e.label),
                    onSelected: newValues.length == 1 && !widget.allowUnselect
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
          );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyLarge,
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

Widget _ratio(BuildContext context, GridAspectRatio aspectRatio,
    void Function(GridAspectRatio?) select) {
  return SegmentedButtonGroup(
    select: select,
    selected: aspectRatio,
    values: GridAspectRatio.values
        .map((e) => SegmentedButtonValue(e, e.value.toString())),
    title: AppLocalizations.of(context)!.aspectRatio,
  );
}

Widget _columns(BuildContext context, GridColumn columns,
    void Function(GridColumn?) select) {
  return SegmentedButtonGroup(
    select: select,
    selected: columns,
    values: GridColumn.values
        .map((e) => SegmentedButtonValue(e, e.number.toString())),
    title: AppLocalizations.of(context)!.gridColumns,
  );
}

Widget _gridLayout(BuildContext context, GridLayoutType selectGridLayout,
    void Function(GridLayoutType?) select) {
  return SegmentedButtonGroup(
    select: select,
    selected: selectGridLayout,
    values: GridLayoutType.values.map((e) => SegmentedButtonValue(e, e.text)),
    title: AppLocalizations.of(context)!.layoutLabel,
  );
}

Widget _safeMode(BuildContext context, SafeMode safeMode,
    {void Function(SafeMode?)? selectSafeMode}) {
  return TextButton(
    child: Text(AppLocalizations.of(context)!.safeModeSetting),
    onPressed: () => radioDialog<SafeMode>(
      context,
      SafeMode.values.map((e) => (e, e.translatedString(context))),
      safeMode,
      (value) {
        (selectSafeMode ??
            (value) {
              Settings.fromDb().copy(safeMode: value).save();
            })(value);

        Navigator.pop(context);
      },
      title: AppLocalizations.of(context)!.safeModeSetting,
    ),
  );
}

Widget _hideName(
    BuildContext context, bool hideName, void Function(bool) select) {
  return SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(AppLocalizations.of(context)!.hideNames),
    value: hideName,
    onChanged: (_) => select(!hideName),
  );
}

class _BottomSheetContent extends StatefulWidget {
  final GridSettingsButton button;

  const _BottomSheetContent({
    super.key,
    required this.button,
  });

  @override
  State<_BottomSheetContent> createState() => __BottomSheetContentState();
}

class __BottomSheetContentState extends State<_BottomSheetContent> {
  GridSettingsButton get button => widget.button;

  StreamSubscription<GridSettingsBase>? watcher;

  late GridSettingsBase gridSettings = button.gridSettings();

  @override
  void initState() {
    super.initState();

    watcher = button.watch?.call((newSettings) {
      gridSettings = newSettings;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                AppLocalizations.of(context)!.settingsLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (button.safeMode != null)
              _safeMode(context, button.safeMode!, selectSafeMode: (s) {
                button.selectSafeMode!(s, gridSettings);
                button.onChanged();
              }),
            if (button.selectHideName != null)
              _hideName(context, gridSettings.hideName, (n) {
                button.selectHideName!(n, gridSettings);
                button.onChanged();
              }),
            if (button.selectGridLayout != null)
              _gridLayout(context, gridSettings.layoutType, (t) {
                button.selectGridLayout!(t, gridSettings);
                button.onChanged();
              }),
            if (button.selectRatio != null)
              _ratio(context, gridSettings.aspectRatio, (r) {
                button.selectRatio!(r, gridSettings);
                button.onChanged();
              }),
            _columns(context, gridSettings.columns, (c) {
              button.selectGridColumn(c, gridSettings);
              button.onChanged();
            })
          ],
        ),
      ),
    );
  }
}
