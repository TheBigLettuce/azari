// SPDX-License-Identifier: GPL-2.0-only
//
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
  favorite(Icons.star_border_rounded),

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

  ungrouped(Icons.fiber_manual_record_rounded),

  notes(Icons.sticky_note_2_outlined);

  const FilteringMode(this.icon);

  /// Icon displayed in search bar.
  final IconData icon;

  String translatedString(BuildContext context) => switch (this) {
        FilteringMode.favorite =>
          AppLocalizations.of(context)!.enumFilteringModeFavorite,
        FilteringMode.original =>
          AppLocalizations.of(context)!.enumFilteringModeOriginal,
        FilteringMode.duplicate =>
          AppLocalizations.of(context)!.enumFilteringModeDuplicate,
        FilteringMode.same =>
          AppLocalizations.of(context)!.enumFilteringModeSame,
        FilteringMode.video =>
          AppLocalizations.of(context)!.enumFilteringModeVideo,
        FilteringMode.gif => AppLocalizations.of(context)!.enumFilteringModeGif,
        FilteringMode.tag => AppLocalizations.of(context)!.enumFilteringModeTag,
        FilteringMode.noFilter =>
          AppLocalizations.of(context)!.enumFilteringModeNoFilter,
        FilteringMode.tagReversed =>
          AppLocalizations.of(context)!.enumFilteringModeTagReversed,
        FilteringMode.untagged =>
          AppLocalizations.of(context)!.enumFilteringModeUntagged,
        FilteringMode.group =>
          AppLocalizations.of(context)!.enumFilteringModeGroup,
        FilteringMode.ungrouped =>
          AppLocalizations.of(context)!.enumFilteringModeUngrouped,
        FilteringMode.notes =>
          AppLocalizations.of(context)!.enumFilteringModeNotes,
      };
}
