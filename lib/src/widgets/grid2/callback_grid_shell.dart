// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/notifiers/data_loader_holder.dart';
import 'package:gallery/src/widgets/notifiers/grid_footer.dart';
import 'package:gallery/src/widgets/notifiers/selection_data.dart';

import 'callback_grid_base.dart';

class CallbackGridShell<T extends Cell> extends StatelessWidget {
  /// The cell includes some keybinds by default.
  /// If [additionalKeybinds] is not null, they are added together.
  final Map<SingleActivator, void Function()> keybinds;

  /// The main focus node of the grid.
  final FocusNode mainFocus;

  /// If [footer] is not null, displayed at the bottom of the screen,
  /// on top of the [child].
  final PreferredSizeWidget? footer;

  // final Widget? fab;

  // final List<Widget> appBarActions;

  // final SearchAndFocus? search;

  final BackgroundDataLoader<T> loader;

  // final Widget? leading;

  /// The actual grid widget.

  final Widget? appBar;

  final Widget child;

  const CallbackGridShell({
    super.key,
    required this.keybinds,
    required this.mainFocus,
    required this.appBar,
    // required this.appBarActions,
    required this.loader,
    // this.leading,
    // this.search,
    this.footer,
    // this.fab,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GridFooterNotifier(
        size: footer?.preferredSize.height,
        child: CallbackShortcuts(
          bindings: keybinds,
          child: Focus(
              autofocus: true,
              focusNode: mainFocus,
              child: DataLoaderHolder<T>(
                loader: loader,
                child: GridSelectionHolder<T>(
                    child: CallbackGridBase<T>(
                  appBar: appBar,
                  // GridAppBar(
                  //   actions: appBarActions,
                  //   bottomWidget: null,
                  //   centerTitle: true,
                  //   leading: leading ?? const SizedBox.shrink(),
                  //   title: GridAppBarTitle(
                  //       searchWidget: search,
                  //       child: const WrapBadgeCellCountTitleWidget(
                  //         child: SearchCharacterTitle(),
                  //       )),
                  // ),
                  child: child,
                  // Stack(
                  //   children: [
                  //     child,
                  //     if (footer != null)
                  //       Align(
                  //         alignment: Alignment.bottomLeft,
                  //         child: Padding(
                  //           padding: EdgeInsets.only(
                  //             bottom: MediaQuery.systemGestureInsetsOf(context)
                  //                 .bottom,
                  //           ),
                  //           child: footer!,
                  //         ),
                  //       ),

                  //   ],
                  // ),
                )),
              )),
        ));
  }
}
