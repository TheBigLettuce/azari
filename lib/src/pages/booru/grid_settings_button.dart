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
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/more/settings/radio_dialog.dart';

class GridSettingsButton extends StatefulWidget {
  const GridSettingsButton(
    this.gridSettings, {
    super.key,
    required this.selectRatio,
    required this.selectHideName,
    required this.selectGridLayout,
    required this.selectGridColumn,
    this.watch,
    this.safeMode,
    this.selectSafeMode,
  });

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
  StreamSubscription<GridSettingsBase>? watcher;

  late GridSettingsBase gridSettings = widget.gridSettings();

  @override
  void initState() {
    super.initState();

    watcher = widget.watch?.call((newSettings) {
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
    return PopupMenuButton(
      icon: const Icon(Icons.more_horiz_outlined),
      itemBuilder: (context) => [
        if (widget.safeMode != null)
          _safeMode(context, widget.safeMode!,
              selectSafeMode: (s) => widget.selectSafeMode!(s, gridSettings)),
        if (widget.selectGridLayout != null)
          _gridLayout(context, gridSettings.layoutType,
              (t) => widget.selectGridLayout!(t, gridSettings)),
        if (widget.selectHideName != null)
          _hideName(context, gridSettings.hideName,
              (n) => widget.selectHideName!(n, gridSettings)),
        if (widget.selectRatio != null)
          _ratio(context, gridSettings.aspectRatio,
              (r) => widget.selectRatio!(r, gridSettings)),
        _columns(context, gridSettings.columns,
            (c) => widget.selectGridColumn(c, gridSettings))
      ],
    );
  }
}

PopupMenuItem _safeMode(BuildContext context, SafeMode safeMode,
    {void Function(SafeMode?)? selectSafeMode}) {
  return PopupMenuItem(
    child: Text(AppLocalizations.of(context)!.safeModeSetting),
    onTap: () => radioDialog<SafeMode>(
      context,
      SafeMode.values.map((e) => (e, e.string)),
      safeMode,
      selectSafeMode ??
          (value) {
            Settings.fromDb().copy(safeMode: value).save();
          },
      title: AppLocalizations.of(context)!.safeModeSetting,
    ),
  );
}

PopupMenuItem _hideName(
    BuildContext context, bool hideName, void Function(bool) select) {
  return PopupMenuItem(
    child: Text(hideName
        ? AppLocalizations.of(context)!.showNames
        : AppLocalizations.of(context)!.hideNames),
    onTap: () => select(!hideName),
  );
}

PopupMenuItem _ratio(BuildContext context, GridAspectRatio aspectRatio,
    void Function(GridAspectRatio?) select) {
  return PopupMenuItem(
    child: Text(AppLocalizations.of(context)!.aspectRatio),
    onTap: () => radioDialog(
      context,
      GridAspectRatio.values.map((e) => (e, e.value.toString())).toList(),
      aspectRatio,
      select,
      title: AppLocalizations.of(context)!.aspectRatio,
    ),
  );
}

PopupMenuItem _columns(BuildContext context, GridColumn columns,
    void Function(GridColumn?) select) {
  return PopupMenuItem(
    child: Text(AppLocalizations.of(context)!.gridColumns),
    onTap: () => radioDialog(
      context,
      GridColumn.values.map((e) => (e, e.number.toString())).toList(),
      columns,
      select,
      title: AppLocalizations.of(context)!.nPerElementsSetting,
    ),
  );
}

PopupMenuItem _gridLayout(BuildContext context, GridLayoutType selectGridLayout,
    void Function(GridLayoutType?) select) {
  return PopupMenuItem(
    child: const Text("Layout"), // TODO: change
    onTap: () => radioDialog(
      context,
      GridLayoutType.values.map((e) => (e, e.text)),
      selectGridLayout,
      select,
      title: "Layout",
    ),
  );
}
