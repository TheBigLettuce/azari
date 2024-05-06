// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_dex_entries.dart";

@JsonSerializable()
class _Tag {
  const _Tag({
    required this.id,
    required this.type,
    required this.attributes,
  });

  factory _Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "type")
  final String type;

  @JsonKey(name: "attributes")
  final _TagAttributes attributes;
}

@JsonSerializable()
class _TagAttributes {
  const _TagAttributes({
    required this.names,
    required this.group,
  });

  factory _TagAttributes.fromJson(Map<String, dynamic> json) =>
      _$TagAttributesFromJson(json);

  @JsonKey(name: "name")
  final Map<String, String> names;

  @JsonKey(name: "group")
  final String group;
}
