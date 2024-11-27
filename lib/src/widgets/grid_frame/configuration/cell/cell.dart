// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";

extension CellsExt on CellBase {
  void Function()? tryAsPressable<T extends CellBase>(
    BuildContext context,
    GridFunctionality<T> functionality,
    int idx,
  ) {
    if (this is Pressable<T>) {
      return () => (this as Pressable<T>).onPress(context, functionality, idx);
    }

    return null;
  }

  List<Sticker>? tryAsStickerable(BuildContext context, bool excludeDuplicate) {
    if (this is Stickerable) {
      return (this as Stickerable).stickers(context, excludeDuplicate);
    }

    return null;
  }

  ImageProvider? tryAsThumbnailable() {
    if (this is Thumbnailable) {
      return (this as Thumbnailable).thumbnail();
    }

    return null;
  }

  SelectionWrapperBuilder? tryAsSelectionWrapperable() {
    if (this is SelectionWrapperBuilder) {
      return this as SelectionWrapperBuilder;
    }

    return null;
  }
}

/// Cells on a grid.
/// Implementations of this interface can be presented on the [GridFrame].
/// This can be not only a cell on a grid, it can be also an element in a list.
/// [GridFrame] decides how this gets displayed.
abstract interface class CellBase implements UniqueKeyable, Aliasable {
  /// Const constructor to allow implementations to have const constructors.
  const CellBase();

  CellStaticData description();

  Widget buildCell<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
    required Alignment imageAlign,
    required Widget Function(Widget child) wrapSelection,
  });
}

abstract interface class Aliasable {
  /// The name of the cell, displayed on top of the cell.
  /// If [long] is true, it means the cell gets displayed as a list entry,
  /// instead of a cell on a grid.
  String alias(bool long);
}

abstract interface class UniqueKeyable {
  Key uniqueKey();
}

abstract interface class SelectionWrapperBuilder {
  Widget buildSelectionWrapper<T extends CellBase>({
    required int thisIndx,
    required List<int>? selectFrom,
    required GridSelection<T>? selection,
    required CellStaticData description,
    required GridFunctionality<T> functionality,
    required VoidCallback? onPressed,
    required Widget child,
  });
}

@immutable
class CellStaticData {
  const CellStaticData({
    this.titleLines = 1,
    this.tightMode = false,
    this.ignoreSwipeSelectGesture = false,
    this.titleAtBottom = false,
    this.circle = false,
    this.alignTitleToTopLeft = false,
    this.ignoreStickers = false,
  });

  /// [GridCell] is displayed in form as a beveled rectangle.
  /// If [circle] is true, then it's displayed as a circle instead.
  final bool circle;

  final bool ignoreSwipeSelectGesture;
  final bool titleAtBottom;
  final bool tightMode;
  final bool alignTitleToTopLeft;
  final bool ignoreStickers;

  final int titleLines;
}

/// Marker class to make [CellBase] implementations pressable.
/// [Pressable] requires the type parameter to have correct type
/// [GridFunctionality] and [onPress].cell.
abstract interface class Pressable<T extends CellBase> {
  /// Potentially, [onPress] can open any page, or not open a page at all.
  void onPress(
    BuildContext context,
    GridFunctionality<T> functionality,
    int idx,
  );
}

class ExitOnPressRoute extends InheritedWidget {
  const ExitOnPressRoute({
    super.key,
    required this.exit,
    required super.child,
  });

  final void Function() exit;

  static void maybeExitOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ExitOnPressRoute>();

    widget?.exit();
  }

  static void exitOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ExitOnPressRoute>();

    widget!.exit();
  }

  @override
  bool updateShouldNotify(ExitOnPressRoute oldWidget) => exit != oldWidget.exit;
}

/// Marker class to make [CellBase] implementations thumbnailable.
abstract interface class Thumbnailable {
  ImageProvider thumbnail();
}

/// Marker class to make [CellBase] implementations stickerable.
/// Also used by [ImageView].
abstract interface class Stickerable {
  /// Some buttons in [ImageView]'s bottom bar have the same meaning
  /// as some stickers, [excludeDuplicate] should remove those.
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate);
}

/// Marker class to make [CellBase] implementations downloadable.
abstract interface class Downloadable {
  String fileDownloadUrl();
}
