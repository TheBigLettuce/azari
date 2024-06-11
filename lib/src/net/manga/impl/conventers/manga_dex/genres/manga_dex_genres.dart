// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/net/manga/manga_api.dart";
import "package:json_annotation/json_annotation.dart";

part "manga_dex_genres.g.dart";

@JsonSerializable()
class MangaDexGenres {
  const MangaDexGenres({
    required this.data,
    required this.result,
  });

  factory MangaDexGenres.fromJson(Map<String, dynamic> json) =>
      _$MangaDexGenresFromJson(json);

  @JsonKey(name: "result")
  final String result;

  @JsonKey(name: "data")
  final List<_MangaTag>? data;

  List<MangaGenre> emptyIfNotOk() => result != "ok"
      ? const []
      : data!
          .map(
            (e) => MangaGenre(
              id: MangaStringId(e.id),
              name: e.attributes.names["en"] ?? e.attributes.names.values.first,
            ),
          )
          .toList();
}

@JsonSerializable()
class _Attributes {
  const _Attributes({
    required this.names,
  });

  factory _Attributes.fromJson(Map<String, dynamic> json) =>
      _$AttributesFromJson(json);

  @JsonKey(name: "name")
  final Map<String, String> names;
}

@JsonSerializable()
class _MangaTag {
  const _MangaTag({
    required this.attributes,
    required this.id,
  });

  factory _MangaTag.fromJson(Map<String, dynamic> json) =>
      _$MangaTagFromJson(json);

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "attributes")
  final _Attributes attributes;
}
