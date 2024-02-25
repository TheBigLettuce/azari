// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';
import 'package:gallery/src/widgets/grid/parts/segment_label.dart';

import '../grid_frame.dart';

class SegmentLayout<T extends Cell> implements GridLayouter<T> {
  final Segments<T> segments;
  final GridAspectRatio aspectRatio;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    if (segments.prebuiltSegments != null) {
      return [
        prototype(
          context,
          segments,
          state.mutation,
          state.selection,
          columns.number,
          systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
          aspectRatio: aspectRatio.value,
          refreshingStatus: state.refreshingStatus,
          gridCell: (context, idx) {
            return GridCell.frameDefault(
              context,
              idx,
              state: state,
            );
          },
          gridCellT: (context, idx, cell) {
            return GridCell.frameDefault(
              context,
              idx,
              state: state,
            );
          },
        )
      ];
    }
    final (s, t) = _segmentsFnc<T>(
      context,
      segments,
      state.mutation,
      state.selection,
      columns.number,
      systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
      aspectRatio: aspectRatio.value,
      refreshingStatus: state.refreshingStatus,
      gridCell: (context, idx) {
        return GridCell.frameDefault(
          context,
          idx,
          state: state,
        );
      },
      gridCellT: (context, idx, cell) {
        return GridCell.frameDefault(
          context,
          idx,
          state: state,
        );
      },
    );

    // state.segTranslation = t;

    return [s];
  }

  static Widget prototype<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    int columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required MakeCellFunc<T> gridCell,
    required GridCell<T> Function(BuildContext, int idx, T) gridCellT,
    required double aspectRatio,
    required double systemNavigationInsets,
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
                              refreshingStatus.refresh();
                            }
                          }
                        : null,
                onPress: val.onLabelPressed);
          } else if (val is List<int>) {
            return _segmentedRow(
              context,
              state,
              selection,
              val,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
            );
          } else if (val is List<T>) {
            return _segmentedRowCells(
              context,
              state,
              selection,
              val,
              gridCellT,
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

  static (Widget, List<int>) _segmentsFnc<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    int columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required MakeCellFunc<T> gridCell,
    required GridCell<T> Function(BuildContext, int idx, T) gridCellT,
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
                              refreshingStatus.refresh();
                            }
                          }
                        : null,
                onPress: val.onLabelPressed);
          } else if (val is List<int>) {
            return _segmentedRow(
              context,
              state,
              selection,
              val,
              gridCell,
              constraints: constraints,
              systemNavigationInsets: systemNavigationInsets,
              aspectRatio: aspectRatio,
              predefined: () => predefined,
            );
          } else if (val is List<T>) {
            return _segmentedRowCells(
              context,
              state,
              selection,
              val,
              gridCellT,
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

  static Widget _segmentedRow<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    List<int> val,
    MakeCellFunc<T> gridCell, {
    List<int> Function()? predefined,
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) =>
      Row(
        children: val.map((indx) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: WrapSelection(
                actionsAreEmpty: selection.addActions.isEmpty,
                selectionEnabled: selection.isNotEmpty,
                thisIndx: indx,
                ignoreSwipeGesture: selection.ignoreSwipe,
                bottomPadding: systemNavigationInsets,
                currentScroll: selection.controller,
                selectUntil: (i) {
                  if (predefined != null) {
                    selection.selectUnselectUntil(indx, state,
                        selectFrom: predefined());
                  } else {
                    selection.selectUnselectUntil(indx, state);
                  }
                },
                selectUnselect: () => selection.selectOrUnselect(context, indx),
                isSelected: selection.isSelected(indx),
                child: gridCell(context, indx),
              ),
            ),
          );
        }).toList(),
      );

  static Widget _segmentedRowCells<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    List<T> val,
    GridCell<T> Function(BuildContext, int idx, T) gridCell, {
    required double constraints,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) =>
      Row(
        children: val.indexed.map((cell) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: WrapSelection(
                actionsAreEmpty: selection.addActions.isEmpty,
                selectionEnabled: selection.isNotEmpty,
                thisIndx: -1,
                ignoreSwipeGesture: selection.ignoreSwipe,
                bottomPadding: systemNavigationInsets,
                currentScroll: selection.controller,
                selectUntil: (i) => selection.selectUnselectUntil(i, state),
                selectUnselect: () => selection.selectOrUnselect(context, -1),
                isSelected: selection.isSelected(-1),
                child: gridCell(context, cell.$1, cell.$2),
              ),
            ),
          );
        }).toList(),
      );

  @override
  bool get isList => false;

  const SegmentLayout(
    this.segments,
    this.columns,
    this.aspectRatio,
  );
}

class _SegSticky {
  final String seg;
  final bool sticky;
  final void Function()? onLabelPressed;
  final bool unstickable;

  const _SegSticky(
    this.seg,
    this.sticky,
    this.onLabelPressed, {
    this.unstickable = true,
  });
}
