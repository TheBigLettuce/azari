// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';

abstract class GridLayoutBehaviour {
  const GridLayoutBehaviour();

  GridSettingsBase Function() get defaultSettings;

  GridLayouter<T> makeFor<T extends CellBase>(GridSettingsBase settings);
}

class GridSettingsLayoutBehaviour implements GridLayoutBehaviour {
  const GridSettingsLayoutBehaviour(this.defaultSettings);

  @override
  final GridSettingsBase Function() defaultSettings;

  @override
  GridLayouter<T> makeFor<T extends CellBase>(GridSettingsBase settings) =>
      settings.layoutType.layout();
}
