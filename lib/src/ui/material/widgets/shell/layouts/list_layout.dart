// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class ListLayout<T extends CellBuilder> extends StatefulWidget {
  const ListLayout({
    super.key,
    required this.hideThumbnails,
    required this.source,
    required this.progress,
    required this.selection,
    this.buildEmpty,
  });

  final bool hideThumbnails;

  final ShellSelectionHolder? selection;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<ListLayout<T>> createState() => _ListLayoutState();
}

class _ListLayoutState<T extends CellBuilder> extends State<ListLayout<T>>
    with ResetSelectionOnUpdate<T, ListLayout<T>> {
  @override
  ReadOnlyStorage<int, T> get source => widget.source;

  @override
  ShellSelectionHolder? get selection => widget.selection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return EmptyWidgetOrContent(
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      source: source,
      child: TrackedIndex.wrap(
        SliverPadding(
          padding: const EdgeInsets.only(right: 8, left: 8),
          sliver: SliverList.builder(
            itemCount: source.count,
            itemBuilder: (context, idx) {
              final cell = widget.source[idx];

              return Padding(
                padding: (source.count - 1) == idx
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 2),
                child: ThisIndex(
                  idx: idx,
                  selectFrom: null,
                  child: Builder(
                    builder: (context) => cell.buildCell(
                      l10n,
                      hideName: false,
                      cellType: CellType.list,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

//  ??
//                 DefaultListTile(
//                   selection: selection,
//                   cell: cell,
//                   index: index,
//                   hideThumbnails: widget.hideThumbnails,
//                 )

class TileDismiss {
  const TileDismiss(this.onDismissed, this.icon);

  final IconData icon;

  final VoidCallback onDismissed;
}

class DefaultListTile extends StatelessWidget {
  const DefaultListTile({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.uniqueKey,
    this.subtitle,
    this.trailing,
    this.dismiss,
  });

  final Key uniqueKey;

  final String? title;
  final String? subtitle;

  final Widget? trailing;
  final ImageProvider? thumbnail;

  final TileDismiss? dismiss;

  @override
  Widget build(BuildContext context) {
    final animate = PlayAnimations.maybeOf(context) ?? false;
    final theme = Theme.of(context);
    SelectionCountNotifier.maybeCountOf(context);
    // final isSelected = selection?.isSelected(selectionIndex ?? index) ?? false;

    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color:
            // isSelected
            //     ? null
            //     :
            theme.colorScheme.secondary.withValues(alpha: 0.1),
        // index.isOdd
        //     ? theme.colorScheme.secondary.withValues(alpha: 0.1)
        //     : theme.colorScheme.surfaceContainerHighest
        //         .withValues(alpha: 0.1),
      ),
      child: DecoratedBox(
        decoration: const ShapeDecoration(shape: StadiumBorder()),
        child: ListTile(
          // textColor: isSelected ? theme.colorScheme.inversePrimary : null,
          leading: thumbnail != null
              ? CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.surface.withValues(alpha: 0),
                  backgroundImage: thumbnail,
                )
              : null,
          subtitle:
              subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
          trailing: trailing,
          title: Text(
            title ?? "",
            softWrap: false,
            style: TextStyle(
              color:
                  // isSelected
                  //     ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                  //     :
                  theme.colorScheme.onSurface.withValues(alpha: 0.8),
              // index.isOdd
              //     ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
              //     : theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    if (animate) {
      child = child.animate(key: uniqueKey).fadeIn();
    }

    return ClipPath(
      clipper: const ShapeBorderClipper(shape: StadiumBorder()),
      child: dismiss != null
          ? Dismissible(
              key: uniqueKey,
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
  }
}

//  WrapSelection(
//       selectFrom: null,
//       limitedSize: true,
//       shape: const StadiumBorder(),
//       description: cell.description(),
//       onPressed: cell.tryAsPressable(context, index),
//       thisIndx: selectionIndex ?? index,
//       child: child,
//     ).animate(key: cell.uniqueKey()).fadeIn()
