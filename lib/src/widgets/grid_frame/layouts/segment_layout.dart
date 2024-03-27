// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_directories.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';
import 'package:gallery/src/widgets/grid_frame/parts/segment_label.dart';

import '../grid_frame.dart';

class SegmentLayout<T extends Cell>
    implements GridLayouter<T>, GridLayoutBehaviour {
  const SegmentLayout(
    this.segments,
    this.defaultSettings, {
    this.suggestionPrefix = const [],
  });

  final Segments<T> segments;
  final List<String> suggestionPrefix;

  @override
  bool get isList => false;

  @override
  final GridSettingsBase Function() defaultSettings;

  @override
  GridLayouter<J> makeFor<J extends Cell>(GridSettingsBase settings) {
    return SegmentLayout(
      segments,
      defaultSettings,
      suggestionPrefix: suggestionPrefix,
    ) as GridLayouter<J>;
  }

  @override
  List<Widget> call(BuildContext context, GridSettingsBase settings,
      GridFrameState<T> state) {
    if (segments.prebuiltSegments != null) {
      return prototype(
        context,
        segments,
        state.mutation,
        state.selection,
        settings.columns,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        functionality: state.widget.functionality,
        aspectRatio: settings.aspectRatio.value,
        refreshingStatus: state.refreshingStatus,
        gridSeed: state.widget.description.gridSeed,
        gridCell: (context, idx, blur) {
          return GridCell.frameDefault(
            context,
            idx,
            hideTitle: settings.hideName,
            isList: isList,
            state: state,
            blur: blur,
          );
        },
        gridCellT: (context, idx, cell, blur) {
          return GridCell.frameDefault(
            context,
            idx,
            blur: blur,
            hideTitle: settings.hideName,
            isList: isList,
            overrideCell: cell,
            state: state,
          );
        },
      );
    }
    final (s, t) = _segmentsFnc<T>(
      context,
      segments,
      state.mutation,
      state.selection,
      settings.columns,
      gridSeed: 1,
      systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
      functionality: state.widget.functionality,
      aspectRatio: settings.aspectRatio.value,
      refreshingStatus: state.refreshingStatus,
      suggestionPrefix: suggestionPrefix,
      gridCell: (context, idx, blur) {
        return GridCell.frameDefault(
          context,
          idx,
          isList: isList,
          blur: blur,
          imageAlign: Alignment.topCenter,
          hideTitle: settings.hideName,
          animated: PlayAnimationNotifier.maybeOf(context) ?? false,
          state: state,
        );
      },
      gridCellT: (context, idx, cell, blur) {
        return GridCell.frameDefault(
          context,
          idx,
          hideTitle: settings.hideName,
          isList: isList,
          overrideCell: cell,
          blur: blur,
          animated: PlayAnimationNotifier.maybeOf(context) ?? false,
          state: state,
        );
      },
    );

    // state.segTranslation = t;

    return s;
  }

  static List<Widget> prototype<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    GridColumn columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required GridCell<T> Function(BuildContext, int idx, bool blur) gridCell,
    required GridCell<T> Function(BuildContext, int idx, T, bool blur)
        gridCellT,
    required double aspectRatio,
    required int gridSeed,
    required double systemNavigationInsets,
  }) {
    final getCell = CellProvider.of<T>(context);

    final segRows = <_SegmentType>[];

    if (segments.injectedSegments.isNotEmpty) {
      segRows.add(_HeaderWithCells<T>(
        _SegSticky(
          segments.injectedLabel,
          true,
          null,
          unstickable: false,
        ),
        segments.injectedSegments.map((e) => (e, false)).toList(),
      ));
    }

    int prevCount = 0;
    for (final e in segments.prebuiltSegments!.entries) {
      segRows.add(
        _HeaderWithIdx(
          _SegSticky(
            e.key.translatedString(context),
            true,
            segments.onLabelPressed == null
                ? null
                : () {
                    if (segments.limitLabelChildren != null &&
                        segments.limitLabelChildren != 0 &&
                        !segments.limitLabelChildren!.isNegative) {
                      segments.onLabelPressed!(
                          e.key.translatedString(context),
                          List.generate(
                                  e.value > segments.limitLabelChildren!
                                      ? segments.limitLabelChildren!
                                      : e.value,
                                  (index) => index + prevCount)
                              .map((e) => getCell(e))
                              .toList());

                      return;
                    }

                    final cells = <T>[];

                    for (final i in List.generate(
                        e.value, (index) => index + prevCount)) {
                      cells.add(getCell(i - 1));
                    }

                    segments.onLabelPressed!(e.key.toString(), cells);
                  },
          ),
          _Idxs(List.generate(e.value, (index) => index + prevCount), false,
              false),
        ),
      );

      prevCount += e.value;
    }

    return _defaultBuilder(
      context,
      segRows,
      null,
      refreshingStatus: refreshingStatus,
      functionality: functionality,
      gridCell: gridCell,
      segments: segments,
      columns: columns,
      selection: selection,
      gridSeed: gridSeed,
      gridCellT: gridCellT,
      systemNavigationInsets: systemNavigationInsets,
      aspectRatio: aspectRatio,
    );
  }

  static (List<Widget>, List<int>) _segmentsFnc<T extends Cell>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    GridColumn columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required GridCell<T> Function(BuildContext, int idx, bool blur) gridCell,
    required GridCell<T> Function(BuildContext, int idx, T, bool blur)
        gridCellT,
    required double systemNavigationInsets,
    required int gridSeed,
    required List<String> suggestionPrefix,
    required double aspectRatio,
  }) {
    if (state.cellCount == 0) {
      return (const [], const []);
    }

    final segRows = <_SegmentType>[];
    final segMap = <String, _Idxs>{};

    final getCell = CellProvider.of<T>(context);

    final unsegmented = <int>[];

    final List<(T, bool)> suggestionCells = [];

    for (var i = 0; i < state.cellCount; i++) {
      final cell = getCell(i);

      if (segments.displayFirstCellInSpecial && suggestionPrefix.isNotEmpty) {
        for (final alias in suggestionPrefix) {
          if (alias.isEmpty) {
            continue;
          }

          if (!alias.indexOf("_").isNegative) {
            for (final e in alias.split("_")) {
              if (cell
                  .alias(false)
                  .startsWith(e.length <= 4 ? e : e.substring(0, 5))) {
                suggestionCells.add((
                  cell,
                  segments.isBlur?.call(segments.segment!(cell) ?? "") ?? false
                ));
              }
            }
          } else {
            if (cell.alias(false).startsWith(
                alias.length <= 4 ? alias : alias.substring(0, 5))) {
              suggestionCells.add((
                cell,
                segments.isBlur?.call(segments.segment!(cell) ?? "") ?? false
              ));
            }
          }
        }
      }

      final (res) = segments.segment!(cell);
      if (res == null) {
        unsegmented.add(i);
      } else {
        final previous = (segMap[res]) ?? _Idxs([], false, false);
        previous.list.add(i);
        segMap[res] = previous;
        // if (sticky) {
        //   final previous = (stickySegs[res]) ?? _Idxs([], blur);
        //   previous.list.add(i);
        //   stickySegs[res] = previous;
        // } else {

        // }
      }
    }

    if (segments.isSticky != null) {
      for (final e in segMap.entries) {
        if (segments.isSticky!(e.key)) {
          e.value.sticky = true;
        }
      }
    }

    if (segments.isBlur != null) {
      for (final e in segMap.entries) {
        if (segments.isBlur!(e.key)) {
          e.value.blur = true;
        }
      }
    }

    if (segments.displayFirstCellInSpecial) {
      segRows.add(_HeaderWithCells<T>(
        _SegSticky(
          segments.injectedLabel,
          true,
          null,
          unstickable: false,
          firstIsSpecial: true,
        ),
        (suggestionCells.isEmpty
                ? [
                    () {
                      final cell = getCell(0);

                      return (
                        cell,
                        segments.isBlur?.call(segments.segment!(cell) ?? "") ??
                            false
                      );
                    }()
                  ]
                : suggestionCells) +
            segments.injectedSegments.map((e) => (e, false)).toList(),
      ));
    } else {
      if (segments.injectedSegments.isNotEmpty) {
        segRows.add(_HeaderWithCells<T>(
          _SegSticky(
            segments.injectedLabel,
            true,
            null,
            unstickable: false,
          ),
          segments.injectedSegments.map((e) => (e, false)).toList(),
        ));
      }
    }

    void onLabelPressed(String key, List<int> value) {
      if (segments.limitLabelChildren != null &&
          segments.limitLabelChildren != 0 &&
          !segments.limitLabelChildren!.isNegative) {
        segments.onLabelPressed!(
            key,
            value
                .take(segments.limitLabelChildren!)
                .map((e) => getCell(e))
                .toList());

        return;
      }

      segments.onLabelPressed!(key, value.map((e) => getCell(e)).toList());
    }

    segMap.removeWhere((key, value) {
      if (value.list.length == 1 && !value.sticky) {
        unsegmented.add(value.list[0]);
        return true;
      }

      return false;
    });

    final List<int> predefined = [];

    segMap.forEach((key, value) {
      if (value.sticky) {
        segRows.add(_HeaderWithIdx(
          _SegSticky(
            key,
            true,
            segments.onLabelPressed == null
                ? null
                : () => onLabelPressed(key, value.list),
          ),
          value,
        ));

        predefined.addAll(value.list);
      }
    });

    segMap.forEach(
      (key, value) {
        if (!value.sticky) {
          segRows.add(_HeaderWithIdx(
            _SegSticky(
              key,
              false,
              segments.onLabelPressed == null
                  ? null
                  : () => onLabelPressed(key, value.list),
            ),
            value,
          ));

          predefined.addAll(value.list);
        }
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(_HeaderWithIdx(
        _SegSticky(
          segments.unsegmentedLabel,
          false,
          segments.onLabelPressed == null
              ? null
              : () => onLabelPressed(segments.unsegmentedLabel, unsegmented),
        ),
        _Idxs(unsegmented, false, false),
      ));
    }

    predefined.addAll(unsegmented);

    return (
      _defaultBuilder(
        context,
        segRows,
        predefined,
        refreshingStatus: refreshingStatus,
        functionality: functionality,
        gridCell: gridCell,
        columns: columns,
        gridSeed: gridSeed,
        segments: segments,
        selection: selection,
        gridCellT: gridCellT,
        systemNavigationInsets: systemNavigationInsets,
        aspectRatio: aspectRatio,
      ),
      predefined
    );
  }

  static List<Widget> _defaultBuilder<T extends Cell>(
    BuildContext context,
    List<_SegmentType> segmentList,
    List<int>? predefined, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required GridCell<T> Function(BuildContext, int idx, bool blur) gridCell,
    required Segments<T> segments,
    required GridColumn columns,
    required GridSelection<T> selection,
    required int gridSeed,
    required GridCell<T> Function(BuildContext, int idx, T, bool blur)
        gridCellT,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    final slivers = <Widget>[];

    for (final e in segmentList) {
      slivers.add(switch (e) {
        _HeaderWithIdx() => _segmentedRowHeaderIdxs(
            context,
            refreshingStatus.mutation,
            selection,
            e,
            gridSeed: gridSeed,
            gridCell,
            predefined: predefined,
            gridFunctionality: functionality,
            refreshingStatus: refreshingStatus,
            segments: segments,
            columns: columns,
            systemNavigationInsets: systemNavigationInsets,
            aspectRatio: aspectRatio,
          ),
        _HeaderWithCells<T>() => _segmentedRowHeaderCells<T>(
            context,
            refreshingStatus.mutation,
            selection,
            e,
            gridCellT,
            gridFunctionality: functionality,
            refreshingStatus: refreshingStatus,
            segments: segments,
            columns: columns,
            systemNavigationInsets: systemNavigationInsets,
            aspectRatio: aspectRatio,
          ),
        // _CellsProvided<Cell>() => throw UnimplementedError(),
        _HeaderWithCells<Cell>() => throw UnimplementedError(),
      });
    }

    return slivers;
  }

  static Widget _segmentedRowHeaderIdxs<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    _HeaderWithIdx val,
    GridCell<T> Function(BuildContext, int idx, bool blur) gridCell, {
    required GridColumn columns,
    List<int>? predefined,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
    required int gridSeed,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    return _defaultSegmentCard(
      context,
      state,
      selection,
      columns: columns,
      gridFunctionality: gridFunctionality,
      refreshingStatus: refreshingStatus,
      segments: segments,
      systemNavigationInsets: systemNavigationInsets,
      aspectRatio: aspectRatio,
      segmentLabel: val.header,
      blur: val.idxs.blur,
      sliver: SliverGrid.builder(
        itemCount: val.idxs.list.length,
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: columns.number,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: columns.pattern(gridSeed),
        ),
        itemBuilder: (context, index) {
          final realIdx = val.idxs.list[index];

          return WrapSelection(
            actionsAreEmpty: selection.addActions.isEmpty,
            selectionEnabled: selection.isNotEmpty,
            thisIndx: realIdx,
            ignoreSwipeGesture: selection.ignoreSwipe,
            bottomPadding: systemNavigationInsets,
            currentScroll: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(context, i,
                selectFrom: predefined),
            selectUnselect: () => selection.selectOrUnselect(context, realIdx),
            isSelected: selection.isSelected(realIdx),
            child: gridCell(context, realIdx, val.idxs.blur),
          );
        },
      ),
    );
  }

  static Widget _segmentedRowHeaderCells<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    _HeaderWithCells<T> val,
    GridCell<T> Function(BuildContext, int idx, T, bool blur) gridCell, {
    required GridColumn columns,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    return _defaultSegmentCard(
      context,
      state,
      selection,
      columns: columns,
      gridFunctionality: gridFunctionality,
      refreshingStatus: refreshingStatus,
      segments: segments,
      systemNavigationInsets: systemNavigationInsets,
      aspectRatio: aspectRatio,
      segmentLabel: val.header,
      blur: false,
      sliver: SliverGrid.builder(
        itemCount: val.cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns.number,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) {
          final cell = val.cells[index];

          return WrapSelection(
            actionsAreEmpty: selection.addActions.isEmpty,
            selectionEnabled: selection.isNotEmpty,
            thisIndx: -1,
            ignoreSwipeGesture: selection.ignoreSwipe,
            bottomPadding: systemNavigationInsets,
            currentScroll: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(context, i),
            selectUnselect: () => selection.selectOrUnselect(context, -1),
            isSelected: selection.isSelected(-1),
            child: gridCell(context, -1, cell.$1, cell.$2),
          );
        },
      ),
    );
  }
  // Sliver;

  static Widget _defaultSegmentCard<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection, {
    required GridColumn columns,
    required double systemNavigationInsets,
    required double aspectRatio,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
    required bool blur,
    required _SegSticky segmentLabel,
    required Widget sliver,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(left: 4),
              sliver: SliverToBoxAdapter(
                child: SegmentLabel(
                  segmentLabel.seg,
                  hidePinnedIcon: segments.hidePinnedIcon,
                  onPress: segmentLabel.onLabelPressed,
                  sticky: segmentLabel.sticky,
                  menuItems: [
                    if (segmentLabel.unstickable &&
                        segments.addToSticky != null &&
                        segmentLabel.seg != segments.unsegmentedLabel)
                      PopupMenuItem(
                        onTap: () {
                          if (segments.addToSticky!(segmentLabel.seg,
                              unsticky: segmentLabel.sticky ? true : null)) {
                            HapticFeedback.vibrate();
                            refreshingStatus.refresh(gridFunctionality);
                          }
                        },
                        child: Text(
                          segmentLabel.sticky ? "Unsticky" : "Sticky",
                        ), // TODO: change
                      ),
                    if (segments.blur != null)
                      PopupMenuItem(
                        onTap: () {
                          segments.blur!(segmentLabel.seg);
                          HapticFeedback.vibrate();
                          refreshingStatus.refresh(gridFunctionality);
                        },
                        child: Text(blur ? "Unblur" : "Blur"), // TODO: change
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(4),
              sliver: sliver,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegSticky {
  final String seg;
  final bool sticky;
  final void Function()? onLabelPressed;
  final bool unstickable;
  final bool firstIsSpecial;

  const _SegSticky(
    this.seg,
    this.sticky,
    this.onLabelPressed, {
    this.firstIsSpecial = false,
    this.unstickable = true,
  });
}

sealed class _SegmentType {
  const _SegmentType();
}

class _HeaderWithCells<T extends Cell> implements _SegmentType {
  const _HeaderWithCells(this.header, this.cells);

  final List<(T cell, bool blur)> cells;
  final _SegSticky header;
}

class _HeaderWithIdx implements _SegmentType {
  const _HeaderWithIdx(this.header, this.idxs);

  final _Idxs idxs;
  final _SegSticky header;
}

class _Idxs {
  _Idxs(this.list, this.blur, this.sticky);

  final List<int> list;
  bool blur;
  bool sticky;
}
