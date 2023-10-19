// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

/// Filtering modes.
/// Implemented outside the [FilterInterface].
/// Some of [FilteringMode] might be virtual.
/// Virtual [FilteringMode] means overriding the default filtering behaviour,
/// [FilteringMode.tag] and [FilteringMode.tagReversed] override how text filtering works..
enum FilteringMode {
  /// Filter by the favorite.
  favorite("Favorite", Icons.star_border_rounded),

  /// Filter by the  "original" tag.
  original("Original", Icons.circle_outlined),

  /// Filter by filenames, which have (1).ext format.
  duplicate("Duplicate", Icons.mode_standby_outlined),

  /// Filter by similarity.
  same("Same", Icons.drag_handle),

  /// Filter by video.
  video("Video", Icons.play_circle),

  /// Filter by GIF.
  gif("GIF", Icons.gif_outlined),

  /// Filter by tag.
  tag("Tag", Icons.tag),

  /// Filter by size, from bif to small.
  size("Size", Icons.arrow_downward),

  /// No filter.
  noFilter("No filter", Icons.filter_list_outlined),

  /// Filter by not tag not included.
  tagReversed("Tag reversed", Icons.label_off_outlined),

  /// Filter by no tags on image.
  untagged("Untagged", Icons.label_off),

  /// Filter by segments.
  group("Group", Icons.group_work_outlined),

  ungrouped("Ungrouped", Icons.fiber_manual_record_rounded),

  notes("Notes", Icons.sticky_note_2_outlined);

  /// Name displayed in search bar.
  final String string;

  /// Icon displayed in search bar.
  final IconData icon;

  const FilteringMode(this.string, this.icon);
}
