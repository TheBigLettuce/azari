// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

/// Filtering modes.
/// Some of [FilteringMode] might be virtual.
/// Virtual [FilteringMode] means overriding the default filtering behaviour,
/// [FilteringMode.tag] and [FilteringMode.tagReversed] override how text filtering works..
enum FilteringMode {
  /// Filter by the favorite.
  favorite(),

  /// Filter by the  "original" tag.
  original(),

  /// Filter by filenames, which have (1).ext format.
  duplicate(),

  /// Filter by similarity.
  same(),

  /// Filter by video.
  video(),

  /// Filter by GIF.
  gif(),

  /// Filter by tag.
  tag(),

  /// No filter.
  noFilter(),

  /// Filter by not tag not included.
  tagReversed(),

  /// Filter by no tags on image.
  untagged(),

  /// Filter by segments.
  group(),

  ungrouped(),

  fiveStars(),
  fourHalfStars(),
  fourStars(),
  threeHalfStars(),
  threeStars(),
  twoHalfStars(),
  twoStars(),
  oneHalfStars(),
  oneStars(),
  zeroHalfStars(),
  zeroStars(),
  onlyHalfStars(),
  onlyFullStars(),
  ;

  const FilteringMode();

  /// Icon displayed in search bar.
  IconData get icon => switch (this) {
        FilteringMode.favorite => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.heart
            : Icons.favorite_border_outlined,
        FilteringMode.original => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.circle
            : Icons.circle_outlined,
        FilteringMode.duplicate => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.doc_on_doc
            : Icons.mode_standby_outlined,
        FilteringMode.same => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.equal_circle
            : Icons.drag_handle,
        FilteringMode.video => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.play_circle
            : Icons.play_circle,
        FilteringMode.gif => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.play_circle
            : Icons.gif_outlined,
        FilteringMode.tag => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.tag_circle
            : Icons.tag,
        FilteringMode.noFilter => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.sort_up
            : Icons.filter_list_outlined,
        FilteringMode.tagReversed => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.tag_circle_fill
            : Icons.label_off_outlined,
        FilteringMode.untagged => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.tag_solid
            : Icons.label_off,
        FilteringMode.group => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.group
            : Icons.group_work_outlined,
        FilteringMode.ungrouped => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.group_solid
            : Icons.fiber_manual_record_rounded,
        FilteringMode.fiveStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
        FilteringMode.fourHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.fourStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
        FilteringMode.threeHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.threeStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
        FilteringMode.twoHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.twoStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
        FilteringMode.oneHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.oneStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
        FilteringMode.zeroHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.zeroStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_border_rounded,
        FilteringMode.onlyHalfStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star_lefthalf_fill
            : Icons.star_half_rounded,
        FilteringMode.onlyFullStars => Platform.isMacOS || Platform.isIOS
            ? CupertinoIcons.star
            : Icons.star_rounded,
      };

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
        FilteringMode.fiveStars => l10n.stars(5),
        FilteringMode.fourHalfStars => l10n.stars(4.5),
        FilteringMode.fourStars => l10n.stars(4),
        FilteringMode.threeHalfStars => l10n.stars(3.5),
        FilteringMode.threeStars => l10n.stars(3),
        FilteringMode.twoHalfStars => l10n.stars(2.5),
        FilteringMode.twoStars => l10n.stars(2),
        FilteringMode.oneHalfStars => l10n.stars(1.5),
        FilteringMode.oneStars => l10n.stars(1),
        FilteringMode.zeroHalfStars => l10n.stars(0.5),
        FilteringMode.zeroStars => l10n.stars(0),
        FilteringMode.onlyHalfStars => l10n.enumFilteringModeOnlyHalfStars,
        FilteringMode.onlyFullStars => l10n.enumFilteringModeOnlyFullStars,
      };
}

enum FilteringColors {
  noColor(Colors.transparent),
  red(Colors.red),
  blue(Colors.blue),
  yellow(Colors.yellow),
  green(Colors.green),
  purple(Colors.purple),
  orange(Colors.orange),
  pink(Colors.pink),
  white(Colors.white),
  brown(Colors.brown),
  black(Colors.black);

  const FilteringColors(this.color);

  final Color color;

  String translatedString(AppLocalizations l10n, ColorsNamesData data) =>
      switch (this) {
        FilteringColors.noColor => "No color",
        FilteringColors.red => data.red.isEmpty ? "Red" : data.red,
        FilteringColors.blue => data.blue.isEmpty ? "Blue" : data.blue,
        FilteringColors.yellow => data.yellow.isEmpty ? "Yellow" : data.yellow,
        FilteringColors.green => data.green.isEmpty ? "Green" : data.green,
        FilteringColors.purple => data.purple.isEmpty ? "Purple" : data.purple,
        FilteringColors.orange => data.orange.isEmpty ? "Orange" : data.orange,
        FilteringColors.pink => data.pink.isEmpty ? "Pink" : data.pink,
        FilteringColors.white => data.white.isEmpty ? "White" : data.white,
        FilteringColors.brown => data.brown.isEmpty ? "Brown" : data.brown,
        FilteringColors.black =>
          data.black.isEmpty ? "Black" : data.black, // TODO: change
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
        SortingMode.stars => l10n.enumSortingModeStars,
      };
}
