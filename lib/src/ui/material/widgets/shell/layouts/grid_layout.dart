// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class GridLayout<T extends CellBuilder> extends StatefulWidget {
  const GridLayout({
    super.key,
    required this.source,
    this.buildEmpty,
    required this.progress,
    required this.selection,
  });

  final ShellSelectionHolder? selection;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<GridLayout<T>> createState() => _GridLayoutState();
}

class _GridLayoutState<T extends CellBuilder> extends State<GridLayout<T>>
    with ResetSelectionOnUpdate<T, GridLayout<T>> {
  @override
  ReadOnlyStorage<int, T> get source => widget.source;

  @override
  ShellSelectionHolder? get selection => widget.selection;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);
    final l10n = context.l10n();

    return EmptyWidgetOrContent(
      source: source,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: TrackedIndex.wrap(
        SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: config.aspectRatio.value,
            crossAxisCount: config.columns.number,
          ),
          itemCount: source.count,
          itemBuilder: (context, idx) {
            final cell = widget.source[idx];

            return TrackingIndexHolder(
              idx: idx,
              child: ThisIndex(
                idx: idx,
                selectFrom: null,
                child: Builder(
                  builder: (context) => cell.buildCell(
                    l10n,
                    hideName: config.hideName,
                    cellType: CellType.cell,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TrackingIndexHolder extends StatefulWidget {
  const TrackingIndexHolder({
    super.key,
    required this.idx,
    required this.child,
  });

  final int idx;
  final Widget child;

  @override
  State<TrackingIndexHolder> createState() => _TrackingIndexHolderState();
}

class _TrackingIndexHolderState extends State<TrackingIndexHolder> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newI = TrackedIndex.of(context);

    if (newI == widget.idx) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: Durations.medium3,
            curve: Easing.standard,
            // alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
