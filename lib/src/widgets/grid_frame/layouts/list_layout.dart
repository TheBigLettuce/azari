// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class ListLayout<T extends CellBase> extends StatefulWidget {
  const ListLayout({
    super.key,
    required this.hideThumbnails,
    required this.source,
    required this.progress,
    this.buildEmpty,
    this.unselectOnUpdate = true,
    this.itemFactory,
  });

  final bool hideThumbnails;
  final bool unselectOnUpdate;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  final Widget Function(BuildContext, int, T)? itemFactory;

  @override
  State<ListLayout<T>> createState() => _ListLayoutState();
}

class _ListLayoutState<T extends CellBase> extends State<ListLayout<T>> {
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

    return EmptyWidgetOrContent(
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      source: source,
      child: SliverPadding(
        padding: const EdgeInsets.only(right: 8, left: 8),
        sliver: SliverList.builder(
          itemCount: source.count,
          itemBuilder: (context, index) {
            final cell = getCell(index);

            return widget.itemFactory?.call(
                  context,
                  index,
                  cell,
                ) ??
                DefaultListTile(
                  functionality: extras.functionality,
                  selection: extras.selection,
                  cell: cell,
                  index: index,
                  hideThumbnails: widget.hideThumbnails,
                );
          },
        ),
      ),
    );
  }
}

class ListLayoutPlaceholder extends StatelessWidget {
  const ListLayoutPlaceholder({
    super.key,
    required this.description,
  });

  final CellStaticData description;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(right: 8, left: 8),
      sliver: SliverList.builder(
        itemCount: 20,
        itemBuilder: (context, index) => DefaultListTilePlaceholder(
          index: index,
        ),
      ),
    );
  }
}

class TileDismiss {
  const TileDismiss(this.onDismissed, this.icon);

  final IconData icon;

  final VoidCallback onDismissed;
}

class DefaultListTile<T extends CellBase> extends StatelessWidget {
  const DefaultListTile({
    super.key,
    required this.functionality,
    required this.selection,
    required this.index,
    required this.cell,
    required this.hideThumbnails,
    this.selectionIndex,
    this.subtitle,
    this.trailing,
    this.dismiss,
  });

  final bool hideThumbnails;

  final int index;
  final int? selectionIndex;

  final String? subtitle;

  final T cell;

  final GridFunctionality<T> functionality;
  final GridSelection<T>? selection;
  final Widget? trailing;

  final TileDismiss? dismiss;

  @override
  Widget build(BuildContext context) {
    final thumbnail = cell.tryAsThumbnailable(context);

    final child = Builder(
      builder: (context) {
        final theme = Theme.of(context);
        SelectionCountNotifier.maybeCountOf(context);
        final isSelected =
            selection?.isSelected(selectionIndex ?? index) ?? false;

        final child = DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? null
                : index.isOdd
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.1),
          ),
          child: DecoratedBox(
            decoration: const ShapeDecoration(shape: StadiumBorder()),
            child: ListTile(
              textColor: isSelected ? theme.colorScheme.inversePrimary : null,
              leading: !hideThumbnails && thumbnail != null
                  ? CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surface.withValues(alpha: 0),
                      backgroundImage: thumbnail,
                    )
                  : null,
              subtitle: subtitle == null ? null : Text(subtitle!),
              trailing: trailing,
              title: Text(
                cell.alias(true),
                softWrap: false,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : index.isOdd
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );

        return ClipPath(
          clipper: const ShapeBorderClipper(shape: StadiumBorder()),
          child: dismiss != null
              ? Dismissible(
                  key: cell.uniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            dismiss!.icon,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onDismissed: (direction) {
                    dismiss!.onDismissed();
                  },
                  dismissThresholds: const {DismissDirection.horizontal: 0.5},
                  child: child,
                )
              : child,
        );
      },
    );

    return WrapSelection(
      selection: selection,
      selectFrom: null,
      limitedSize: true,
      shape: const StadiumBorder(),
      description: cell.description(),
      onPressed: cell.tryAsPressable(context, functionality, index),
      functionality: functionality,
      thisIndx: selectionIndex ?? index,
      child: child,
    ).animate(key: cell.uniqueKey()).fadeIn();
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
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.1),
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
