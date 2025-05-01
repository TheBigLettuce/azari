// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";

mixin DefaultBuildCell implements CellBuilder {
  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    Alignment imageAlign = Alignment.center,
  }) {
    return switch (cellType) {
      CellType.list => DefaultListTile(
          uniqueKey: uniqueKey(),
          title: title(l10n),
          subtitle: subtitle(l10n),
          thumbnail: thumbnail(),
          dismiss: dismiss(),
        ),
      CellType.cell || CellType.cellStatic => GridCell(
          uniqueKey: uniqueKey(),
          thumbnail: thumbnail(),
          titleLines: titleLines(),
          title: hideName ? null : title(l10n),
          subtitle: hideName ? null : subtitle(l10n),
          imageAlign: imageAlign,
        ),
    };
  }
}

// required Widget Function(Widget child) wrapSelection,

abstract mixin class CellBuilderData {
  const CellBuilderData();

  Key uniqueKey();

  String title(AppLocalizations l10n);
  String subtitle(AppLocalizations l10n) => "";

  int titleLines() => 1;

  ImageProvider? thumbnail() => null;

  TileDismiss? dismiss() => null;
}

/// Cells on a grid.
/// Implementations of this interface can be presented on the [ShellElement].
/// This can be not only a cell on a grid, it can be also an element in a list.
/// [ShellElement] decides how this gets displayed.
abstract interface class CellBuilder extends CellBuilderData {
  const CellBuilder();

  /// PlayAnimations.maybeOf(context) might me present
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    Alignment imageAlign = Alignment.center,
  });
}

enum CellType {
  list,
  cell,
  cellStatic,
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
