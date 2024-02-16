// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

typedef MakeCellFunc<T extends Cell> = GridCell Function(
  BuildContext,
  T,
  int, {
  required bool hideAlias,
  required bool tightMode,
});

/// [GridFrame] supports multiple layout modes.
/// [GridLayout] actually implements them all.
abstract class GridLayouts {
  static Widget list<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    double systemNavigationInsets, {
    required bool hideThumbnails,
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
          hideThumbnails: hideThumbnails,
          onPressed: onPressed,
        ),
      );

  static Widget listTile<T extends Cell>(
      BuildContext context,
      GridMutationInterface<T> state,
      GridSelection<T> selection,
      double systemNavigationInsets,
      {required int index,
      required T cell,
      required bool hideThumbnails,
      required void Function(BuildContext, T, int)? onPressed}) {
    final selected = selection.isSelected(index);

    return _WrapSelection(
      actionsAreEmpty: selection.addActions.isEmpty,
      selectUntil: (i) => selection.selectUnselectUntil(i, state),
      thisIndx: index,
      isSelected: selected,
      ignoreSwipeGesture: selection.ignoreSwipe,
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
        leading: !hideThumbnails && cell.thumbnail() != null
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.background,
                foregroundImage: cell.thumbnail(),
                onForegroundImageError: (_, __) {},
              )
            : null,
        title: Text(
          cell.alias(true),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ).animate(key: cell.uniqueKey()).fadeIn();
  }

  static Widget grid<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    int columns,
    bool listView,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: aspectRatio, crossAxisCount: columns),
      itemCount: state.cellCount,
      itemBuilder: (context, indx) {
        final cell = state.getCell(indx);

        return _WrapSelection(
          actionsAreEmpty: selection.addActions.isEmpty,
          selectionEnabled: selection.selected.isNotEmpty,
          thisIndx: indx,
          ignoreSwipeGesture: selection.ignoreSwipe,
          bottomPadding: systemNavigationInsets,
          scrollController: selection.controller,
          selectUntil: (i) => selection.selectUnselectUntil(i, state),
          selectUnselect: () => selection.selectOrUnselect(
              context, indx, cell, systemNavigationInsets),
          isSelected: selection.isSelected(indx),
          child: gridCell(context, cell, indx,
              hideAlias: hideAlias, tightMode: tightMode),
        );
      },
    );
  }

  static Widget masonryGrid<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    int columns,
    bool listView,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
    required double systemNavigationInsets,
    required double aspectRatio,
    required int randomNumber,
  }) {
    final size = (MediaQuery.sizeOf(context).shortestSide * 0.95) / columns;

    return SliverMasonryGrid(
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      delegate: SliverChildBuilderDelegate(childCount: state.cellCount,
          (context, indx) {
        final cell = state.getCell(indx);

        // final n1 = switch (columns) {
        //   2 => 4,
        //   3 => 3,
        //   4 => 3,
        //   5 => 3,
        //   6 => 3,
        //   int() => 4,
        // };

        // final n2 = switch (columns) {
        //   2 => 40,
        //   3 => 40,
        //   4 => 30,
        //   5 => 30,
        //   6 => 20,
        //   int() => 40,
        // };

        // final int i = ((randomNumber + indx) % 5 + n1) * n2;

        final rem = ((randomNumber + indx) % 11) * 0.5;

        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: (size / aspectRatio) +
                  (rem * (size * (0.037 + (columns / 100) - rem * 0.01)))
                      .toInt()),
          child: _WrapSelection(
            actionsAreEmpty: selection.addActions.isEmpty,
            selectionEnabled: selection.selected.isNotEmpty,
            thisIndx: indx,
            ignoreSwipeGesture: selection.ignoreSwipe,
            bottomPadding: systemNavigationInsets,
            scrollController: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(i, state),
            selectUnselect: () => selection.selectOrUnselect(
                context, indx, cell, systemNavigationInsets),
            isSelected: selection.isSelected(indx),
            child: gridCell(context, cell, indx,
                hideAlias: hideAlias, tightMode: tightMode),
          ),
        );
      }),
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns),
    );
  }

  static Widget quiltedGrid<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    GridColumn columns,
    bool listView,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
    required double systemNavigationInsets,
    required double aspectRatio,
    required int randomNumber,
  }) {
    return SliverGrid.builder(
      itemCount: state.cellCount,
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: columns.number,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: columns.pattern(randomNumber),
      ),
      itemBuilder: (context, indx) {
        final cell = state.getCell(indx);

        return _WrapSelection(
          actionsAreEmpty: selection.addActions.isEmpty,
          selectionEnabled: selection.selected.isNotEmpty,
          thisIndx: indx,
          ignoreSwipeGesture: selection.ignoreSwipe,
          bottomPadding: systemNavigationInsets,
          scrollController: selection.controller,
          selectUntil: (i) => selection.selectUnselectUntil(i, state),
          selectUnselect: () => selection.selectOrUnselect(
              context, indx, cell, systemNavigationInsets),
          isSelected: selection.isSelected(indx),
          child: gridCell(context, cell, indx,
              hideAlias: hideAlias, tightMode: tightMode),
        );
      },
    );
  }

  static Widget segmentedRow<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    List<int> val,
    bool listView,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
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
                      index: indx,
                      cell: cell,
                      onPressed: null,
                      hideThumbnails: false),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: material.AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _WrapSelection(
                      actionsAreEmpty: selection.addActions.isEmpty,
                      selectionEnabled: selection.selected.isNotEmpty,
                      thisIndx: indx,
                      ignoreSwipeGesture: selection.ignoreSwipe,
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
                      child: gridCell(context, cell, indx,
                          hideAlias: hideAlias, tightMode: tightMode),
                    ),
                  ),
                );
        }).toList(),
      );

  static Widget segmentedRowCells<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    List<T> val,
    bool listView,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
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
                      index: cell.$1,
                      cell: cell.$2,
                      onPressed: null,
                      hideThumbnails: false),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints),
                  child: material.AspectRatio(
                    aspectRatio: aspectRatio,
                    child: _WrapSelection(
                      actionsAreEmpty: selection.addActions.isEmpty,
                      selectionEnabled: selection.selected.isNotEmpty,
                      thisIndx: -1,
                      ignoreSwipeGesture: selection.ignoreSwipe,
                      bottomPadding: systemNavigationInsets,
                      scrollController: selection.controller,
                      selectUntil: (i) =>
                          selection.selectUnselectUntil(i, state),
                      selectUnselect: () => selection.selectOrUnselect(
                          context, -1, cell.$2, systemNavigationInsets),
                      isSelected: selection.isSelected(-1),
                      child: gridCell(context, cell.$2, -1,
                          tightMode: tightMode, hideAlias: hideAlias),
                    ),
                  ),
                );
        }).toList(),
      );

  static Widget segmentsPrebuilt<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    bool listView,
    int columns,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
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
            return SegmentLabel(val.seg,
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
              hideAlias: hideAlias,
              tightMode: tightMode,
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
              hideAlias: hideAlias,
              tightMode: tightMode,
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
    GridSelection<T> selection,
    bool listView,
    int columns,
    MakeCellFunc<T> gridCell, {
    required bool hideAlias,
    required bool tightMode,
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
            return SegmentLabel(val.seg,
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
              hideAlias: hideAlias,
              tightMode: tightMode,
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
              hideAlias: hideAlias,
              tightMode: tightMode,
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
