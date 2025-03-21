// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/material.dart";

/// Filtering modes.
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

  ungrouped(Icons.fiber_manual_record_rounded),

  fiveStars(Icons.star_rounded),
  fourHalfStars(Icons.star_half_rounded),
  fourStars(Icons.star_rounded),
  threeHalfStars(Icons.star_half_rounded),
  threeStars(Icons.star_rounded),
  twoHalfStars(Icons.star_half_rounded),
  twoStars(Icons.star_rounded),
  oneHalfStars(Icons.star_half_rounded),
  oneStars(Icons.star_rounded),
  zeroHalfStars(Icons.star_half_rounded),
  zeroStars(Icons.star_border_rounded),
  onlyHalfStars(Icons.star_half_rounded),
  onlyFullStars(Icons.star_rounded),
  ;

  const FilteringMode(this.icon);

  /// Icon displayed in search bar.
  final IconData icon;

  FavoriteStars get toStars => toStarsOrNull ?? FavoriteStars.zero;

  FavoriteStars? get toStarsOrNull {
    return switch (this) {
      FilteringMode.fiveStars => FavoriteStars.five,
      FilteringMode.fourHalfStars => FavoriteStars.fourFive,
      FilteringMode.fourStars => FavoriteStars.four,
      FilteringMode.threeHalfStars => FavoriteStars.threeFive,
      FilteringMode.threeStars => FavoriteStars.three,
      FilteringMode.twoHalfStars => FavoriteStars.twoFive,
      FilteringMode.twoStars => FavoriteStars.two,
      FilteringMode.oneHalfStars => FavoriteStars.oneFive,
      FilteringMode.oneStars => FavoriteStars.one,
      FilteringMode.zeroHalfStars => FavoriteStars.zeroFive,
      FilteringMode.zeroStars => FavoriteStars.zero,
      FilteringMode() => null,
    };
  }

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
        FilteringMode.fiveStars => "5 stars", // TODO: change
        FilteringMode.fourHalfStars => "4.5 stars",
        FilteringMode.fourStars => "4 stars",
        FilteringMode.threeHalfStars => "3.5 stars",
        FilteringMode.threeStars => "3 stars",
        FilteringMode.twoHalfStars => "2.5 stars",
        FilteringMode.twoStars => "2 stars",
        FilteringMode.oneHalfStars => "1.5 stars",
        FilteringMode.oneStars => "1 star",
        FilteringMode.zeroHalfStars => "0.5 star",
        FilteringMode.zeroStars => "No stars",
        FilteringMode.onlyHalfStars => "Only half stars",
        FilteringMode.onlyFullStars => "Only full stars",
      };
}

/// Sorting modes.
enum SortingMode {
  none,
  rating,
  score,
  size,
  stars;

  const SortingMode();

  IconData icons(SortingMode selected) => switch (this) {
        SortingMode.none => this == selected
            ? Icons.filter_list_off_rounded
            : Icons.filter_list_off_outlined,
        SortingMode.rating =>
          this == selected ? Icons.explicit_rounded : Icons.explicit_outlined,
        SortingMode.score =>
          this == selected ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
        SortingMode.size => this == selected
            ? Icons.square_foot_rounded
            : Icons.square_foot_outlined,
        SortingMode.stars =>
          this == selected ? Icons.star_rounded : Icons.star_outlined,
      };

  String translatedString(AppLocalizations l10n) => switch (this) {
        SortingMode.none => l10n.enumSortingModeNone,
        SortingMode.size => l10n.enumSortingModeSize,
        SortingMode.rating => l10n.enumSortingModeRating,
        SortingMode.score => l10n.enumSortingModeScore,
        SortingMode.stars => "Stars", // TODO: change
      };
}
