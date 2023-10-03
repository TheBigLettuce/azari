// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/widgets/grid/sticker.dart';

/// From this the actual grid cell as displayed on the screen gets built.
class CellData {
  /// The thumbnail image of the cell.
  final ImageProvider? thumb;

  /// Displayed on top of the cell, at the bottom center.
  final String name;

  /// Metadata of the post.
  /// Displayed on top of the cell, starting from the top left corner.
  final List<Sticker> stickers;

  const CellData({
    required this.thumb,
    required this.name,
    required this.stickers,
  });
}
