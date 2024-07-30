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
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

class GridQuiltedLayout<T extends CellBase> extends StatefulWidget {
  const GridQuiltedLayout({
    super.key,
    required this.randomNumber,
    required this.source,
    required this.progress,
    this.buildEmpty,
    this.unselectOnUpdate = true,
  });

  final int randomNumber;
  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final bool unselectOnUpdate;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<GridQuiltedLayout<T>> createState() => _GridQuiltedLayoutState();
}

class _GridQuiltedLayoutState<T extends CellBase>
    extends State<GridQuiltedLayout<T>> {
  ReadOnlyStorage<int, T> get source => widget.source;

  late final StreamSubscription<int> _watcher;

  @override
  void initState() {
    _watcher = source.watch((_) {
      if (widget.unselectOnUpdate) {
        GridExtrasNotifier.of<T>(context).selection.reset();
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

    return EmptyWidgetOrContent(
      count: source.count,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverGrid.builder(
        itemCount: source.count,
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: config.columns.number,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: config.columns.pattern(widget.randomNumber),
        ),
        itemBuilder: (context, idx) {
          final cell = getCell(idx);

          return WrapSelection(
            thisIndx: idx,
            description: cell.description(),
            selection: extras.selection,
            onPressed: cell.tryAsPressable(context, extras.functionality, idx),
            functionality: extras.functionality,
            selectFrom: null,
            child: GridCell.frameDefault(
              context,
              idx,
              cell,
              imageAlign: Alignment.topCenter,
              hideTitle: config.hideName,
              isList: false,
              animated: PlayAnimations.maybeOf(context) ?? false,
            ),
          );
        },
      ),
    );
  }
}
