// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/base/grid_settings_base.dart";
import "package:gallery/src/db/schemas/grid_settings/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";

class GridFrameSettingsButton {
  const GridFrameSettingsButton({
    required this.selectGridColumn,
    this.safeMode,
    this.selectSafeMode,
    this.selectGridLayout,
    this.selectHideName,
    this.selectRatio,
    this.overrideDefault,
    this.watchExplicitly,
  });

  final GridSettingsBase Function()? overrideDefault;
  final StreamSubscription<GridSettingsBase> Function(
    void Function(GridSettingsBase) f,
  )? watchExplicitly;
  final void Function(GridAspectRatio?, GridSettingsBase)? selectRatio;
  final void Function(bool, GridSettingsBase)? selectHideName;
  final void Function(GridLayoutType?, GridSettingsBase)? selectGridLayout;
  final void Function(GridColumn?, GridSettingsBase) selectGridColumn;
  final SafeMode? safeMode;
  final void Function(SafeMode?, GridSettingsBase)? selectSafeMode;
}
