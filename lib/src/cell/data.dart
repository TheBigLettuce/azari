// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';

/// From this the actual grid cell as displayed on the screen gets built.
class CellData {
  /// The thumbnail image of the cell.
  final ImageProvider thumb;

  /// Displayed on top of the cell.
  final String name;

  /// Metadata of the post.
  /// Displayed on top of the cell, starting from the top left corner.
  final List<IconData> stickers;

  /// If this property set to false, and [CallbackGrid.loadThumbsDirectly] is set,
  /// the grid will attempt to load the thumbnail, by calling [CallbackGrid.loadThumbsDirectly].
  /// Cells should set this only if there is an particular logic of how the thumbnails get loaded.
  final bool? loaded;

  const CellData(
      {required this.thumb,
      required this.name,
      required this.stickers,
      this.loaded});
}
