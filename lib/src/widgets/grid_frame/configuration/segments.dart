// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

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
  final String? Function(T cell)? segment;

  final Map<SegmentKey, int>? prebuiltSegments;
  final int? limitLabelChildren;

  final void Function(String label, List<T> children)? onLabelPressed;

  final bool hidePinnedIcon;
  final bool displayFirstCellInSpecial;

  final SegmentCapability caps;
}

enum SegmentModifier {
  blur,
  auth,
  sticky;
}

abstract interface class SegmentCapability {
  Set<SegmentModifier> modifiersFor(String seg);

  bool get ignoreButtons;

  void addModifiers(List<String> segments, Set<SegmentModifier> m);
  void removeModifiers(List<String> segments, Set<SegmentModifier> m);

  static SegmentCapability empty() => const _SegmentCapabilityEmpty();
  static SegmentCapability alwaysPinned() =>
      const _SegmentCapabilityAlwaysPinned();
}

class _SegmentCapabilityAlwaysPinned implements SegmentCapability {
  const _SegmentCapabilityAlwaysPinned();

  @override
  bool get ignoreButtons => true;

  @override
  void addModifiers(List<String> segments, Set<SegmentModifier> m) {}

  @override
  Set<SegmentModifier> modifiersFor(String seg) =>
      const {SegmentModifier.sticky};

  @override
  void removeModifiers(List<String> segments, Set<SegmentModifier> m) {}
}

class _SegmentCapabilityEmpty implements SegmentCapability {
  const _SegmentCapabilityEmpty();

  @override
  bool get ignoreButtons => true;

  @override
  void addModifiers(List<String> segments, Set<SegmentModifier> m) {}

  @override
  Set<SegmentModifier> modifiersFor(String seg) => const {};

  @override
  void removeModifiers(List<String> segments, Set<SegmentModifier> m) {}
}
