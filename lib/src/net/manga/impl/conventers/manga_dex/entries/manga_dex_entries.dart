// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/manga/impl/conventers/manga_dex.dart";
import "package:azari/src/net/manga/manga_api.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:json_annotation/json_annotation.dart";

part "_manga_entry.dart";
part "attributes.dart";
part "manga_dex_entries.g.dart";
part "relationships.dart";
part "tag.dart";

@JsonSerializable()
class MangaDexEntries {
  const MangaDexEntries({
    required this.data,
    required this.result,
  });

  factory MangaDexEntries.fromJson(Map<String, dynamic> json) =>
      _$MangaDexEntriesFromJson(json);

  @JsonKey(name: "result")
  final String result;

  @JsonKey(name: "data")
  final List<_MangaEntry>? data;

  List<MangaEntry> emptyIfNotOk() => result != "ok" ? const [] : data!;
}
