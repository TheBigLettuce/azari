// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

class GridMasonryLayout<T extends CellBase> extends StatefulWidget {
  const GridMasonryLayout({
    super.key,
    required this.randomNumber,
    required this.source,
    required this.progress,
    this.buildEmpty,
    this.unselectOnUpdate = true,
  });

  final bool unselectOnUpdate;

  final int randomNumber;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<GridMasonryLayout<T>> createState() => _GridMasonryLayoutState();
}

class _GridMasonryLayoutState<T extends CellBase>
    extends State<GridMasonryLayout<T>> {
  ReadOnlyStorage<int, T> get source => widget.source;

  late final StreamSubscription<int> _watcher;

  @override
  void initState() {
    _watcher = source.watch((_) {
      if (widget.unselectOnUpdate) {
        GridExtrasNotifier.of<T>(context).selection?.reset();
      }

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getCell = CellProvider.of<T>(context);
    final extras = GridExtrasNotifier.of<T>(context);
    final config = GridConfiguration.of(context);

    final size = (MediaQuery.sizeOf(context).shortestSide * 0.95) /
        config.columns.number;

    return EmptyWidgetOrContent(
      source: source,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverMasonryGrid(
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.columns.number,
        ),
        delegate: SliverChildBuilderDelegate(childCount: source.count,
            (context, idx) {
          final cell = getCell(idx);

          final rem = ((widget.randomNumber + idx) % 11) * 0.5;
          final maxHeight = (size / config.aspectRatio.value) +
              (rem *
                      (size *
                          (0.037 + (config.columns.number / 100) - rem * 0.01)))
                  .toInt();

          final child = cell.buildCell<T>(
            context,
            idx,
            cell,
            imageAlign: Alignment.center,
            hideTitle: config.hideName,
            isList: false,
          );

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: WrapSelection(
              selection: extras.selection,
              thisIndx: idx,
              onPressed:
                  cell.tryAsPressable(context, extras.functionality, idx),
              description: cell.description(),
              functionality: extras.functionality,
              selectFrom: null,
              child: child,
            ),
          );
        }),
      ),
    );
  }
}
