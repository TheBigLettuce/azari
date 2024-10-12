// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class GridLayout<T extends CellBase> extends StatefulWidget {
  const GridLayout({
    super.key,
    required this.source,
    this.buildEmpty,
    required this.progress,
    this.unselectOnUpdate = true,
  });

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;
  final bool unselectOnUpdate;

  @override
  State<GridLayout<T>> createState() => _GridLayoutState();
}

class _GridLayoutState<T extends CellBase> extends State<GridLayout<T>> {
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
      source: source,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: config.aspectRatio.value,
          crossAxisCount: config.columns.number,
        ),
        itemCount: source.count,
        itemBuilder: (context, idx) {
          final cell = getCell(idx);

          return WrapSelection<T>(
            selection: extras.selection,
            thisIndx: idx,
            onPressed: cell.tryAsPressable(context, extras.functionality, idx),
            description: cell.description(),
            functionality: extras.functionality,
            selectFrom: null,
            child: cell.buildCell<T>(
              context,
              idx,
              cell,
              hideTitle: config.hideName,
              isList: false,
              imageAlign: Alignment.center,
              animated: PlayAnimations.maybeOf(context) ?? false,
            ),
          );
        },
      ),
    );
  }
}

class GridLayoutPlaceholder extends StatelessWidget {
  const GridLayoutPlaceholder({
    super.key,
    required this.description,
  });

  final CellStaticData description;

  @override
  Widget build(BuildContext context) {
    final config = GridConfiguration.of(context);

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: config.aspectRatio.value,
        crossAxisCount: config.columns.number,
      ),
      itemCount: config.columns.number * 20,
      itemBuilder: (context, idx) {
        return GridCellPlaceholder(
          description: description,
        );
      },
    );
  }
}

class EmptyWidgetOrContent extends StatefulWidget {
  const EmptyWidgetOrContent({
    super.key,
    required this.progress,
    required this.buildEmpty,
    required this.source,
    required this.child,
  });

  final ReadOnlyStorage<dynamic, dynamic> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  final Widget child;

  @override
  State<EmptyWidgetOrContent> createState() => _EmptyWidgetOrContentState();
}

class _EmptyWidgetOrContentState extends State<EmptyWidgetOrContent>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<bool> _watcher;

  @override
  void initState() {
    _watcher = widget.progress.watch((_) {
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
    final theme = Theme.of(context);

    if (widget.buildEmpty == null) {
      return widget.child;
    }

    return widget.source.count == 0 && !widget.progress.inRefreshing
        ? SliverToBoxAdapter(
            child: DefaultTextStyle(
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ) ??
                  const TextStyle(),
              child:
                  widget.buildEmpty!(widget.progress.error).animate().fadeIn(),
            ),
          )
        : widget.child;
  }
}
