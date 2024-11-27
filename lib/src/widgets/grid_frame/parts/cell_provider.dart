// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class CellProvider<T extends CellBase> extends InheritedWidget {
  const CellProvider({
    super.key,
    required this.getCell,
    required super.child,
  });

  final GetCellCallback<T> getCell;

  static T getOf<T extends CellBase>(BuildContext context, int i) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

    return widget!.getCell(i);
  }

  static GetCellCallback<T> of<T extends CellBase>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CellProvider<T>>();

    return widget!.getCell;
  }

  @override
  bool updateShouldNotify(CellProvider<T> oldWidget) =>
      getCell != oldWidget.getCell;
}
