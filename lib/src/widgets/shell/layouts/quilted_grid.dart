// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

class QuiltedGridLayout<T extends CellBase> extends StatefulWidget {
  const QuiltedGridLayout({
    super.key,
    required this.randomNumber,
    required this.source,
    required this.progress,
    required this.selection,
    this.buildEmpty,
  });

  final int randomNumber;
  final ShellSelectionHolder? selection;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<QuiltedGridLayout<T>> createState() => _QuiltedGridLayoutState();
}

class _QuiltedGridLayoutState<T extends CellBase>
    extends State<QuiltedGridLayout<T>>
    with ResetSelectionOnUpdate<T, QuiltedGridLayout<T>> {
  @override
  ReadOnlyStorage<int, T> get source => widget.source;

  @override
  ShellSelectionHolder? get selection => widget.selection;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);

    return EmptyWidgetOrContent(
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      source: source,
      child: SliverGrid.builder(
        itemCount: source.count,
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: config.columns.number,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: config.columns.pattern(widget.randomNumber),
        ),
        itemBuilder: (context, idx) {
          final cell = widget.source[idx];

          return cell.buildCell<T>(
            context,
            idx,
            cell,
            imageAlign: Alignment.topCenter,
            hideTitle: config.hideName,
            isList: false,
            animated: PlayAnimations.maybeOf(context) ?? false,
            wrapSelection: (child) =>
                cell.tryAsSelectionWrapperable()?.buildSelectionWrapper<T>(
                      context: context,
                      thisIndx: idx,
                      onPressed: cell.tryAsPressable(
                        context,
                        idx,
                      ),
                      description: cell.description(),
                      selectFrom: null,
                      child: child,
                    ) ??
                WrapSelection(
                  thisIndx: idx,
                  description: cell.description(),
                  onPressed: cell.tryAsPressable(context, idx),
                  selectFrom: null,
                  child: child,
                ),
          );
        },
      ),
    );
  }
}
