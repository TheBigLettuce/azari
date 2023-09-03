// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

/// [CallbackGrid] supports multiple layout modes.
/// [GridLayout] actually implements them all.
class GridLayout {
  static Widget list<T extends Cell>(
          BuildContext context,
          GridMutationInterface<T> state,
          SelectionInterface<T> selection,
          double systemNavigationInsets,
          bool listView,
          {required void Function(T)? loadThumbsDirectly,
          required void Function(BuildContext, T, int) onPressed}) =>
      SliverList.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
        ),
        itemCount: state.cellCount,
        itemBuilder: (context, index) {
          final cell = state.getCell(index);
          final cellData = cell.getCellData(listView);
          if (cellData.loaded != null && cellData.loaded == false) {
            loadThumbsDirectly?.call(cell);
          }

          return _WrappedSelection(
            selectUntil: (i) => selection.selectUnselectUntil(i, state),
            thisIndx: index,
            isSelected: selection.isSelected(index),
            selectionEnabled: selection.selected.isNotEmpty,
            selectUnselect: () => selection.selectOrUnselect(
                context, index, cell, systemNavigationInsets),
            child: ListTile(
              onLongPress: () => selection.selectOrUnselect(
                  context, index, cell, systemNavigationInsets),
              onTap: () => onPressed(context, cell, index),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.background,
                foregroundImage: cellData.thumb,
                onForegroundImageError: (_, __) {},
              ),
              title: Text(
                cellData.name,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ).animate().fadeIn();
        },
      );

  static Widget grid<T extends Cell>(
          BuildContext context,
          GridMutationInterface<T> state,
          SelectionInterface<T> selection,
          int columns,
          bool listView,
          void Function(T)? loadThumbsDirectly,
          GridCell Function(T, int) gridCell,
          {required double systemNavigationInsets,
          required double aspectRatio}) =>
      SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: aspectRatio, crossAxisCount: columns),
        itemCount: state.cellCount,
        itemBuilder: (context, indx) {
          final cell = state.getCell(indx);
          final cellData = cell.getCellData(listView);
          if (cellData.loaded != null && cellData.loaded == false) {
            loadThumbsDirectly?.call(cell);
          }

          return _WrappedSelection(
            selectionEnabled: selection.selected.isNotEmpty,
            thisIndx: indx,
            selectUntil: (i) => selection.selectUnselectUntil(i, state),
            selectUnselect: () => selection.selectOrUnselect(
                context, indx, cell, systemNavigationInsets),
            isSelected: selection.isSelected(indx),
            child: gridCell(cell, indx),
          );
        },
      );

  static Widget segmentedRow<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    List<int> val,
    bool listView,
    GridCell Function(T, int) gridCell, {
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
    required void Function(T)? loadThumbsDirectly,
  }) =>
      Row(
        children: val.map((indx) {
          final cell = state.getCell(indx);
          final cellData = cell.getCellData(listView);
          if (cellData.loaded != null && cellData.loaded == false) {
            loadThumbsDirectly?.call(cell);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints),
            child: material.AspectRatio(
              aspectRatio: aspectRatio,
              child: _WrappedSelection(
                selectionEnabled: selection.selected.isNotEmpty,
                thisIndx: indx,
                selectUntil: (i) => selection.selectUnselectUntil(i, state),
                selectUnselect: () => selection.selectOrUnselect(
                    context, indx, cell, systemNavigationInsets),
                isSelected: selection.isSelected(indx),
                child: gridCell(cell, indx),
              ),
            ),
          );
        }).toList(),
      );

  static Widget segmentedRowCells<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    List<T> val,
    bool listView,
    GridCell Function(T, int) gridCell, {
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
    required void Function(T)? loadThumbsDirectly,
  }) =>
      Row(
        children: val.map((cell) {
          final cellData = cell.getCellData(listView);
          if (cellData.loaded != null && cellData.loaded == false) {
            loadThumbsDirectly?.call(cell);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints),
            child: material.AspectRatio(
              aspectRatio: aspectRatio,
              child: _WrappedSelection(
                selectionEnabled: selection.selected.isNotEmpty,
                thisIndx: -1,
                selectUntil: (i) => selection.selectUnselectUntil(i, state),
                selectUnselect: () => selection.selectOrUnselect(
                    context, -1, cell, systemNavigationInsets),
                isSelected: selection.isSelected(-1),
                child: gridCell(cell, -1),
              ),
            ),
          );
        }).toList(),
      );

  static Widget segments<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    bool listView,
    int columns,
    GridCell Function(T, int) gridCell, {
    required double systemNavigationInsets,
    required double aspectRatio,
    required void Function(T)? loadThumbsDirectly,
  }) {
    final segRows = <dynamic>[];
    final segMap = <String, List<int>>{};
    final stickySegs = <String, List<int>>{};

    final unsegmented = <int>[];

    for (var i = 0; i < state.cellCount; i++) {
      final (res, sticky) = segments.segment(state.getCell(i));
      if (res == null) {
        unsegmented.add(i);
      } else {
        if (sticky) {
          final previous = (stickySegs[res]) ?? [];
          previous.add(i);
          stickySegs[res] = previous;
        } else {
          final previous = (segMap[res]) ?? [];
          previous.add(i);
          segMap[res] = previous;
        }
      }
    }

    segMap.removeWhere((key, value) {
      if (value.length == 1) {
        unsegmented.add(value[0]);
        return true;
      }

      return false;
    });

    makeRows<J>(List<J> value) {
      var row = <J>[];

      for (final i in value) {
        row.add(i);
        if (row.length == columns) {
          segRows.add(row);
          row = [];
        }
      }

      if (row.isNotEmpty) {
        segRows.add(row);
      }
    }

    if (segments.injectedSegments.isNotEmpty) {
      segRows.add(_SegSticky(segments.injectedLabel, true));

      makeRows(segments.injectedSegments);
    }

    stickySegs.forEach((key, value) {
      segRows.add(_SegSticky(key, true));

      makeRows(value);
    });

    segMap.forEach(
      (key, value) {
        segRows.add(_SegSticky(key, false));

        makeRows(value);
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(_SegSticky(segments.unsegmentedLabel, false));

      makeRows(unsegmented);
    }

    final constraints = MediaQuery.of(context).size.width / columns;

    return SliverList.builder(
      itemBuilder: (context, indx) {
        if (indx >= segRows.length) {
          return null;
        }
        final val = segRows[indx];
        if (val is _SegSticky) {
          return Segments.label(
              context,
              val.seg,
              val.sticky,
              segments.addToSticky != null &&
                      val.seg != segments.unsegmentedLabel
                  ? () {
                      HapticFeedback.vibrate();
                      segments.addToSticky!(val.seg,
                          unsticky: val.sticky ? true : null);
                      state.onRefresh();
                    }
                  : null);
        } else if (val is List<int>) {
          return segmentedRow(
              context, state, selection, val, listView, gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
              loadThumbsDirectly: loadThumbsDirectly);
        } else if (val is List<T>) {
          return segmentedRowCells(
              context, state, selection, val, listView, gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
              loadThumbsDirectly: loadThumbsDirectly);
        }
        throw "invalid type";
      },
    );
  }
}
