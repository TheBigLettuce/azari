// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

/// Filtering modes.
/// Implemented outside the [FilterInterface].
/// Some of [FilteringMode] might be virtual.
/// Virtual [FilteringMode] means overriding the default filtering behaviour,
/// [FilteringMode.tag] and [FilteringMode.tagReversed] override how text filtering works..
enum FilteringMode {
  /// Filter by the favorite.
  favorite(Icons.favorite_border_outlined),

  /// Filter by the  "original" tag.
  original(Icons.circle_outlined),

  /// Filter by filenames, which have (1).ext format.
  duplicate(Icons.mode_standby_outlined),

  /// Filter by similarity.
  same(Icons.drag_handle),

  /// Filter by video.
  video(Icons.play_circle),

  /// Filter by GIF.
  gif(Icons.gif_outlined),

  /// Filter by tag.
  tag(Icons.tag),

  /// No filter.
  noFilter(Icons.filter_list_outlined),

  /// Filter by not tag not included.
  tagReversed(Icons.label_off_outlined),

  /// Filter by no tags on image.
  untagged(Icons.label_off),

  /// Filter by segments.
  group(Icons.group_work_outlined),

  ungrouped(Icons.fiber_manual_record_rounded);

  const FilteringMode(this.icon);

  /// Icon displayed in search bar.
  final IconData icon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        FilteringMode.favorite => l10n.enumFilteringModeFavorite,
        FilteringMode.original => l10n.enumFilteringModeOriginal,
        FilteringMode.duplicate => l10n.enumFilteringModeDuplicate,
        FilteringMode.same => l10n.enumFilteringModeSame,
        FilteringMode.video => l10n.enumFilteringModeVideo,
        FilteringMode.gif => l10n.enumFilteringModeGif,
        FilteringMode.tag => l10n.enumFilteringModeTag,
        FilteringMode.noFilter => l10n.enumFilteringModeNoFilter,
        FilteringMode.tagReversed => l10n.enumFilteringModeTagReversed,
        FilteringMode.untagged => l10n.enumFilteringModeUntagged,
        FilteringMode.group => l10n.enumFilteringModeGroup,
        FilteringMode.ungrouped => l10n.enumFilteringModeUngrouped,
      };
}

/// Sorting modes.
/// Implemented inside the [FilterInterface].
enum SortingMode {
  none,
  size;

  const SortingMode();

  int get sortingIdAndroid => switch (this) {
        SortingMode.none => 0,
        SortingMode.size => 1,
      };

  String translatedString(AppLocalizations l10n) => switch (this) {
        SortingMode.none => l10n.enumSortringModeNone,
        SortingMode.size => l10n.enumSortringModeSize,
      };
}
