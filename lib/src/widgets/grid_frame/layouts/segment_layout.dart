// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:gallery/src/widgets/grid_frame/parts/segment_label.dart";
import "package:local_auth/local_auth.dart";

class SegmentLayout<T extends CellBase> extends StatefulWidget {
  const SegmentLayout({
    super.key,
    required this.segments,
    required this.suggestionPrefix,
    required this.getCell,
    required this.gridSeed,
    required this.mutation,
  });

  final Segments<T> segments;
  final List<String> suggestionPrefix;
  final T Function(int) getCell;
  final GridMutationInterface mutation;

  final int gridSeed;

  @override
  State<SegmentLayout<T>> createState() => _SegmentLayoutState();
}

class _SegmentLayoutState<T extends CellBase> extends State<SegmentLayout<T>> {
  Segments<T> get segments => widget.segments;
  List<String> get suggestionPrefix => widget.suggestionPrefix;
  GridMutationInterface get mutation => widget.mutation;
  T Function(int) get getCell => widget.getCell;

  late final StreamSubscription<int> _watcher;

  List<_SegmentType> _data = [];
  List<int>? predefined;

  @override
  void initState() {
    super.initState();

    _makeSegments();

    _watcher = mutation.listenCount((_) {
      _makeSegments();

      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  void _makeSegments() {
    if (segments.prebuiltSegments != null) {
      _data = _genSegPredef();
    } else {
      final ret = _genSegFnc();
      _data = ret.$1;
      predefined = ret.$2;
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
            .toList(),
      );

      return;
    }

    segments.onLabelPressed!(key, value.map((e) => getCell(e)).toList());
  }

  (List<_SegmentType>, List<int>) _genSegFnc() {
    final caps = segments.caps;

    final segRows = <_SegmentType>[];
    final segMap = <String, (List<int>, Set<SegmentModifier>)>{};

    final getCell = CellProvider.of<T>(context);

    final unsegmented = <int>[];

    final List<(T, bool)> suggestionCells = [];

    for (var i = 0; i < mutation.cellCount; i++) {
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
                suggestionCells.add(
                  (
                    cell,
                    caps
                        .modifiersFor(segments.segment!(cell) ?? "")
                        .contains(SegmentModifier.blur)
                  ),
                );
              }
            }
          } else {
            if (cell.alias(false).startsWith(
                  alias.length <= 4 ? alias : alias.substring(0, 4),
                )) {
              suggestionCells.add(
                (
                  cell,
                  caps
                      .modifiersFor(segments.segment!(cell) ?? "")
                      .contains(SegmentModifier.blur)
                ),
              );
            }
          }
        }
      }

      if (suggestionCells.isNotEmpty) {
        suggestionCells
            .sort((a, b) => a.$1.alias(false).compareTo(b.$1.alias(false)));
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
      segRows.add(
        _HeaderWithCells<T>(
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
          const {SegmentModifier.sticky},
        ),
      );
    } else {
      if (segments.injectedSegments.isNotEmpty) {
        segRows.add(
          _HeaderWithCells<T>(
            _SegSticky(
              segments.injectedLabel,
              null,
              unstickable: false,
            ),
            segments.injectedSegments.map((e) => (e, false)).toList(),
            const {SegmentModifier.sticky},
          ),
        );
      }
    }

    segMap.removeWhere((key, value) {
      if (value.$1.length == 1 && !value.$2.contains(SegmentModifier.sticky)) {
        if (value.$2.contains(SegmentModifier.blur)) {
          return false;
        }

        unsegmented.add(value.$1[0]);

        return true;
      }

      return false;
    });

    final List<int> predefined = [];

    segMap.forEach((key, value) {
      if (value.$2.contains(SegmentModifier.sticky)) {
        segRows.add(
          _HeaderWithIdx(
            _SegSticky(
              key,
              segments.onLabelPressed == null
                  ? null
                  : () => onLabelPressed(key, value.$1),
            ),
            value.$1,
            value.$2,
          ),
        );

        predefined.addAll(value.$1);
      }
    });

    segMap.forEach(
      (key, value) {
        if (!value.$2.contains(SegmentModifier.sticky)) {
          segRows.add(
            _HeaderWithIdx(
              _SegSticky(
                key,
                segments.onLabelPressed == null
                    ? null
                    : () => onLabelPressed(key, value.$1),
              ),
              value.$1,
              value.$2,
            ),
          );

          predefined.addAll(value.$1);
        }
      },
    );

    if (unsegmented.isNotEmpty) {
      segRows.add(
        _HeaderWithIdx(
          _SegSticky(
            segments.unsegmentedLabel,
            segments.onLabelPressed == null
                ? null
                : () => onLabelPressed(segments.unsegmentedLabel, unsegmented),
          ),
          unsegmented,
        ),
      );
    }

    predefined.addAll(unsegmented);

    return (segRows, predefined);
  }

  List<_SegmentType> _genSegPredef() {
    final segRows = <_SegmentType>[];

    if (segments.injectedSegments.isNotEmpty) {
      segRows.add(
        _HeaderWithCells<T>(
          _SegSticky(
            segments.injectedLabel,
            null,
            unstickable: false,
          ),
          segments.injectedSegments.map((e) => (e, false)).toList(),
          const {SegmentModifier.sticky},
        ),
      );
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
                          (index) => index + prevCount,
                        ).map((e) => getCell(e)).toList(),
                      );

                      return;
                    }

                    final cells = <T>[];

                    for (final i in List.generate(
                      e.value,
                      (index) => index + prevCount,
                    )) {
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

    return segRows;
  }

  @override
  Widget build(BuildContext context) {
    final extras = GridExtrasNotifier.of<T>(context);
    final config = GridConfiguration.of(context);

    return SegmentLayoutBody(
      data: _data,
      predefined: predefined,
      gridSeed: widget.gridSeed,
      selection: extras.selection,
      segments: segments,
      gridFunctionality: extras.functionality,
      config: config,
    );
  }
}

class SegmentLayoutBody<T extends CellBase> extends StatelessWidget {
  const SegmentLayoutBody({
    super.key,
    required this.data,
    required this.gridSeed,
    required this.selection,
    required this.predefined,
    required this.segments,
    required this.gridFunctionality,
    required this.config,
  });

  final List<_SegmentType> data;
  final int gridSeed;
  final GridSelection<T> selection;
  final List<int>? predefined;
  final Segments<T> segments;
  final GridFunctionality<T> gridFunctionality;
  final GridSettingsData config;

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];

    for (final e in data) {
      slivers.add(
        switch (e) {
          _HeaderWithIdx() => _SegRowHIdx<T>(
              selection: selection,
              val: e,
              gridSeed: gridSeed,
              predefined: predefined,
              gridFunctionality: gridFunctionality,
              segments: segments,
              config: config,
            ),
          _HeaderWithCells<T>() => _SegRowHCell<T>(
              selection: selection,
              val: e,
              gridFunctionality: gridFunctionality,
              segments: segments,
              config: config,
            ),
          _HeaderWithCells<CellBase>() => throw UnimplementedError(),
        },
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}

class _SegRowHCell<T extends CellBase> extends StatelessWidget {
  const _SegRowHCell({
    super.key,
    required this.selection,
    required this.val,
    required this.gridFunctionality,
    required this.segments,
    required this.config,
  });

  final GridSelection<T> selection;
  final _HeaderWithCells<T> val;
  final GridFunctionality<T> gridFunctionality;
  final Segments<T> segments;
  final GridSettingsData config;

  @override
  Widget build(BuildContext context) {
    return SegmentCard(
      selection: selection,
      columns: config.columns,
      gridFunctionality: gridFunctionality,
      segments: segments,
      aspectRatio: config.aspectRatio.value,
      segmentLabel: val.header,
      modifiers: val.modifiers,
      sliver: SliverGrid.builder(
        itemCount: val.cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.columns.number,
          childAspectRatio: config.aspectRatio.value,
        ),
        itemBuilder: (context, idx) {
          final cell = val.cells[idx];

          return WrapSelection<T>(
            selection: selection,
            description: cell.$1.description(),
            onPressed:
                cell.$1.tryAsPressable<T>(context, gridFunctionality, idx),
            functionality: gridFunctionality,
            selectFrom: null,
            thisIndx: -1,
            child: GridCell.frameDefault<T>(
              context,
              -1,
              cell.$1,
              blur: cell.$2,
              isList: false,
              imageAlign: Alignment.topCenter,
              hideTitle: config.hideName,
              animated: PlayAnimationNotifier.maybeOf(context) ?? false,
            ),
          );
        },
      ),
    );
  }
}

class _SegRowHIdx<T extends CellBase> extends StatelessWidget {
  const _SegRowHIdx({
    super.key,
    required this.selection,
    required this.val,
    this.predefined,
    required this.gridFunctionality,
    required this.segments,
    required this.gridSeed,
    required this.config,
  });

  final GridSelection<T> selection;
  final _HeaderWithIdx val;
  final List<int>? predefined;
  final GridFunctionality<T> gridFunctionality;
  final Segments<T> segments;
  final int gridSeed;
  final GridSettingsData config;

  @override
  Widget build(BuildContext context) {
    final toBlur = val.modifiers.contains(SegmentModifier.blur);
    final getCell = CellProvider.of<T>(context);

    return SegmentCard(
      selection: selection,
      columns: config.columns,
      gridFunctionality: gridFunctionality,
      segments: segments,
      aspectRatio: config.aspectRatio.value,
      segmentLabel: val.header,
      modifiers: val.modifiers,
      sliver: SliverGrid.builder(
        itemCount: val.list.length,
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: config.columns.number,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: config.columns.pattern(gridSeed),
        ),
        itemBuilder: (context, idx) {
          final realIdx = val.list[idx];
          final cell = getCell(realIdx);

          return WrapSelection<T>(
            thisIndx: realIdx,
            description: cell.description(),
            selectFrom: predefined,
            onPressed: cell.tryAsPressable(context, gridFunctionality, idx),
            functionality: gridFunctionality,
            selection: selection,
            child: GridCell.frameDefault(
              context,
              idx,
              cell,
              isList: false,
              blur: toBlur,
              imageAlign: Alignment.topCenter,
              hideTitle: config.hideName,
              animated: PlayAnimationNotifier.maybeOf(context) ?? false,
            ),
          );
        },
      ),
    );
  }
}

class SegmentCard<T extends CellBase> extends StatelessWidget {
  const SegmentCard({
    super.key,
    required this.selection,
    required this.columns,
    required this.aspectRatio,
    required this.gridFunctionality,
    required this.segments,
    required this.segmentLabel,
    required this.modifiers,
    required this.sliver,
  });

  final GridSelection<T> selection;
  final GridColumn columns;
  final double aspectRatio;
  final GridFunctionality<T> gridFunctionality;
  final Segments<T> segments;
  final _SegSticky segmentLabel;
  final Set<SegmentModifier> modifiers;

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
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
                  menuItems: segments.caps.ignoreButtons
                      ? const []
                      : [
                          if (segmentLabel.unstickable &&
                              segmentLabel.seg != segments.unsegmentedLabel)
                            PopupMenuItem(
                              onTap: () async {
                                if (toAuth && canAuthBiometric) {
                                  final success =
                                      await LocalAuthentication().authenticate(
                                    localizedReason:
                                        AppLocalizations.of(context)!
                                            .unstickyDirectory,
                                  );

                                  if (!success) {
                                    return;
                                  }
                                }

                                if (toSticky) {
                                  segments.caps.removeModifiers(
                                    [segmentLabel.seg],
                                    const {SegmentModifier.sticky},
                                  );
                                } else {
                                  segments.caps.addModifiers(
                                    [segmentLabel.seg],
                                    const {SegmentModifier.sticky},
                                  );
                                }

                                unawaited(HapticFeedback.vibrate());
                                unawaited(
                                  gridFunctionality.refreshingStatus.refresh(),
                                );
                              },
                              child: Text(
                                toSticky
                                    ? AppLocalizations.of(context)!.unpinTag
                                    : AppLocalizations.of(context)!
                                        .pinGroupLabel,
                              ),
                            ),
                          PopupMenuItem(
                            onTap: () async {
                              if (toAuth && canAuthBiometric) {
                                final success =
                                    await LocalAuthentication().authenticate(
                                  localizedReason: AppLocalizations.of(context)!
                                      .unblurDirectory,
                                );

                                if (!success) {
                                  return;
                                }
                              }

                              if (toBlur) {
                                segments.caps.removeModifiers(
                                  [segmentLabel.seg],
                                  const {SegmentModifier.blur},
                                );
                              } else {
                                segments.caps.addModifiers(
                                  [segmentLabel.seg],
                                  const {SegmentModifier.blur},
                                );
                              }

                              unawaited(HapticFeedback.vibrate());
                              unawaited(
                                gridFunctionality.refreshingStatus.refresh(),
                              );
                            },
                            child: Text(
                              toBlur
                                  ? AppLocalizations.of(context)!.unblur
                                  : AppLocalizations.of(context)!.blur,
                            ),
                          ),
                          if (segmentLabel.seg != segments.unsegmentedLabel &&
                              segments.unsegmentedLabel != segmentLabel.seg &&
                              segmentLabel.seg != "Booru")
                            PopupMenuItem(
                              enabled: canAuthBiometric,
                              onTap: !canAuthBiometric
                                  ? null
                                  : () async {
                                      final success =
                                          await LocalAuthentication()
                                              .authenticate(
                                        localizedReason:
                                            AppLocalizations.of(context)!
                                                .lockDirectory,
                                      );

                                      if (!success) {
                                        return;
                                      }

                                      if (toAuth) {
                                        segments.caps.removeModifiers(
                                          [segmentLabel.seg],
                                          const {SegmentModifier.auth},
                                        );
                                      } else {
                                        segments.caps.addModifiers(
                                          [segmentLabel.seg],
                                          const {SegmentModifier.auth},
                                        );
                                      }

                                      unawaited(HapticFeedback.vibrate());
                                      unawaited(
                                        gridFunctionality.refreshingStatus
                                            .refresh(),
                                      );
                                    },
                              child: Text(
                                toAuth
                                    ? AppLocalizations.of(context)!
                                        .notRequireAuth
                                    : AppLocalizations.of(context)!.requireAuth,
                              ),
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
  const _SegSticky(
    this.seg,
    this.onLabelPressed, {
    this.firstIsSpecial = false,
    this.unstickable = true,
  });
  final String seg;
  final void Function()? onLabelPressed;
  final bool unstickable;
  final bool firstIsSpecial;
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
