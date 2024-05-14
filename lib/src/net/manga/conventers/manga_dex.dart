// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:json_annotation/json_annotation.dart";

class MangaDexSafeModeConverter
    implements JsonConverter<AnimeSafeMode, String> {
  const MangaDexSafeModeConverter();

  @override
  AnimeSafeMode fromJson(String json) => switch (json) {
        "safe" || "suggestive" => AnimeSafeMode.safe,
        "erotica" => AnimeSafeMode.ecchi,
        "pornographic" => AnimeSafeMode.h,
        String() => AnimeSafeMode.safe,
      };

  @override
  String toJson(AnimeSafeMode object) => switch (object) {
        AnimeSafeMode.safe => "safe",
        AnimeSafeMode.ecchi => "erotica",
        AnimeSafeMode.h => "pornographic",
      };
}

class MangaDexAltTitlesConventer
    implements JsonConverter<Map<String, String>, List<dynamic>> {
  const MangaDexAltTitlesConventer();

  @override
  Map<String, String> fromJson(List<dynamic> json) => json
          .where(
        (element) =>
            (element as Map).containsKey("en") && element.containsKey("ja-ro"),
        // &&
        // element.containsKey(attributes.originalLanguage),
      )
          .fold<Map<String, String>>(
        {},
        (previousValue, element) {
          for (final e in (element as Map).entries) {
            final prev = previousValue[e.key];
            if (prev == null) {
              previousValue[e.key as String] = e.value as String;
            } else {
              if ((e.value as String).compareTo(prev) < 0) {
                previousValue[e.key as String] = e.value as String;
              }
            }
          }

          return previousValue;
        },
      );

  @override
  List<dynamic> toJson(Map<String, String> object) => const [];
}

class MangaDexVolumeConventer implements JsonConverter<int, String?> {
  const MangaDexVolumeConventer();

  @override
  int fromJson(String? json) => json == null ? -1 : int.tryParse(json) ?? -1;

  @override
  String toJson(int object) => object.toString();
}

class MangaDexIdConverter implements JsonConverter<MangaStringId, String> {
  const MangaDexIdConverter();

  @override
  MangaStringId fromJson(String json) => MangaStringId(json);

  @override
  String toJson(MangaStringId object) => object.id;
}

// Map<String, dynamic> makeTags(List<MangaId> includesTag) {
//   final m = <String, dynamic>{};

//   for (final (i, id) in includesTag.indexed) {
//     m["includedTags[$i]"] = (id as MangaStringId).id;
//   }

//   return m;
// }








// List<MangaEntry> _fromJson(List<dynamic> l) {
//   try {
//     final res = List.generate(
//       l.length,
//       (index) {
//         final e = l[index];
//         final id = e["id"];
//         final attr = e["attributes"];
//         final fileName =
//             _findType("cover_art", e["relationships"])["attributes"]
//                 ["fileName"];

//         final originalLanguage = attr["originalLanguage"];
//         final altTitles = attr["altTitles"] as List<dynamic>;

//         final safe = switch (attr["contentRating"] as String) {
//           "safe" || "suggestive" => AnimeSafeMode.safe,
//           "erotica" => AnimeSafeMode.ecchi,
//           "pornographic" => AnimeSafeMode.h,
//           String() => throw "invalid content rating",
//         };

//         final titleEnglish = _tagFirstIndex("en", altTitles);
//         final titleJapanese = _tagFirstIndex(originalLanguage, altTitles);
//         final titleJaJo = originalLanguage == "ja"
//             ? _tagFirstIndex("ja-ro", altTitles, true)
//             : null;

//         final volumes = attr["lastVolume"];

//         return MangaEntry(
//           status: attr["status"],
//           imageUrl:
//               _constructImageUrl(id: id, thumb: false, fileName: fileName),
//           thumbUrl: _constructImageUrl(id: id, thumb: true, fileName: fileName),
//           year: attr["year"] ?? 0,
//           safety: safe,
//           genres: _genres(attr["tags"]),
//           relations: _mangaRelations(e["relationships"]),
//           titleSynonyms:
//               _tagEntries(originalLanguage, altTitles, titleJapanese?.$2) +
//                   _tagEntries("en", altTitles, titleEnglish?.$2) +
//                   _tagEntries("ja-ro", altTitles, titleJaJo?.$2),
//           title: titleJaJo?.$1 ?? _tagOrFirst("en", attr["title"]),
//           titleEnglish: titleEnglish?.$1 ?? _tagOrFirst("en", attr["title"]),
//           titleJapanese: titleJapanese?.$1 ??
//               (altTitles.isEmpty ? "" : _tagOrFirst("ja", altTitles.first)),
//           site: MangaMeta.mangaDex,
//           id: MangaStringId(id),
//           animeIds: const [],
//           synopsis: _tagOrFirst("en", attr["description"]),
//           demographics: attr["publicationDemographic"] ?? "",
//           volumes: (volumes is String ? int.tryParse(volumes) : volumes) ?? -1,
//         );
//       },
//     );

//     return res;
//   } catch (e, stackTrace) {
//     LogTarget.manga.logDefaultImportant(
//       "unwrapping manga json".errorMessage(e),
//       stackTrace,
//     );

//     rethrow;
//   }
// }
 // final titleEnglish = _tagFirstIndex("en", altTitles);
//         final titleJapanese = _tagFirstIndex(originalLanguage, altTitles);
//         final titleJaJo = originalLanguage == "ja"
//             ? _tagFirstIndex("ja-ro", altTitles, true)
//             : null;

  // title: titleJaJo?.$1 ?? _tagOrFirst("en", attr["title"]),
  // titleEnglish: titleEnglish?.$1 ?? _tagOrFirst("en", attr["title"]),
  // titleJapanese: titleJapanese?.$1 ??
  //     (altTitles.isEmpty ? "" : _tagOrFirst("ja", altTitles.first)),

  // (String, int)? _tagFirstIndex(
  //   String tag,
  //   List<dynamic> l, [
  //   bool longest = false,
  // ]) {
  //   if (!longest) {
  //     for (final e in l.indexed) {
  //       final e1 = e.$2[tag];
  //       if (e1 != null) {
  //         return (e1, e.$1);
  //       }
  //     }
  //   } else {
  //     final ret = <(String, int)>[];

  //     for (final e in l.indexed) {
  //       final e1 = e.$2[tag];
  //       if (e1 != null) {
  //         ret.add((e1, e.$1));
  //       }
  //     }

  //     if (ret.isEmpty) {
  //       return null;
  //     }

  //     if (ret.length == 1) {
  //       return ret.first;
  //     }

  //     late (String, int) ret2;
  //     int longest = 0;
  //     for (final e in ret) {
  //       if (e.$1.length > longest) {
  //         longest = e.$1.length;
  //         ret2 = e;
  //       }
  //     }

  //     return ret2;
  //   }
  // }



// String? _getScanlationGroup(List<dynamic> l) {
//   for (final e in l) {
//     if (e["type"] == "scanlation_group") {
//       return e["attributes"]["name"];
//     }
//   }

//   return null;
// }

// List<MangaRelation> _mangaRelations(List<dynamic> l) {
//   final ret = <MangaRelation>[];

//   for (final e in l) {
//     if (e["type"] == "manga") {
//       final attr = e["attributes"];
//       if (attr == null) {
//         continue;
//       }

//       ret.add(
//         MangaRelation(
//           id: MangaStringId(e["id"]),
//           name: _tagOrFirst("en", attr["title"]),
//         ),
//       );
//     }
//   }

//   return ret;
// }

// Map<String, dynamic> _findType(String s, List<dynamic> l) {
//   for (final e in l) {
//     if (e["type"] == s) {
//       return e;
//     }
//   }

//   return {};
// }



//   return null;
// }
