// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_dex_chapters.dart";

@JsonSerializable()
class _MangaChapter implements MangaChapter {
  const _MangaChapter({
    required this.id,
    required this.attributes,
    required this.scanlationGroup,
  });

  factory _MangaChapter.fromJson(Map<String, dynamic> json) =>
      _$MangaChapterFromJson(json);

  @override
  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "attributes")
  final _Attributes attributes;

  @MangaDexChapterRelationshipsConverter()
  @JsonKey(name: "relationships")
  final _Relationship? scanlationGroup;

  @override
  String get chapter => attributes.chapter;

  @override
  int get pages => attributes.pages;

  @override
  String get title => attributes.title ?? "";

  @override
  String get translator => scanlationGroup?.attributes?.name ?? "";

  @override
  String get volume => attributes.volume;
}

@JsonSerializable()
class _Attributes {
  const _Attributes({
    required this.pages,
    required this.volume,
    required this.chapter,
    required this.title,
    required this.translatedLanguage,
    required this.externalUrl,
  });

  factory _Attributes.fromJson(Map<String, dynamic> json) =>
      _$AttributesFromJson(json);

  @JsonKey(name: "pages")
  final int pages;

  @JsonKey(name: "volumes")
  final String volume;
  @JsonKey(name: "chapter")
  final String chapter;

  @JsonKey(name: "title")
  final String? title;
  @JsonKey(name: "translatedLanguage")
  final String translatedLanguage;
  @JsonKey(name: "externalUrl")
  final String? externalUrl;
}
