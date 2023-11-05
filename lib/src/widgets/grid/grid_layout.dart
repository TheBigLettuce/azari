// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

class NoteLayout<T extends Cell> implements GridLayouter<T> {
  @override
  final GridColumn columns;

  final List<String> Function(T cell) getText;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 2),
        itemBuilder: (context, index) {
          final note = state.widget.getCell(index);
          final provider = note.getCellData(false, context: context).thumb;

          final backgroundColor =
              note is NoteBase ? (note as NoteBase).backgroundColor : null;
          final textColor =
              note is NoteBase ? (note as NoteBase).textColor : null;

          return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              onTap: () => state.onPressed(context, note, index),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                      color: backgroundColor != null
                          ? Color(backgroundColor).harmonizeWith(
                              Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: constraints.minHeight * 0.2,
                                    height: constraints.maxHeight * 0.2,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    clipBehavior: Clip.antiAlias,
                                    child: provider != null
                                        ? OctoImage(
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                            progressIndicatorBuilder:
                                                (context, _) {
                                              return Container(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondaryContainer)
                                                  .animate(
                                                      onComplete: (controller) {
                                                controller.repeat();
                                              }).shimmer(
                                                      delay: 2.seconds,
                                                      duration: 500.ms);
                                            },
                                            image: provider)
                                        : null,
                                  )),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                    width: (constraints.maxHeight * 0.8),
                                    height: (constraints.maxHeight * 0.78),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: getText(note)
                                            .map((e) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.3),
                                                  child: Text(
                                                    e,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                        wordSpacing: 2.6,
                                                        color: textColor != null
                                                            ? Color(textColor)
                                                                .harmonizeWith(Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary)
                                                            : null,
                                                        letterSpacing: 1.3,
                                                        fontFamily:
                                                            "ZenKurenaido"),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    )),
                              )
                            ],
                          );
                        },
                      )),
                ),
              ));
        },
        itemCount: state.mutationInterface!.cellCount,
      ),
    );
  }

  @override
  bool get isList => false;

  const NoteLayout(this.columns, this.getText);
}

class SegmentListLayout<T extends Cell> implements GridLayouter<T> {
  final Segments<T> segments;

  @override
  final GridColumn columns;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    if (segments.prebuiltSegments != null) {
      return _GridLayouts.segmentsPrebuilt(
        context,
        segments,
        state._state,
        state.selection,
        true,
        columns.number,
        state.makeGridCell,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: 1,
      );
    }
    final (s, t) = _GridLayouts.segmentsFnc<T>(
      context,
      segments,
      state._state,
      state.selection,
      true,
      columns.number,
      state.makeGridCell,
      systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
      aspectRatio: 1,
    );

    state.segTranslation = t;

    return s;
  }

  @override
  bool get isList => true;

  const SegmentListLayout(this.segments, this.columns);
}

class SegmentLayout<T extends Cell> implements GridLayouter<T> {
  final Segments<T> segments;
  final settings.GridAspectRatio aspectRatio;

  @override
  final GridColumn columns;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    if (segments.prebuiltSegments != null) {
      return _GridLayouts.segmentsPrebuilt(
        context,
        segments,
        state._state,
        state.selection,
        false,
        columns.number,
        state.makeGridCell,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: aspectRatio.value,
      );
    }
    final (s, t) = _GridLayouts.segmentsFnc<T>(
      context,
      segments,
      state._state,
      state.selection,
      false,
      columns.number,
      state.makeGridCell,
      systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
      aspectRatio: aspectRatio.value,
    );

    state.segTranslation = t;

    return s;
  }

  @override
  bool get isList => false;

  const SegmentLayout(this.segments, this.columns, this.aspectRatio);
}

class GridListLayout<T extends Cell> implements GridLayouter<T> {
  @override
  final GridColumn columns;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return _GridLayouts.grid<T>(context, state._state, state.selection,
        columns.number, true, state.makeGridCell,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: 1);
  }

  @override
  bool get isList => true;

  const GridListLayout(this.columns);
}

class GridLayout<T extends Cell> implements GridLayouter<T> {
  final settings.GridAspectRatio aspectRatio;

  @override
  final GridColumn columns;

  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return _GridLayouts.grid<T>(context, state._state, state.selection,
        columns.number, false, state.makeGridCell,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: aspectRatio.value);
  }

  @override
  bool get isList => false;

  const GridLayout(this.columns, this.aspectRatio);
}

class ListLayout<T extends Cell> implements GridLayouter<T> {
  @override
  Widget call(BuildContext context, CallbackGridState<T> state) {
    return _GridLayouts.list<T>(context, state._state, state.selection,
        state.widget.systemNavigationInsets.bottom,
        onPressed: state.widget.unpressable ? null : state.onPressed);
  }

  @override
  GridColumn? get columns => null;

  @override
  bool get isList => true;

  const ListLayout();
}

/// [CallbackGrid] supports multiple layout modes.
/// [GridLayout] actually implements them all.
abstract class _GridLayouts {
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
    ).animate(key: cell.uniqueKey()).fadeIn();
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
