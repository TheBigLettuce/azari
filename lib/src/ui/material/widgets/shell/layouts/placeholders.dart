// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

mixin ResetSelectionOnUpdate<T extends CellBuilder, W extends StatefulWidget>
    on State<W> {
  ReadOnlyStorage<int, T> get source;
  ShellSelectionHolder? get selection;

  void Function()? get onUpdate => null;

  late final StreamSubscription<int> _resetCountWatcher;

  @override
  void initState() {
    super.initState();

    _resetCountWatcher = source.watch((_) {
      selection?.reset();
      onUpdate?.call();

      setState(() {});
    });
  }

  @override
  void dispose() {
    _resetCountWatcher.cancel();

    super.dispose();
  }
}

class ListLayoutPlaceholder extends StatelessWidget {
  const ListLayoutPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(right: 8, left: 8),
      sliver: SliverList.builder(
        itemCount: 20,
        itemBuilder: (context, index) =>
            DefaultListTilePlaceholder(index: index),
      ),
    );
  }
}

class DefaultListTilePlaceholder extends StatelessWidget {
  const DefaultListTilePlaceholder({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipPath(
      clipper: const ShapeBorderClipper(shape: StadiumBorder()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: index.isOdd
              ? theme.colorScheme.secondary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
        ),
        child: ListTile(
          minVerticalPadding: 1,
          contentPadding: EdgeInsets.zero,
          title: SizedBox.fromSize(
            size: const Size(double.infinity, 56),
            child: const ShimmerLoadingIndicator(),
          ),
        ),
      ),
    );
  }
}

class GridQuiltedLayoutPlaceholder extends StatelessWidget {
  const GridQuiltedLayoutPlaceholder({
    super.key,
    required this.randomNumber,
    required this.circle,
    required this.tightMode,
  });

  final bool circle;
  final bool tightMode;

  final int randomNumber;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);

    return SliverGrid.builder(
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: config.columns.number,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: config.columns.pattern(randomNumber),
      ),
      itemCount: config.columns.number * 20,
      itemBuilder: (context, idx) {
        return GridCellPlaceholder(circle: circle, tightMode: tightMode);
      },
    );
  }
}

class GridLayoutPlaceholder extends StatelessWidget {
  const GridLayoutPlaceholder({
    super.key,
    this.circle = false,
    this.tightMode = false,
  });

  final bool circle;
  final bool tightMode;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: config.aspectRatio.value,
        crossAxisCount: config.columns.number,
      ),
      itemCount: config.columns.number * 20,
      itemBuilder: (context, idx) {
        return GridCellPlaceholder(circle: circle, tightMode: tightMode);
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
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ) ??
                  const TextStyle(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: widget.buildEmpty!(widget.progress.error)
                    .animate()
                    .fadeIn(),
              ),
            ),
          )
        : widget.child;
  }
}

class TrackedIndex extends InheritedWidget {
  const TrackedIndex({
    super.key,
    required this.idx,
    required this.idxSink,
    required super.child,
  });

  final int? idx;
  final Sink<int?> idxSink;

  static Widget wrap(Widget child) => _TrackedIndexWrapper(child: child);

  static int? of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<TrackedIndex>();

    return widget!.idx;
  }

  static Sink<int?> sinkOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<TrackedIndex>();

    return widget!.idxSink;
  }

  @override
  bool updateShouldNotify(TrackedIndex oldWidget) =>
      idx != oldWidget.idx || idxSink != oldWidget.idxSink;
}

class _TrackedIndexWrapper extends StatefulWidget {
  const _TrackedIndexWrapper({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<_TrackedIndexWrapper> createState() => __TrackedIndexWrapperState();
}

class __TrackedIndexWrapperState extends State<_TrackedIndexWrapper> {
  int? idx;

  final _controller = StreamController<int?>.broadcast();
  late final StreamSubscription<int?> _events;

  @override
  void initState() {
    super.initState();

    _events = _controller.stream.listen((e) {
      setState(() {
        idx = e;
      });
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrackedIndex(
      idx: idx,
      idxSink: _controller.sink,
      child: widget.child,
    );
  }
}
