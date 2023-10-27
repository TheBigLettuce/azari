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
    double systemNavigationInsets, {
    required void Function(BuildContext, T, int)? onPressed,
  }) =>
      SliverList.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
        ),
        itemCount: state.cellCount,
        itemBuilder: (context, index) => listTile(
          context,
          state,
          selection,
          systemNavigationInsets,
          index: index,
          cell: state.getCell(index),
          onPressed: onPressed,
        ),
      );

  static Widget listTile<T extends Cell>(
      BuildContext context,
      GridMutationInterface<T> state,
      SelectionInterface<T> selection,
      double systemNavigationInsets,
      {required int index,
      required T cell,
      required void Function(BuildContext, T, int)? onPressed}) {
    final cellData = cell.getCellData(true, context: context);
    final selected = selection.isSelected(index);

    return _WrappedSelection(
      selectUntil: (i) => selection.selectUnselectUntil(i, state),
      thisIndx: index,
      isSelected: selected,
      selectionEnabled: selection.selected.isNotEmpty,
      scrollController: selection.controller,
      bottomPadding: systemNavigationInsets,
      selectUnselect: () => selection.selectOrUnselect(
          context, index, cell, systemNavigationInsets),
      child: ListTile(
        textColor:
            selected ? Theme.of(context).colorScheme.inversePrimary : null,
        onLongPress: () => selection.selectOrUnselect(
            context, index, cell, systemNavigationInsets),
        onTap: onPressed == null ? null : () => onPressed(context, cell, index),
        leading: cellData.thumb != null
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.background,
                foregroundImage: cellData.thumb,
                onForegroundImageError: (_, __) {},
              )
            : null,
        title: Text(
          cellData.name,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ).animate().fadeIn();
  }

  static Widget grid<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    int columns,
    bool listView,
    GridCell Function(BuildContext, T, int) gridCell, {
    required double systemNavigationInsets,
    required double aspectRatio,
  }) =>
      SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: aspectRatio, crossAxisCount: columns),
        itemCount: state.cellCount,
        itemBuilder: (context, indx) {
          final cell = state.getCell(indx);

          return _WrappedSelection(
            selectionEnabled: selection.selected.isNotEmpty,
            thisIndx: indx,
            bottomPadding: systemNavigationInsets,
            scrollController: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(i, state),
            selectUnselect: () => selection.selectOrUnselect(
                context, indx, cell, systemNavigationInsets),
            isSelected: selection.isSelected(indx),
            child: gridCell(context, cell, indx),
          );
        },
      );

  static Widget segmentedRow<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    List<int> val,
    bool listView,
    GridCell Function(BuildContext, T, int) gridCell, {
    List<int> Function()? predefined,
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) =>
      Row(
        children: val.map((indx) {
          final cell = state.getCell(indx);

          return listView
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: listTile(
                      context, state, selection, systemNavigationInsets,
                      index: indx, cell: cell, onPressed: null),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: material.AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _WrappedSelection(
                      selectionEnabled: selection.selected.isNotEmpty,
                      thisIndx: indx,
                      bottomPadding: systemNavigationInsets,
                      scrollController: selection.controller,
                      selectUntil: (i) {
                        if (predefined != null) {
                          selection.selectUnselectUntil(indx, state,
                              selectFrom: predefined());
                        } else {
                          selection.selectUnselectUntil(indx, state);
                        }
                      },
                      selectUnselect: () => selection.selectOrUnselect(
                          context, indx, cell, systemNavigationInsets),
                      isSelected: selection.isSelected(indx),
                      child: gridCell(context, cell, indx),
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
    GridCell Function(BuildContext, T, int) gridCell, {
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) =>
      Row(
        children: val.indexed.map((cell) {
          return listView
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: listTile<T>(
                      context, state, selection, systemNavigationInsets,
                      index: cell.$1, cell: cell.$2, onPressed: null),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: material.AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _WrappedSelection(
                      selectionEnabled: selection.selected.isNotEmpty,
                      thisIndx: -1,
                      bottomPadding: systemNavigationInsets,
                      scrollController: selection.controller,
                      selectUntil: (i) =>
                          selection.selectUnselectUntil(i, state),
                      selectUnselect: () => selection.selectOrUnselect(
                          context, -1, cell.$2, systemNavigationInsets),
                      isSelected: selection.isSelected(-1),
                      child: gridCell(context, cell.$2, -1),
                    ),
                  ),
                );
        }).toList(),
      );

  static Widget segmentsPrebuilt<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    bool listView,
    int columns,
    GridCell Function(BuildContext, T, int) gridCell, {
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    final segRows = <dynamic>[];

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
      segRows.add(
          _SegSticky(segments.injectedLabel, true, null, unstickable: false));

      makeRows(segments.injectedSegments);
    }

    int prevCount = 0;
    for (final e in segments.prebuiltSegments!.entries) {
      segRows.add(_SegSticky(
          e.key,
          true,
          segments.onLabelPressed == null
              ? null
              : () {
                  if (segments.limitLabelChildren != null &&
                      segments.limitLabelChildren != 0 &&
                      !segments.limitLabelChildren!.isNegative) {
                    segments.onLabelPressed!(
                        e.key,
                        List.generate(
                                e.value > segments.limitLabelChildren!
                                    ? segments.limitLabelChildren!
                                    : e.value,
                                (index) => index + prevCount)
                            .map((e) => state.getCell(e))
                            .toList());

                    return;
                  }

                  final cells = <T>[];

                  for (final i
                      in List.generate(e.value, (index) => index + prevCount)) {
                    cells.add(state.getCell(i - 1));
                  }

                  segments.onLabelPressed!(e.key, cells);
                }));

      makeRows(List.generate(e.value, (index) => index + prevCount));

      prevCount += e.value;
    }

    Widget make(double constraints) {
      return SliverList.builder(
        itemBuilder: (context, indx) {
          if (indx >= segRows.length) {
            return null;
          }
          final val = segRows[indx];
          if (val is _SegSticky) {
            return Segments.label(context, val.seg,
                sticky: val.sticky,
                hidePinnedIcon: segments.hidePinnedIcon,
                onLongPress: !val.unstickable
                    ? null
                    : segments.addToSticky != null &&
                            val.seg != segments.unsegmentedLabel
                        ? () {
                            if (segments.addToSticky!(val.seg,
                                unsticky: val.sticky ? true : null)) {
                              HapticFeedback.vibrate();
                              state.onRefresh();
                            }
                          }
                        : null,
                onPress: val.onLabelPressed);
          } else if (val is List<int>) {
            return segmentedRow(
              context,
              state,
              selection,
              val,
              listView,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
            );
          } else if (val is List<T>) {
            return segmentedRowCells(
              context,
              state,
              selection,
              val,
              listView,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
            );
          }
          throw "invalid type";
        },
      );
    }

    return !Platform.isAndroid
        ? SliverLayoutBuilder(
            builder: (context, c) {
              final constraints = c.asBoxConstraints().minWidth / columns;

              return make(constraints);
            },
          )
        : make(MediaQuery.of(context).size.width / columns);
  }

  static (Widget, List<int>) segmentsFnc<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    SelectionInterface<T> selection,
    bool listView,
    int columns,
    GridCell Function(BuildContext, T, int) gridCell, {
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    final segRows = <dynamic>[];
    final segMap = <String, List<int>>{};
    final stickySegs = <String, List<int>>{};

    final unsegmented = <int>[];

    segments.addToSticky;

    for (var i = 0; i < state.cellCount; i++) {
      final (res, sticky) = segments.segment!(state.getCell(i));
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
      segRows.add(
          _SegSticky(segments.injectedLabel, true, null, unstickable: false));

      makeRows(segments.injectedSegments);
    }

    void onLabelPressed(String key, List<int> value) {
      if (segments.limitLabelChildren != null &&
          segments.limitLabelChildren != 0 &&
          !segments.limitLabelChildren!.isNegative) {
        segments.onLabelPressed!(
            key,
            value
                .take(segments.limitLabelChildren!)
                .map((e) => state.getCell(e))
                .toList());

        return;
      }

      segments.onLabelPressed!(
          key, value.map((e) => state.getCell(e)).toList());
    }

    stickySegs.forEach((key, value) {
      segRows.add(_SegSticky(
          key,
          true,
          segments.onLabelPressed == null
              ? null
              : () => onLabelPressed(key, value)));

      makeRows(value);
    });

    segMap.forEach(
      (key, value) {
        segRows.add(_SegSticky(
            key,
            false,
            segments.onLabelPressed == null
                ? null
                : () => onLabelPressed(key, value)));

        makeRows(value);
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(_SegSticky(
          segments.unsegmentedLabel,
          false,
          segments.onLabelPressed == null
              ? null
              : () => onLabelPressed(segments.unsegmentedLabel, unsegmented)));

      makeRows(unsegmented);
    }

    final List<int> predefined = [];

    for (final segs in stickySegs.values) {
      predefined.addAll(segs);
    }

    for (final segs in segMap.values) {
      predefined.addAll(segs);
    }

    predefined.addAll(unsegmented);

    Widget make(double constraints) {
      return SliverList.builder(
        itemBuilder: (context, indx) {
          if (indx >= segRows.length) {
            return null;
          }
          final val = segRows[indx];
          if (val is _SegSticky) {
            return Segments.label(context, val.seg,
                sticky: val.sticky,
                hidePinnedIcon: segments.hidePinnedIcon,
                onLongPress: !val.unstickable
                    ? null
                    : segments.addToSticky != null &&
                            val.seg != segments.unsegmentedLabel
                        ? () {
                            if (segments.addToSticky!(val.seg,
                                unsticky: val.sticky ? true : null)) {
                              HapticFeedback.vibrate();
                              state.onRefresh();
                            }
                          }
                        : null,
                onPress: val.onLabelPressed);
          } else if (val is List<int>) {
            return segmentedRow(
              context,
              state,
              selection,
              val,
              listView,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
              predefined: () => predefined,
            );
          } else if (val is List<T>) {
            return segmentedRowCells(
              context,
              state,
              selection,
              val,
              listView,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
            );
          }
          throw "invalid type";
        },
      );
    }

    return (
      !Platform.isAndroid
          ? SliverLayoutBuilder(
              builder: (context, c) {
                final constraints = c.asBoxConstraints().minWidth / columns;

                return make(constraints);
              },
            )
          : make(MediaQuery.of(context).size.width / columns),
      predefined
    );
  }
}
