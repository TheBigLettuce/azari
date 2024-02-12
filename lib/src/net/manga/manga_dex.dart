// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';

class MangaDex implements MangaAPI {
  const MangaDex(this.client);

  static const _log = LogTarget.manga;
  final Dio client;

  @override
  MangaMeta get site => MangaMeta.mangaDex;

  @override
  Future<List<MangaEntry>> search(
    String s, {
    int page = 0,
    int count = 10,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    List<MangaId>? includesTag,
  }) async {
    Map<String, dynamic> makeTags() {
      final m = <String, dynamic>{};

      for (final (i, id) in includesTag!.indexed) {
        m["includedTags[$i]"] = (id as MangaStringId).id;
      }

      return m;
    }

    final res = await client.getUriLog(
      Uri.https(site.url, "/manga", {
        "includes[0]": "cover_art",
        "includes[1]": "manga",
        "order[followedCount]": "desc",
        "order[relevance]": "desc",
        "limit": count.toString(),
        "offset": (page * count).toString(),
        "title": s,
        "contentRating[0]": switch (safeMode) {
          AnimeSafeMode.safe => "safe",
          AnimeSafeMode.ecchi => "erotica",
          AnimeSafeMode.h => "pornographic",
        },
        if (safeMode == AnimeSafeMode.ecchi) "contentRating[1]": "suggestive",
        if (includesTag != null && includesTag.isNotEmpty) ...makeTags(),
      }),
      LogReq("Manga search page $page", _log),
      options: Options(
        responseType: ResponseType.json,
      ),
    );

    if (res.data == null ||
        res.data["result"] != "ok" ||
        (res.data["data"] as List<dynamic>).isEmpty) {
      return const [];
    }

    return _fromJson(res.data["data"]);
  }

  @override
  Future<List<MangaEntry>> top(int page, int count) {
    return search("", page: page, count: count);
  }

  @override
  Future<List<MangaGenre>> tags() async {
    final res = await client.getUriLog(
      Uri.https(site.url, "/manga/tag"),
      const LogReq("Manga tags", _log),
      options: Options(responseType: ResponseType.json),
    );

    if (res.data == null ||
        res.data["result"] != "ok" ||
        (res.data["data"] as List<dynamic>).isEmpty) {
      return const [];
    }

    return _genres(res.data["data"]);
  }

  @override
  Future<double> score(MangaEntry e) async {
    final res = await client.getUriLog(
      Uri.https(site.url, "/statistics/manga/${e.id.toString()}"),
      const LogReq("Manga score", _log),
      options: Options(responseType: ResponseType.json),
    );

    final t = (res.data["statistics"] as Map<String, dynamic>)
        .values
        .first["rating"]["average"];

    return t == null ? -1 : (t as num).toDouble();
  }

  @override
  Future<MangaEntry> single(MangaId id) async {
    final res = await client.getUriLog(
      Uri.https(site.url, "/manga/${id.toString()}", {
        "includes[0]": "cover_art",
        "includes[1]": "manga",
      }),
      const LogReq("Manga single", _log),
      options: Options(responseType: ResponseType.json),
    );

    if (res.data == null || res.data["result"] != "ok") {
      throw "empty result";
    }

    return _fromJson([res.data["data"]])[0];
  }

  @override
  Future<List<(List<MangaChapter>, String)>> chapters(
    MangaEntry e, {
    int page = 0,
    int count = 100,
    MangaChapterOrder order = MangaChapterOrder.desc,
  }) async {
    final res = await client.getUriLog(
        Uri.https(site.url, "/manga/${e.id}/feed", {
          "limit": count.toString(),
          "offset": (page * count).toString(),
          "contentRating[0]": "safe",
          "contentRating[1]": "suggestive",
          "contentRating[2]": "erotica",
          "contentRating[3]": "pornographic",
          "includes[]": "scanlation_group",
          "order[volume]": order == MangaChapterOrder.asc ? "asc" : "desc",
          "order[chapter]": order == MangaChapterOrder.asc ? "asc" : "desc",
          "translatedLanguage[]": "en",
        }),
        LogReq("Manga chapters page $page", _log));

    return _fromJsonChapters("en", res.data["data"]);
  }

  @override
  Future<List<MangaImage>> imagesForChapter(MangaId id) async {
    try {
      final res = await client.getUriLog(
        Uri.https(site.url, "/at-home/server/$id"),
        const LogReq("Manga single", _log),
        options: Options(responseType: ResponseType.json),
      );

      if (res.data == null || res.data["result"] == null) {
        throw "empty result";
      }

      final String baseUrl = res.data["baseUrl"];
      final String hash = res.data["chapter"]["hash"];

      final ret = _fromJsonImages(res.data["chapter"]["data"],
          baseUrl: baseUrl, hash: hash);

      return ret;
    } catch (e, stackTrace) {
      LogTarget.manga.logDefaultImportant(
          "unwrapping manga chapter images json".errorMessage(e), stackTrace);

      rethrow;
    }
  }

  @override
  String browserUrl(MangaEntry e) => "https://mangadex.org/title/${e.id}";
}

List<MangaImage> _fromJsonImages(
  List<dynamic> l, {
  required String baseUrl,
  required String hash,
}) {
  final ret = <MangaImage>[];

  for (final e in l.indexed) {
    ret.add(MangaImage("$baseUrl/data/$hash/${e.$2}", e.$1));
  }

  return ret;
}

List<(List<MangaChapter>, String)> _fromJsonChapters(
    String lang, List<dynamic> l) {
  final ret = <String, List<MangaChapter>>{};

  try {
    for (final e in l) {
      final attr = e["attributes"];
      if (attr["translatedLanguage"] == lang) {
        final String volume = attr["volume"] ?? "?";
        final l = ret[volume];
        if (l == null) {
          ret[volume] = [];
        }

        final int pages = attr["pages"];
        if (pages == 0) {
          continue;
        }

        ret[volume]!.add(MangaChapter(
            chapter: attr["chapter"] ?? "0",
            pages: pages,
            title: attr["title"] ?? "",
            volume: volume,
            translator: _getScanlationGroup(e["relationships"]) ?? "",
            id: e["id"]));
      }
    }
  } catch (e, stackTrace) {
    LogTarget.manga.logDefaultImportant(
        "unwrapping manga chapter json".errorMessage(e), stackTrace);

    rethrow;
  }

  final ret1 = ret.entries.map((e) => (e.value, e.key)).toList();
  // ret1.sort((e1, e2) {
  //   final r = e1.$2.compareTo(e2.$2);

  //   return r;
  //   // r == 0
  //   //     ? 0
  //   //     : r.isNegative
  //   //         ? r.abs()
  //   //         : -r;
  // });

  // for (final e in ret1) {
  //   e.$1.sort((e1, e2) {
  //     return e1.chapter.compareTo(e2.chapter);
  //   });
  // }

  return ret1;
}

String? _getScanlationGroup(List<dynamic> l) {
  for (final e in l) {
    if (e["type"] == "scanlation_group") {
      return e["attributes"]["name"];
    }
  }

  return null;
}

List<MangaEntry> _fromJson(List<dynamic> l) {
  try {
    final res = List.generate(
      l.length,
      (index) {
        final e = l[index];
        final id = e["id"];
        final attr = e["attributes"];
        final fileName =
            _findType("cover_art", e["relationships"])["attributes"]
                ["fileName"];

        final originalLanguage = attr["originalLanguage"];
        final altTitles = attr["altTitles"] as List<dynamic>;

        final safe = switch (attr["contentRating"] as String) {
          "safe" => AnimeSafeMode.safe,
          "erotica" || "suggestive" => AnimeSafeMode.ecchi,
          "pornographic" => AnimeSafeMode.h,
          String() => throw "invalid content rating",
        };

        final titleEnglish = _tagFirstIndex("en", altTitles);
        final titleJapanese = _tagFirstIndex(originalLanguage, altTitles);
        final titleJaJo = originalLanguage == "ja"
            ? _tagFirstIndex("ja-ro", altTitles, true)
            : null;

        final volumes = attr["lastVolume"];

        return MangaEntry(
          status: attr["status"],
          imageUrl:
              _constructImageUrl(id: id, thumb: false, fileName: fileName),
          thumbUrl: _constructImageUrl(id: id, thumb: true, fileName: fileName),
          year: attr["year"] ?? 0,
          safety: safe,
          genres: _genres(attr["tags"]),
          relations: _mangaRelations(e["relationships"]),
          titleSynonyms:
              _tagEntries(originalLanguage, altTitles, titleJapanese?.$2) +
                  _tagEntries("en", altTitles, titleEnglish?.$2) +
                  _tagEntries("ja-ro", altTitles, titleJaJo?.$2),
          title: titleJaJo?.$1 ?? _tagOrFirst("en", attr["title"]),
          titleEnglish: titleEnglish?.$1 ?? _tagOrFirst("en", attr["title"]),
          titleJapanese: titleJapanese?.$1 ??
              (altTitles.isEmpty ? "" : _tagOrFirst("ja", altTitles.first)),
          site: MangaMeta.mangaDex,
          id: MangaStringId(id),
          animeIds: const [],
          description: _tagOrFirst("en", attr["description"]),
          demographics: attr["publicationDemographic"] ?? "",
          volumes: (volumes is String ? int.tryParse(volumes) : volumes) ?? -1,
        );
      },
    );

    return res;
  } catch (e, stackTrace) {
    LogTarget.manga.logDefaultImportant(
        "unwrapping manga json".errorMessage(e), stackTrace);

    rethrow;
  }
}

// String _formatTags(List<String> l) {
//   final t = "[${l.map((e) => '"$e"').join(",")}]";
//   print(t);
//   return t;
// }

List<MangaRelation> _mangaRelations(List<dynamic> l) {
  final ret = <MangaRelation>[];

  for (final e in l) {
    if (e["type"] == "manga") {
      final attr = e["attributes"];
      if (attr == null) {
        continue;
      }

      ret.add(MangaRelation(
        id: MangaStringId(e["id"]),
        name: _tagOrFirst("en", attr["title"]),
      ));
    }
  }

  return ret;
}

Map<String, dynamic> _findType(String s, List<dynamic> l) {
  for (final e in l) {
    if (e["type"] == s) {
      return e;
    }
  }

  return {};
}

String _constructImageUrl({
  required String id,
  required bool thumb,
  required String fileName,
}) =>
    switch (thumb) {
      true => "https://uploads.mangadex.org/covers/$id/$fileName.256.jpg",
      false => "https://uploads.mangadex.org/covers/$id/$fileName",
    };

// List<MangaRelation> _relations(List<dynamic> l) {
//    if (l.isEmpty) {
//     return const [];
//   }

//   return l
//       .map((e) => MangaRelation(id: e["id"], name: e[""]))
//       .toList();
// }

List<MangaGenre> _genres(List<dynamic> l) {
  if (l.isEmpty) {
    return const [];
  }

  return l
      .map((e) => MangaGenre(
          id: MangaStringId(e["id"]),
          name: _tagOrFirst("en", e["attributes"]["name"])))
      .toList();
}

String? _tagOrNullList(String tag, List<dynamic> l) {
  if (l.isEmpty) {
    return "";
  }

  String? ret;
  for (final e in l) {
    final str = e[tag];
    if (str != null) {
      ret = str;
    }
  }

  return ret;
}

List<String> _tagEntries(String tag, List<dynamic> l, int? exclude) {
  final ret = <String>[];

  for (final (i, e) in l.indexed) {
    if (i == exclude) {
      continue;
    }

    final e1 = e[tag];
    if (e1 != null) {
      ret.add(e1);
    }
  }

  return ret;
}

(String, int)? _tagFirstIndex(String tag, List<dynamic> l,
    [bool longest = false]) {
  if (!longest) {
    for (final e in l.indexed) {
      final e1 = e.$2[tag];
      if (e1 != null) {
        return (e1, e.$1);
      }
    }
  } else {
    final ret = <(String, int)>[];

    for (final e in l.indexed) {
      final e1 = e.$2[tag];
      if (e1 != null) {
        ret.add((e1, e.$1));
      }
    }

    if (ret.isEmpty) {
      return null;
    }

    if (ret.length == 1) {
      return ret.first;
    }

    late (String, int) ret2;
    int longest = 0;
    for (final e in ret) {
      if (e.$1.length > longest) {
        longest = e.$1.length;
        ret2 = e;
      }
    }

    return ret2;
  }

  return null;
}

String _tagOrFirstList(String tag, List<dynamic> l) {
  if (l.isEmpty) {
    return "";
  }

  String? ret;
  for (final e in l) {
    final str = e[tag];
    if (str != null) {
      ret = str;
    }
  }

  return ret ?? (l.isNotEmpty ? _tagOrFirst(tag, l.first) : "");
}

String _tagOrFirst(String tag, Map<String, dynamic> m) {
  final en = m[tag];
  if (en == null) {
    return m.isNotEmpty ? m.values.first : "";
  }

  return en;
}
