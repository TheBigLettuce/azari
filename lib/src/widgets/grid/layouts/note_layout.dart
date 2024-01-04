// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/base/note_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/widgets/shimmer_loading_indicator.dart';

import '../callback_grid.dart';

class NoteLayout<T extends Cell> implements GridLayouter<T> {
  @override
  final GridColumn columns;

  final List<String> Function(T cell) getText;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 2),
        itemBuilder: (context, index) {
          final note = state.widget.getCell(index);
          final provider = note.getCellData(false, context: context).thumb;

          final backgroundColor =
              note is NoteBase ? (note as NoteBase).backgroundColor : null;
          final textColor =
              note is NoteBase ? (note as NoteBase).textColor : null;

          return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              onTap: () => state.onPressed(context, note, index),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                      color: backgroundColor != null
                          ? Color(backgroundColor).harmonizeWith(
                              Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: constraints.minHeight * 0.2,
                                    height: constraints.maxHeight * 0.2,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    clipBehavior: Clip.antiAlias,
                                    child: provider != null
                                        ? Image(
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                            frameBuilder: (
                                              context,
                                              child,
                                              frame,
                                              wasSynchronouslyLoaded,
                                            ) {
                                              if (wasSynchronouslyLoaded) {
                                                return child;
                                              }

                                              return frame == null
                                                  ? const ShimmerLoadingIndicator()
                                                  : child.animate().fadeIn();
                                            },
                                            image: provider)
                                        : null,
                                  )),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                    width: (constraints.maxHeight * 0.8),
                                    height: (constraints.maxHeight * 0.78),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: getText(note)
                                            .map((e) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.3),
                                                  child: Text(
                                                    e,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                        wordSpacing: 2.6,
                                                        color: textColor != null
                                                            ? Color(textColor)
                                                                .harmonizeWith(Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary)
                                                            : null,
                                                        letterSpacing: 1.3,
                                                        fontFamily:
                                                            "ZenKurenaido"),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    )),
                              )
                            ],
                          );
                        },
                      )),
                ),
              ));
        },
        itemCount: state.mutationInterface.cellCount,
      ),
    );
  }

  @override
  bool get isList => false;

  const NoteLayout(this.columns, this.getText);
}
