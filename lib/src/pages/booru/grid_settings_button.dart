// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/radio_dialog.dart';

class GridSettingsButton extends StatelessWidget {
  final GridSettingsBase gridSettings;
  final void Function(GridAspectRatio?)? selectRatio;
  final void Function(bool)? selectHideName;
  final void Function(bool)? selectListView;
  final void Function(GridColumn?) selectGridColumn;
  final SafeMode? safeMode;
  final void Function(SafeMode?)? selectSafeMode;

  const GridSettingsButton(this.gridSettings,
      {super.key,
      required this.selectRatio,
      required this.selectHideName,
      required this.selectListView,
      required this.selectGridColumn,
      this.safeMode,
      this.selectSafeMode});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_horiz_outlined),
      itemBuilder: (context) => [
        if (safeMode != null)
          _safeMode(context, safeMode!, selectSafeMode: selectSafeMode),
        if (selectListView != null)
          _listView(gridSettings.listView, selectListView!),
        if (selectHideName != null)
          _hideName(context, gridSettings.hideName, selectHideName!),
        if (selectRatio != null)
          _ratio(context, gridSettings.aspectRatio, selectRatio!),
        _columns(context, gridSettings.columns, selectGridColumn)
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
        ? "Show names" // TODO: change
        : "Hide names"),
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
    child: const Text("Columns"), // TODO: change
    onTap: () => radioDialog(
      context,
      GridColumn.values.map((e) => (e, e.number.toString())).toList(),
      columns,
      select,
      title: AppLocalizations.of(context)!.nPerElementsSetting,
    ),
  );
}

PopupMenuItem _listView(bool listView, void Function(bool) select) {
  return PopupMenuItem(
    child: Text(listView
        ? "Grid view" // TODO: change
        : "List view"),
    onTap: () => select(!listView),
  );
}
