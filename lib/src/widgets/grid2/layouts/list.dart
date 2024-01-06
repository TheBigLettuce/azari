// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/notifiers/cell_provider.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';
import 'package:gallery/src/widgets/notifiers/selection_data.dart';

import '../cell/wrapped_selection.dart';

class ListLayout<T extends Cell> extends StatelessWidget {
  final void Function(T)? download;

  const ListLayout({super.key, this.download});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const Divider(
        height: 1,
      ),
      itemCount: GridElementCountNotifier.of(context),
      itemBuilder: (context, index) {
        final onPressed = GridMetadataProvider.onPressedOf<T>(context);
        final cell = CellProvider.getOf<T>(context, index);
        final cellData = cell.getCellData(true, context: context);

        return Animate(
            key: cell.uniqueKey(),
            effects: const [FadeEffect(end: 1.0)],
            child: WrappedSelection(
              thisIndx: index,
              child: ListTile(
                  textColor:
                      SelectionData.of(context).isSelected(context, index)
                          ? Theme.of(context).colorScheme.inversePrimary
                          : null,
                  onTap: onPressed == null
                      ? null
                      : () => onPressed(context, index),
                  leading: cellData.thumb != null
                      ? CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
                          foregroundImage: cellData.thumb,
                          onForegroundImageError: (_, __) {},
                        )
                      : null,
                  title: Text(
                    cellData.name,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  )),
            ));
      },
    );
  }
}


// static Widget list<T extends Cell>(
//     BuildContext context,
//     GridMutationInterface<T> state,
//     SelectionInterface<T> selection,
//     double systemNavigationInsets, {
//     required void Function(BuildContext, T, int)? onPressed,
//   }) =>
     
      // );

//   static Widget listTile<T extends Cell>(
//       BuildContext context,
//       GridMutationInterface<T> state,
//       SelectionInterface<T> selection,
//       double systemNavigationInsets,
//       {required int index,
//       required T cell,
//       required void Function(BuildContext, T, int)? onPressed}) {
//     final cellData = cell.getCellData(true, context: context);
//     final selected = selection.isSelected(index);

    
//   }