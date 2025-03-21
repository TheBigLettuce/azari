// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:ui";

import "package:azari/init_main/app_info.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/resource_source/source_storage.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/parts/segment_label.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:local_auth/local_auth.dart";

abstract class SegmentKey {
  const SegmentKey();

  String translatedString(AppLocalizations context);
}

sealed class SegmentInjectedCellType<T> {}

abstract class AsyncCell<T> implements SegmentInjectedCellType<T> {
  Key uniqueKey();

  StreamSubscription<T?> watch(void Function(T?) f, [bool fire = false]);
}

class SyncCell<T> implements SegmentInjectedCellType<T> {
  const SyncCell(this.value);

  final T value;
}

/// Segments of the grid.
class Segments<T> {
  const Segments(
    this.unsegmentedLabel, {
    this.segment,
    this.limitLabelChildren,
    this.prebuiltSegments,
    this.onLabelPressed,
    required this.caps,
    this.displayFirstCellInSpecial = false,
    this.hidePinnedIcon = false,
    this.injectedSegments = const [],
    required this.injectedLabel,
  }) : assert(prebuiltSegments == null || segment == null);

  final bool hidePinnedIcon;
  final bool displayFirstCellInSpecial;

  final int? limitLabelChildren;

  /// Under [unsegmentedLabel] appear cells on which [segment] returns null,
  /// or are single standing.
  final String unsegmentedLabel;

  /// Under [injectedLabel] appear [injectedSegments].
  /// All pinned.
  final String injectedLabel;

  /// [injectedSegments] make it possible to add foreign cell on the segmented grid.
  /// [segment] is not called on [injectedSegments].
  final List<SegmentInjectedCellType<T>> injectedSegments;

  /// Segmentation function.
  /// If [sticky] is true, then even if the cell is single standing it will appear
  /// as a single element segment on the grid.

  final Map<SegmentKey, int>? prebuiltSegments;

  final SegmentCapability caps;

  final String? Function(T cell)? segment;

  final void Function(String label, List<T> children)? onLabelPressed;
}

enum SegmentModifier {
  blur,
  auth,
  sticky;
}

abstract interface class SegmentCapability {
  const factory SegmentCapability.empty() = _SegmentCapabilityEmpty;
  const factory SegmentCapability.alwaysPinned() =
      _SegmentCapabilityAlwaysPinned;

  Set<SegmentModifier> get(String seg);

  bool get ignoreButtons;

  void add(List<String> segments, Set<SegmentModifier> m);
  void remove(List<String> segments, Set<SegmentModifier> m);
}

class _SegmentCapabilityAlwaysPinned implements SegmentCapability {
  const _SegmentCapabilityAlwaysPinned();

  @override
  bool get ignoreButtons => true;

  @override
  void add(List<String> segments, Set<SegmentModifier> m) {}

  @override
  Set<SegmentModifier> get(String seg) => const {SegmentModifier.sticky};

  @override
  void remove(List<String> segments, Set<SegmentModifier> m) {}
}

class _SegmentCapabilityEmpty implements SegmentCapability {
  const _SegmentCapabilityEmpty();

  @override
  bool get ignoreButtons => true;

  @override
  void add(List<String> segments, Set<SegmentModifier> m) {}

  @override
  Set<SegmentModifier> get(String seg) => const {};

  @override
  void remove(List<String> segments, Set<SegmentModifier> m) {}
}

class SegmentLayout<T extends CellBase> extends StatefulWidget {
  const SegmentLayout({
    super.key,
    required this.segments,
    required this.suggestionPrefix,
    required this.gridSeed,
    required this.storage,
    required this.progress,
    required this.l10n,
    required this.selection,
  });

  final ShellSelectionHolder? selection;

  final int gridSeed;

  final Segments<T> segments;
  final List<String> suggestionPrefix;
  final ReadOnlyStorage<int, T> storage;
  final RefreshingProgress progress;
  final AppLocalizations l10n;

  @override
  State<SegmentLayout<T>> createState() => _SegmentLayoutState();
}

class _SegmentLayoutState<T extends CellBase> extends State<SegmentLayout<T>>
    with ResetSelectionOnUpdate<T, SegmentLayout<T>> {
  Segments<T> get segments => widget.segments;
  List<String> get suggestionPrefix => widget.suggestionPrefix;

  @override
  ReadOnlyStorage<int, T> get source => widget.storage;

  @override
  ShellSelectionHolder? get selection => widget.selection;

  @override
  void Function()? get onUpdate => _makeSegments;

  List<_SegmentType> _data = [];
  List<int>? predefined;

  @override
  void initState() {
    super.initState();

    _makeSegments();
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
        value.take(segments.limitLabelChildren!).map((e) => source[e]).toList(),
      );

      return;
    }

    segments.onLabelPressed!(key, value.map((e) => source[e]).toList());
  }

  (List<_SegmentType>, List<int>) _genSegFnc() {
    final caps = segments.caps;

    final segRows = <_SegmentType>[];
    final segMap = <String, (List<int>, Set<SegmentModifier>)>{};

    final unsegmented = <int>[];

    final List<(SegmentInjectedCellType<T>, bool)> suggestionCells = [];

    for (var i = 0; i < source.count; i++) {
      final cell = source[i];

      if (segments.displayFirstCellInSpecial && suggestionPrefix.isNotEmpty) {
        for (final alias in suggestionPrefix) {
          if (alias.isEmpty) {
            continue;
          }

          if (!alias.indexOf("_").isNegative) {
            for (final e in alias.split("_")) {
              if (cell
                  .alias(false)
                  .startsWith(e.length <= 6 ? e : e.substring(0, 6))) {
                suggestionCells.add(
                  (
                    SyncCell(cell),
                    caps
                        .get(segments.segment!(cell) ?? "")
                        .contains(SegmentModifier.blur)
                  ),
                );
                break;
              }
            }
          } else {
            if (cell.alias(false).startsWith(
                  alias.length <= 6 ? alias : alias.substring(0, 6),
                )) {
              suggestionCells.add(
                (
                  SyncCell(cell),
                  caps
                      .get(segments.segment!(cell) ?? "")
                      .contains(SegmentModifier.blur)
                ),
              );
            }
          }
        }
      }

      if (suggestionCells.isNotEmpty) {
        suggestionCells.sort(
          (a, b) => (a.$1 as SyncCell<T>)
              .value
              .alias(false)
              .compareTo((b.$1 as SyncCell<T>).value.alias(false)),
        );
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
      e.value.$2.addAll(caps.get(e.key));
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
                  ? <(SegmentInjectedCellType<T>, bool)>[
                      if (source.isNotEmpty)
                        () {
                          final cell = source[0];

                          return (
                            SyncCell(cell),
                            caps
                                .get(segments.segment!(cell) ?? "")
                                .contains(SegmentModifier.blur)
                          );
                        }(),
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
            e.key.translatedString(widget.l10n),
            segments.onLabelPressed == null
                ? null
                : () {
                    if (segments.limitLabelChildren != null &&
                        segments.limitLabelChildren != 0 &&
                        !segments.limitLabelChildren!.isNegative) {
                      segments.onLabelPressed!(
                        e.key.translatedString(widget.l10n),
                        List.generate(
                          e.value > segments.limitLabelChildren!
                              ? segments.limitLabelChildren!
                              : e.value,
                          (index) => index + prevCount,
                        ).map((e) => source[e]).toList(),
                      );

                      return;
                    }

                    final cells = <T>[];

                    for (final i in List.generate(
                      e.value,
                      (index) => index + prevCount,
                    )) {
                      cells.add(source[i - 1]);
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
    final config = ShellConfiguration.of(context);

    return SegmentLayoutBody(
      data: _data,
      predefined: predefined,
      gridSeed: widget.gridSeed,
      selection: selection,
      segments: segments,
      config: config,
      storage: source,
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
    required this.config,
    required this.storage,
  });

  final int gridSeed;

  final ReadOnlyStorage<int, T> storage;

  final List<_SegmentType> data;
  final ShellSelectionHolder? selection;
  final List<int>? predefined;
  final Segments<T> segments;
  final ShellConfigurationData config;

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
              segments: segments,
              storage: storage,
              config: config,
            ),
          _HeaderWithCells<T>() => _SegRowHCell<T>(
              selection: selection,
              val: e,
              segments: segments,
            ),
          _HeaderWithCells<CellBase>() => throw UnimplementedError(),
        },
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}

class _SegRowHCell<T extends CellBase> extends StatefulWidget {
  const _SegRowHCell({
    super.key,
    required this.selection,
    required this.val,
    required this.segments,
  });

  final ShellSelectionHolder? selection;
  final _HeaderWithCells<T> val;
  final Segments<T> segments;

  @override
  State<_SegRowHCell<T>> createState() => __SegRowHCellState();
}

class __SegRowHCellState<T extends CellBase> extends State<_SegRowHCell<T>> {
  final _addedCells = <(SyncCell<T>, bool)>[];
  late final List<StreamSubscription<T?>> _watchers;

  @override
  void initState() {
    super.initState();

    _watchers = widget.val.cells
        .where((e) => e.$1 is AsyncCell<T>)
        .map(
          (e) => (e.$1 as AsyncCell<T>).watch(
            (newE) {
              if (newE != null) {
                _addedCells.removeWhere(
                  (e) => e.$1.value.uniqueKey() == newE.uniqueKey(),
                );
                _addedCells.add((SyncCell(newE), false));
              } else {
                _addedCells.removeWhere(
                  (e2) =>
                      e2.$1.value.uniqueKey() ==
                      (e.$1 as AsyncCell<T>).uniqueKey(),
                );
              }

              setState(() {});
            },
            true,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final e in _watchers) {
      e.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final items = widget.val.cells
            .where((e) => e.$1 is! AsyncCell<T>)
            .map((e) => (e.$1 as SyncCell<T>, e.$2))
            .toList() +
        _addedCells;

    if (items.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SegmentCard(
      count: items.length,
      selection: widget.selection,
      columns: GridColumn.three,
      segments: widget.segments,
      aspectRatio: GridAspectRatio.oneTwo.value,
      segmentLabel: widget.val.header,
      modifiers: widget.val.modifiers,
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: GridColumn.three.number,
          childAspectRatio: GridAspectRatio.oneTwo.value,
        ),
        itemBuilder: (context, idx) {
          final (cell, blur) = items[idx];

          return cell.value.buildCell<T>(
            context,
            -1,
            cell.value,
            blur: blur,
            isList: false,
            imageAlign: Alignment.topCenter,
            hideTitle: false,
            animated: PlayAnimations.maybeOf(context) ?? false,
            wrapSelection: (child) =>
                cell.value
                    .tryAsSelectionWrapperable()
                    ?.buildSelectionWrapper<T>(
                      context: context,
                      description: cell.value.description(),
                      onPressed: cell.value.tryAsPressable<T>(
                        context,
                        idx,
                      ),
                      selectFrom: null,
                      thisIndx: -1,
                      child: child,
                    ) ??
                WrapSelection<T>(
                  description: cell.value.description(),
                  onPressed: cell.value.tryAsPressable<T>(
                    context,
                    idx,
                  ),
                  selectFrom: null,
                  thisIndx: -1,
                  child: child,
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
    required this.segments,
    required this.gridSeed,
    required this.config,
    required this.storage,
  });

  final int gridSeed;

  final ReadOnlyStorage<int, T> storage;

  final ShellSelectionHolder? selection;
  final _HeaderWithIdx val;
  final List<int>? predefined;
  final Segments<T> segments;
  final ShellConfigurationData config;

  @override
  Widget build(BuildContext context) {
    final toBlur = val.modifiers.contains(SegmentModifier.blur);

    Widget buildItem(BuildContext context, int idx) {
      final realIdx = val.list[idx];
      final cell = storage[realIdx];

      return cell.buildCell<T>(
        context,
        idx,
        cell,
        isList: false,
        blur: toBlur,
        imageAlign: Alignment.topCenter,
        hideTitle: config.hideName,
        animated: PlayAnimations.maybeOf(context) ?? false,
        wrapSelection: (child) =>
            cell.tryAsSelectionWrapperable()?.buildSelectionWrapper<T>(
                  context: context,
                  thisIndx: realIdx,
                  description: cell.description(),
                  selectFrom: predefined,
                  onPressed: cell.tryAsPressable(context, idx),
                  child: child,
                ) ??
            WrapSelection<T>(
              thisIndx: realIdx,
              description: cell.description(),
              selectFrom: predefined,
              onPressed: cell.tryAsPressable(context, idx),
              child: child,
            ),
      );
    }

    return SegmentCard(
      selection: selection,
      columns: config.columns,
      segments: segments,
      aspectRatio: config.aspectRatio.value,
      segmentLabel: val.header,
      modifiers: val.modifiers,
      count: val.list.length,
      sliver: switch (config.layoutType) {
        GridLayoutType.grid => SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: config.aspectRatio.value,
              crossAxisCount: config.columns.number,
            ),
            itemCount: val.list.length,
            itemBuilder: buildItem,
          ),
        GridLayoutType.list => SliverPadding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            sliver: SliverList.builder(
              itemCount: val.list.length,
              itemBuilder: (context, idx) {
                final realIdx = val.list[idx];
                final cell = storage[realIdx];

                final child = Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    SelectionCountNotifier.maybeCountOf(context);
                    final isSelected = selection?.isSelected(realIdx) ?? false;

                    return DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: isSelected
                            ? null
                            : idx.isOdd
                                ? theme.colorScheme.secondary
                                    .withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.1),
                      ),
                      child: ListTile(
                        textColor: isSelected
                            ? theme.colorScheme.inversePrimary
                            : null,
                        leading: toBlur
                            ? ClipOval(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.compose(
                                    outer: ImageFilter.blur(
                                      sigmaX: 3.59,
                                      sigmaY: 3.59,
                                      tileMode: TileMode.mirror,
                                    ),
                                    inner: ImageFilter.dilate(
                                      radiusX: 0.7,
                                      radiusY: 0.7,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: theme.colorScheme.surface
                                        .withValues(alpha: 0),
                                    backgroundImage:
                                        cell.tryAsThumbnailable(context),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: theme.colorScheme.surface
                                    .withValues(alpha: 0),
                                backgroundImage:
                                    cell.tryAsThumbnailable(context),
                              ),
                        title: Text(
                          cell.alias(true),
                          softWrap: false,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.8)
                                : idx.isOdd
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                );

                return WrapSelection(
                  selectFrom: null,
                  limitedSize: true,
                  shape: const StadiumBorder(),
                  description: cell.description(),
                  onPressed: cell.tryAsPressable(context, idx),
                  thisIndx: realIdx,
                  child: child,
                );
              },
            ),
          ),
        GridLayoutType.gridQuilted => SliverGrid.builder(
            itemCount: val.list.length,
            gridDelegate: SliverQuiltedGridDelegate(
              crossAxisCount: config.columns.number,
              repeatPattern: QuiltedGridRepeatPattern.inverted,
              pattern: config.columns.pattern(gridSeed),
            ),
            itemBuilder: buildItem,
          ),
      },
    );
  }
}

class SegmentCard<T extends CellBase> extends StatelessWidget {
  const SegmentCard({
    super.key,
    required this.selection,
    required this.columns,
    required this.aspectRatio,
    required this.segments,
    required this.segmentLabel,
    required this.modifiers,
    required this.count,
    required this.sliver,
  });

  final int count;

  final double aspectRatio;

  final ShellSelectionHolder? selection;
  final GridColumn columns;
  final Segments<T> segments;
  final _SegSticky segmentLabel;
  final Set<SegmentModifier> modifiers;

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final toSticky = modifiers.contains(SegmentModifier.sticky);
    final toBlur = modifiers.contains(SegmentModifier.blur);
    final toAuth = modifiers.contains(SegmentModifier.auth);

    final isBooru = segmentLabel.seg == "Booru";
    final isSpecial = segmentLabel.seg == segments.injectedLabel;
    final isUnsegmented = segmentLabel.seg == segments.unsegmentedLabel;

    Future<void> sticky() async {
      if (toAuth && AppInfo().canAuthBiometric) {
        final success = await LocalAuthentication().authenticate(
          localizedReason: l10n.unstickyStickyDirectory,
        );

        if (!success) {
          return;
        }
      }

      if (toSticky) {
        segments.caps.remove(
          [segmentLabel.seg],
          const {SegmentModifier.sticky},
        );
      } else {
        segments.caps.add(
          [segmentLabel.seg],
          const {SegmentModifier.sticky},
        );
      }

      unawaited(HapticFeedback.vibrate());
    }

    Future<void> blur() async {
      if (toAuth && AppInfo().canAuthBiometric) {
        final success = await LocalAuthentication().authenticate(
          localizedReason: l10n.unblurDirectory,
        );

        if (!success) {
          return;
        }
      }

      if (toBlur) {
        segments.caps.remove(
          [segmentLabel.seg],
          const {SegmentModifier.blur},
        );
      } else {
        segments.caps.add(
          [segmentLabel.seg],
          const {SegmentModifier.blur},
        );
      }

      unawaited(HapticFeedback.vibrate());
    }

    Future<void> auth() async {
      final success = await LocalAuthentication().authenticate(
        localizedReason: l10n.lockDirectory,
      );

      if (!success) {
        return;
      }

      if (toAuth) {
        segments.caps.remove(
          [segmentLabel.seg],
          const {SegmentModifier.auth},
        );
      } else {
        segments.caps.add(
          [segmentLabel.seg],
          const {SegmentModifier.auth},
        );
      }

      unawaited(HapticFeedback.vibrate());
    }

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
                  count: count,
                  icons: segments.caps.ignoreButtons ||
                          isUnsegmented ||
                          isSpecial ||
                          isBooru
                      ? const []
                      : [
                          IconButton.filled(
                            isSelected: toBlur,
                            onPressed: blur,
                            icon: const Icon(Icons.blur_on_rounded),
                          ),
                          if (AppInfo().canAuthBiometric)
                            IconButton.filled(
                              isSelected: toAuth,
                              onPressed: auth,
                              icon: toAuth
                                  ? const Icon(Icons.lock_rounded)
                                  : const Icon(Icons.lock_open_rounded),
                            ),
                          IconButton.filled(
                            isSelected: toSticky,
                            onPressed: sticky,
                            icon: const Icon(Icons.push_pin_outlined),
                          ),
                        ],
                  onPress: segmentLabel.onLabelPressed,
                  sticky: toSticky,
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
  final bool unstickable;
  final bool firstIsSpecial;

  final VoidCallback? onLabelPressed;
}

sealed class _SegmentType {
  const _SegmentType();
}

class _HeaderWithCells<T extends CellBase> implements _SegmentType {
  const _HeaderWithCells(this.header, this.cells, this.modifiers);

  final List<(SegmentInjectedCellType<T>, bool)> cells;
  final _SegSticky header;
  final Set<SegmentModifier> modifiers;
}

class _HeaderWithIdx implements _SegmentType {
  const _HeaderWithIdx(this.header, this.list, [this.modifiers = const {}]);

  final List<int> list;
  final _SegSticky header;
  final Set<SegmentModifier> modifiers;
}
