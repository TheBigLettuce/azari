// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';

import 'contentable.dart';
import 'sticker.dart';

/// Cells on a grid.
/// Implementations of this interface can be presented on the [GridFrame].
/// This can be not only a cell on a grid, it can be also an element in a list.
/// [GridFrame] decides how this gets displayed.
abstract interface class CellBase {
  /// Const constructor to allow implementations to have const constructors.
  const CellBase();

  /// The name of the cell, displayed on top of the cell.
  /// If [long] is true, it means the cell gets displayed as a list entry,
  /// instead of a cell on a grid.
  String alias(bool long);

  CellStaticData description();

  Key uniqueKey();
}

@immutable
class CellStaticData {
  const CellStaticData({
    this.titleLines = 1,
    this.tightMode = false,
    this.ignoreSwipeSelectGesture = false,
    this.titleAtBottom = false,
    this.imageAlign = Alignment.center,
    this.circle = false,
    this.alignTitleToTopLeft = false,
  });

  /// [GridCell] is displayed in form as a beveled rectangle.
  /// If [circle] is true, then it's displayed as a circle instead.
  final bool circle;

  final bool ignoreSwipeSelectGesture;
  final bool titleAtBottom;
  final bool tightMode;
  final bool alignTitleToTopLeft;

  final int titleLines;

  final Alignment imageAlign;
}

abstract interface class IsarEntryId {
  /// Common pattern of the implementations of [Cell] is that they are all an Isar schema.
  /// However, this property can be ignored, together with the setter.
  /// This is only useful for the internal implementations, not used in the [GridFrame].
  /// No asumptions can be made about this property.
  int? get isarId;
  set isarId(int? i);
}

abstract interface class Pressable<T extends CellBase> {
  void onPress(BuildContext context, GridFunctionality<T> functionality, T cell,
      int idx);

  /// File that gets displayed in the image view.
  /// This can be unimplemented.
  /// Not implementing this assumes that clicking on the grid will take to an other page,
  /// requires [GridFrame.overrideOnPress] to be not null, which makes [fileDisplay] never to be called.
  // Contentable content();

  /// Additional information about the cell.
  /// This gets displayed in the "Info" list view, in the image view.
  // Widget? contentInfo(BuildContext context);

  /// Additional buttons which get diplayed in the image view's appbar.
  // List<Widget>? addButtons(BuildContext context);
}

abstract interface class Thumbnailable {
  ImageProvider thumbnail();
}

abstract interface class Stickerable {
  List<(IconData, void Function()?)>? addStickers(BuildContext context);

  List<Sticker> stickers(BuildContext context);
}

abstract interface class Downloadable {
  /// Url to the file to download.
  /// This can be unimplemented.
  /// Not implementing this assumes that clicking on the grid will take to an other page,
  /// requires [GridFrame.overrideOnPress] to be not null, which makes [fileDownloadUrl] never to be called.
  String? fileDownloadUrl();
}
