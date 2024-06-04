// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:json_annotation/json_annotation.dart";

part "manga_dex_chapters.g.dart";
part "_manga_chapter.dart";
part "relationship.dart";

@JsonSerializable()
class MangaDexChapters {
  const MangaDexChapters({
    required this.result,
    required this.data,
  });

  factory MangaDexChapters.fromJson(Map<String, dynamic> json) =>
      _$MangaDexChaptersFromJson(json);

  @JsonKey(name: "result")
  final String result;

  @JsonKey(name: "data")
  final List<_MangaChapter>? data;

  List<MangaChapter> filterLanguage(String language) {
    if (data == null || data!.isEmpty) {
      return [];
    }

    return data!
        .where(
          (element) =>
              element.attributes.translatedLanguage == language &&
              element.attributes.pages != 0 &&
              element.scanlationGroup != null,
        )
        .toList();
  }
}

class MangaDexChapterRelationshipsConverter
    implements JsonConverter<_Relationship?, List<Map<String, dynamic>>> {
  const MangaDexChapterRelationshipsConverter();

  @override
  _Relationship? fromJson(List<Map<String, dynamic>> json) {
    final l = json
        .where((element) => element["type"] == "scanlation_group")
        .firstOrNull;
    if (l == null) {
      return null;
    }

    return _Relationship.fromJson(l);
  }

  @override
  List<Map<String, dynamic>> toJson(_Relationship? object) => const [];
}
