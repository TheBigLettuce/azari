// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';
import 'package:gallery/src/widgets/notifiers/network_configuration.dart';

import 'grid_action.dart';

/// Displayed in the keybinds info page name.
// final String keybindsDescription;

/// If [pageName] is not null, and [CallbackGridShell.searchWidget] is null,
/// then a Text widget will be displayed in the app bar with this value.
/// If null and [CallbackGridShell.searchWidget] is null, then [keybindsDescription] is used as the value.
// final String? pageName;

/// Actions of the grid on selected cells.
// final List<GridAction<T>> actions;

// final GridLayouter<T> layout;

/// Displayed in the app bar bottom widget.
// final PreferredSizeWidget? bottomWidget;

// final bool showAppBar;

// class GridDescription1 {
//   final GridColumn columns;
//   final GridAspectRatio aspectRatio;

//   const GridDescription1(
//     this.actions, {
//     this.showAppBar = true,
//     required this.keybindsDescription,
//     this.bottomWidget,
//     this.pageName,
//     // required this.layout,
//   });
// }

/// Metadata about the grid.
class GridMetadata<T extends Cell> {
  /// Actions of the grid on selected cells.
  final List<GridAction<T>> gridActions;

  // final List<Widget> appBarActions;

  // final SearchAndFocus? search;

  final bool tight;

  final bool hideAlias;

  final bool isList;

  final GridAspectRatio aspectRatio;

  final GridColumn columns;

  final void Function(BuildContext, int)? onPressed;

  // static void launchImageView<T extends Cell>(BuildContext context, int idx) {
  //   final r = NotifierRegistry.registrerOf(context);
  //   // final c = CellProvider.getOf<T>(context, idx);
  //   final f = CellProvider.of<T>(context);

  //   final overlayColor =
  //       Theme.of(context).colorScheme.background.withOpacity(0.5);

  //   Navigator.push(context, MaterialPageRoute(builder: (context) {
  //     return r!(_Test1<T>(
  //         child: ImageView<T>(
  //       systemOverlayRestoreColor: overlayColor,
  //       onExit: () {
  //         // inImageView = false;
  //         // widget.onExitImageView?.call();
  //       },
  //       focusMain: () {
  //         // widget.mainFocus.requestFocus();
  //       },

  //       // currentCell: c,
  //       startingCell: idx,
  //       updateTagScrollPos: (pos, selectedCell) {},
  //       cellCount: GridElementCountNotifier.of(context),
  //       scrollUntill: (post) {},
  //       onNearEnd: null, getCell: (i) => f(i)!,
  //     )));
  //   }));
  // }

  //   final offsetGrid = controller.offset;
  // final overlayColor =
  // Theme.of(context).colorScheme.background.withOpacity(0.5);

  // final c = GridElementCountNotifier.of(context);

  // final f = CellProvider.of<T>(context);

  // onNearEnd: widget.loadNext == null ? null : _state._onNearEnd);

// segTranslation != null
  //     ? () {
  //         for (final (i, e) in segTranslation!.indexed) {
  //           if (e == startingCell) {
  //             return i;
  //           }
  //         }

  //         return 0;
  //       }()
  //     : startingCell,

  const GridMetadata({
    // this.appBarActions = const [],
    required this.gridActions,
    this.hideAlias = false,
    this.tight = false,
    this.onPressed,
    required this.aspectRatio,
    required this.columns,
    required this.isList,
    // this.search,
  });
}

class _Test1<T extends Cell> extends StatelessWidget {
  final Widget child;

  const _Test1({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    NetworkConfigurationProvider.of(context);
    // CellProvider.of<T>(context);
    GridMetadataProvider.isListOf<T>(context);
    GridElementCountNotifier.of(context);

    return child;
  }
}

// abstract class GridLayouter {
//   Widget call(BuildContext context, CallbackGridShellState<T> state);
//   GridColumn? get columns;
//   bool get isList;

//   const GridLayouter();
// }
