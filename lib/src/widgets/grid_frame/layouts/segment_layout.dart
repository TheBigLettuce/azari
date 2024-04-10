// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';
import 'package:gallery/src/widgets/grid_frame/parts/segment_label.dart';
import 'package:local_auth/local_auth.dart';

import '../grid_frame.dart';

class SegmentLayout<T extends CellBase>
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
  GridLayouter<J> makeFor<J extends CellBase>(GridSettingsBase settings) {
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
        functionality: state.widget.functionality,
        aspectRatio: settings.aspectRatio.value,
        refreshingStatus: state.refreshingStatus,
        gridSeed: state.widget.description.gridSeed,
        gridCell: (context, idx, cell, blur) {
          return GridCell.frameDefault(
            context,
            idx,
            cell,
            imageAlign: Alignment.topCenter,
            blur: blur,
            hideTitle: settings.hideName,
            isList: isList,
            state: state,
          );
        },
      );
    }
    final (s, t) = _segmentsFnc<T>(
        context, segments, state.mutation, state.selection, settings.columns,
        gridSeed: 1,
        functionality: state.widget.functionality,
        aspectRatio: settings.aspectRatio.value,
        refreshingStatus: state.refreshingStatus,
        suggestionPrefix: suggestionPrefix,
        gridCell: (context, idx, cell, blur) {
      return GridCell.frameDefault(
        context,
        idx,
        cell,
        isList: isList,
        blur: blur,
        imageAlign: Alignment.topCenter,
        hideTitle: settings.hideName,
        animated: PlayAnimationNotifier.maybeOf(context) ?? false,
        state: state,
      );
    });

    return s;
  }

  static List<Widget> prototype<T extends CellBase>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface state,
    GridSelection<T> selection,
    GridColumn columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required GridCell<T> Function(BuildContext, int idx, T, bool blur) gridCell,
    required double aspectRatio,
    required int gridSeed,
  }) {
    final getCell = CellProvider.of<T>(context);

    final segRows = <_SegmentType>[];

    if (segments.injectedSegments.isNotEmpty) {
      segRows.add(_HeaderWithCells<T>(
        _SegSticky(
          segments.injectedLabel,
          null,
          unstickable: false,
        ),
        segments.injectedSegments.map((e) => (e, false)).toList(),
        const {SegmentModifier.sticky},
      ));
    }

    int prevCount = 0;
    for (final e in segments.prebuiltSegments!.entries) {
      segRows.add(
        _HeaderWithIdx(
          _SegSticky(
            e.key.translatedString(context),
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
          List.generate(e.value, (index) => index + prevCount),
          const {SegmentModifier.sticky},
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
      aspectRatio: aspectRatio,
    );
  }

  static (List<Widget>, List<int>) _segmentsFnc<T extends CellBase>(
    BuildContext context,
    Segments<T> segments,
    GridMutationInterface state,
    GridSelection<T> selection,
    GridColumn columns, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required GridCell<T> Function(BuildContext, int idx, T cell, bool blur)
        gridCell,
    required int gridSeed,
    required List<String> suggestionPrefix,
    required double aspectRatio,
  }) {
    if (state.cellCount == 0) {
      return (const [], const []);
    }

    final caps = segments.caps;

    final segRows = <_SegmentType>[];
    final segMap = <String, (List<int>, Set<SegmentModifier>)>{};

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
                  .startsWith(e.length <= 4 ? e : e.substring(0, 4))) {
                suggestionCells.add((
                  cell,
                  caps
                      .modifiersFor(segments.segment!(cell) ?? "")
                      .contains(SegmentModifier.blur)
                ));
              }
            }
          } else {
            if (cell.alias(false).startsWith(
                alias.length <= 4 ? alias : alias.substring(0, 4))) {
              suggestionCells.add((
                cell,
                caps
                    .modifiersFor(segments.segment!(cell) ?? "")
                    .contains(SegmentModifier.blur)
              ));
            }
          }
        }
      }

      final (res) = segments.segment!(cell);
      if (res == null) {
        unsegmented.add(i);
      } else {
        final previous = (segMap[res]) ?? ([], {});
        previous.$1.add(i);
        segMap[res] = previous;
      }
    }

    for (final e in segMap.entries) {
      e.value.$2.addAll(caps.modifiersFor(e.key));
    }

    if (segments.displayFirstCellInSpecial) {
      segRows.add(_HeaderWithCells<T>(
          _SegSticky(
            segments.injectedLabel,
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
                          caps
                              .modifiersFor(segments.segment!(cell) ?? "")
                              .contains(SegmentModifier.blur)
                        );
                      }()
                    ]
                  : suggestionCells) +
              segments.injectedSegments.map((e) => (e, false)).toList(),
          const {SegmentModifier.sticky}));
    } else {
      if (segments.injectedSegments.isNotEmpty) {
        segRows.add(_HeaderWithCells<T>(
          _SegSticky(
            segments.injectedLabel,
            null,
            unstickable: false,
          ),
          segments.injectedSegments.map((e) => (e, false)).toList(),
          const {SegmentModifier.sticky},
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
      if (value.$1.length == 1 && !value.$2.contains(SegmentModifier.sticky)) {
        unsegmented.add(value.$1[0]);
        return true;
      }

      return false;
    });

    final List<int> predefined = [];

    segMap.forEach((key, value) {
      if (value.$2.contains(SegmentModifier.sticky)) {
        segRows.add(_HeaderWithIdx(
            _SegSticky(
              key,
              segments.onLabelPressed == null
                  ? null
                  : () => onLabelPressed(key, value.$1),
            ),
            value.$1,
            value.$2));

        predefined.addAll(value.$1);
      }
    });

    segMap.forEach(
      (key, value) {
        if (!value.$2.contains(SegmentModifier.sticky)) {
          segRows.add(_HeaderWithIdx(
            _SegSticky(
              key,
              segments.onLabelPressed == null
                  ? null
                  : () => onLabelPressed(key, value.$1),
            ),
            value.$1,
            value.$2,
          ));

          predefined.addAll(value.$1);
        }
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(_HeaderWithIdx(
        _SegSticky(
          segments.unsegmentedLabel,
          segments.onLabelPressed == null
              ? null
              : () => onLabelPressed(segments.unsegmentedLabel, unsegmented),
        ),
        unsegmented,
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
        aspectRatio: aspectRatio,
      ),
      predefined
    );
  }

  static List<Widget> _defaultBuilder<T extends CellBase>(
    BuildContext context,
    List<_SegmentType> segmentList,
    List<int>? predefined, {
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> functionality,
    required Segments<T> segments,
    required GridColumn columns,
    required GridSelection<T> selection,
    required int gridSeed,
    required GridCell<T> Function(BuildContext, int idx, T cell, bool blur)
        gridCell,
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
            aspectRatio: aspectRatio,
          ),
        _HeaderWithCells<T>() => _segmentedRowHeaderCells<T>(
            context,
            refreshingStatus.mutation,
            selection,
            e,
            gridCell,
            gridFunctionality: functionality,
            refreshingStatus: refreshingStatus,
            segments: segments,
            columns: columns,
            aspectRatio: aspectRatio,
          ),
        // _CellsProvided<Cell>() => throw UnimplementedError(),
        _HeaderWithCells<CellBase>() => throw UnimplementedError(),
      });
    }

    return slivers;
  }

  static Widget _segmentedRowHeaderIdxs<T extends CellBase>(
    BuildContext context,
    GridMutationInterface state,
    GridSelection<T> selection,
    _HeaderWithIdx val,
    GridCell<T> Function(BuildContext, int idx, T cell, bool blur) gridCell, {
    required GridColumn columns,
    List<int>? predefined,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
    required int gridSeed,
    required double aspectRatio,
  }) {
    final toBlur = val.modifiers.contains(SegmentModifier.blur);
    final getCell = CellProvider.of<T>(context);

    return _defaultSegmentCard(
      context,
      state,
      selection,
      columns: columns,
      gridFunctionality: gridFunctionality,
      refreshingStatus: refreshingStatus,
      segments: segments,
      aspectRatio: aspectRatio,
      segmentLabel: val.header,
      modifiers: val.modifiers,
      sliver: SliverGrid.builder(
        itemCount: val.list.length,
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: columns.number,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: columns.pattern(gridSeed),
        ),
        itemBuilder: (context, index) {
          final realIdx = val.list[index];
          final cell = getCell(realIdx);

          return WrapSelection<T>(
            thisIndx: realIdx,
            description: cell.description(),
            selectFrom: predefined,
            onPressed: cell.tryAsPressable(context, gridFunctionality, index),
            functionality: gridFunctionality,
            selection: selection,
            child: gridCell(context, realIdx, cell, toBlur),
          );
        },
      ),
    );
  }

  static Widget _segmentedRowHeaderCells<T extends CellBase>(
    BuildContext context,
    GridMutationInterface state,
    GridSelection<T> selection,
    _HeaderWithCells<T> val,
    GridCell<T> Function(BuildContext, int idx, T cell, bool blur) gridCell, {
    required GridColumn columns,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
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
      aspectRatio: aspectRatio,
      segmentLabel: val.header,
      modifiers: val.modifiers,
      sliver: SliverGrid.builder(
        itemCount: val.cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns.number,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) {
          final cell = val.cells[index];

          return WrapSelection<T>(
            selection: selection,
            description: cell.$1.description(),
            onPressed:
                cell.$1.tryAsPressable<T>(context, gridFunctionality, index),
            functionality: gridFunctionality,
            selectFrom: null,
            thisIndx: -1,
            child: gridCell(context, -1, cell.$1, cell.$2),
          );
        },
      ),
    );
  }
  // Sliver;

  static Widget _defaultSegmentCard<T extends CellBase>(
    BuildContext context,
    GridMutationInterface state,
    GridSelection<T> selection, {
    required GridColumn columns,
    required double aspectRatio,
    required GridRefreshingStatus<T> refreshingStatus,
    required GridFunctionality<T> gridFunctionality,
    required Segments<T> segments,
    required _SegSticky segmentLabel,
    required Set<SegmentModifier> modifiers,
    required Widget sliver,
  }) {
    final toSticky = modifiers.contains(SegmentModifier.sticky);
    final toBlur = modifiers.contains(SegmentModifier.blur);
    final toAuth = modifiers.contains(SegmentModifier.auth);

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
                  sticky: toSticky,
                  menuItems: [
                    if (segmentLabel.unstickable &&
                        segmentLabel.seg != segments.unsegmentedLabel)
                      PopupMenuItem(
                        onTap: () async {
                          if (toAuth && canAuthBiometric) {
                            final success = await LocalAuthentication()
                                .authenticate(
                                    localizedReason: "Unsticky directory");

                            if (!success) {
                              return;
                            }
                          }

                          if (toSticky) {
                            segments.caps.removeModifiers([segmentLabel.seg],
                                const {SegmentModifier.sticky});
                          } else {
                            segments.caps.addModifiers([segmentLabel.seg],
                                const {SegmentModifier.sticky});
                          }

                          HapticFeedback.vibrate();
                          refreshingStatus.refresh(gridFunctionality);
                        },
                        child: Text(
                          toSticky ? "Unsticky" : "Sticky",
                        ), // TODO: change
                      ),
                    PopupMenuItem(
                      onTap: () async {
                        if (toAuth && canAuthBiometric) {
                          final success = await LocalAuthentication()
                              .authenticate(
                                  localizedReason: "Unblur directory");

                          if (!success) {
                            return;
                          }
                        }

                        if (toBlur) {
                          segments.caps.removeModifiers(
                              [segmentLabel.seg], const {SegmentModifier.blur});
                        } else {
                          segments.caps.addModifiers(
                              [segmentLabel.seg], const {SegmentModifier.blur});
                        }

                        HapticFeedback.vibrate();
                        refreshingStatus.refresh(gridFunctionality);
                      },
                      child: Text(toBlur ? "Unblur" : "Blur"), // TODO: change
                    ),
                    if (segmentLabel.seg != segments.unsegmentedLabel &&
                        segments.unsegmentedLabel != segmentLabel.seg &&
                        segmentLabel.seg != "Booru")
                      PopupMenuItem(
                        enabled: canAuthBiometric,
                        onTap: !canAuthBiometric
                            ? null
                            : () async {
                                final success = await LocalAuthentication()
                                    .authenticate(
                                        localizedReason:
                                            "Lock directory group");

                                if (!success) {
                                  return;
                                }

                                if (toAuth) {
                                  segments.caps.removeModifiers(
                                      [segmentLabel.seg],
                                      const {SegmentModifier.auth});
                                } else {
                                  segments.caps.addModifiers([segmentLabel.seg],
                                      const {SegmentModifier.auth});
                                }

                                HapticFeedback.vibrate();
                                refreshingStatus.refresh(gridFunctionality);
                              },
                        child: Text(toAuth ? "Unauth" : "Require auth"),
                      )
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
  final void Function()? onLabelPressed;
  final bool unstickable;
  final bool firstIsSpecial;

  const _SegSticky(
    this.seg,
    this.onLabelPressed, {
    this.firstIsSpecial = false,
    this.unstickable = true,
  });
}

sealed class _SegmentType {
  const _SegmentType();
}

class _HeaderWithCells<T extends CellBase> implements _SegmentType {
  const _HeaderWithCells(this.header, this.cells, this.modifiers);

  final List<(T, bool)> cells;
  final _SegSticky header;
  final Set<SegmentModifier> modifiers;
}

class _HeaderWithIdx implements _SegmentType {
  const _HeaderWithIdx(this.header, this.list, [this.modifiers = const {}]);

  final List<int> list;
  final _SegSticky header;
  final Set<SegmentModifier> modifiers;
}
