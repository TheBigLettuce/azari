// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_dex_entries.dart";

@JsonSerializable()
class _Relationships {
  const _Relationships({
    required this.id,
    required this.type,
    required this.attributes,
  });

  factory _Relationships.fromJson(Map<String, dynamic> json) =>
      _$RelationshipsFromJson(json);

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "type")
  final String type;

  @JsonKey(name: "attributes")
  final _RelationshipsAttributes? attributes;
}

@JsonSerializable()
class _RelationshipsAttributes {
  const _RelationshipsAttributes({
    required this.filename,
    required this.title,
  });

  factory _RelationshipsAttributes.fromJson(Map<String, dynamic> json) =>
      _$RelationshipsAttributesFromJson(json);

  @JsonKey(name: "fileName")
  final String? filename;

  @JsonKey(name: "title")
  final Map<String, String>? title;
}
