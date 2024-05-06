// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_dex_entries.dart";

@JsonSerializable()
class _Attributes {
  const _Attributes({
    required this.demographics,
    required this.volumes,
    required this.lastChapter,
    required this.contentRating,
    required this.status,
    required this.year,
    required this.titles,
    required this.descriptions,
    required this.titlesExtra,
    required this.tags,
    required this.originalLanguage,
  });

  factory _Attributes.fromJson(Map<String, dynamic> json) =>
      _$AttributesFromJson(json);

  @JsonKey(name: "tags")
  final List<_Tag> tags;

  @JsonKey(name: "originalLanguage")
  final String originalLanguage;

  @JsonKey(name: "title")
  final Map<String, String> titles;

  @JsonKey(name: "description")
  final Map<String, String> descriptions;

  @MangaDexAltTitlesConventer()
  @JsonKey(name: "altTitles")
  final Map<String, String> titlesExtra;

  @JsonKey(name: "publicationDemographic")
  final String demographics;

  @MangaDexVolumeConventer()
  @JsonKey(name: "lastVolume")
  final int volumes;

  @JsonKey(name: "lastChapter")
  final String lastChapter;

  @MangaDexSafeModeConverter()
  @JsonKey(name: "contentRating")
  final AnimeSafeMode contentRating;

  @JsonKey(name: "status")
  final String status;

  @JsonKey(name: "year")
  final int? year;
}
