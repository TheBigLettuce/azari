// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/manga/conventers/manga_dex/chapters/manga_dex_chapters.dart";
import "package:gallery/src/net/manga/conventers/manga_dex/entries/manga_dex_entries.dart";
import "package:gallery/src/net/manga/conventers/manga_dex/genres/manga_dex_genres.dart";
import "package:gallery/src/net/manga/conventers/manga_dex/images/manga_dex_images.dart";

const Duration _defaultTimeout = Duration(seconds: 30);

class MangaDex implements MangaAPI {
  const MangaDex(this.client);

  static const _log = LogTarget.manga;
  final Dio client;

  @override
  MangaMeta get site => MangaMeta.mangaDex;

  @override
  String browserUrl(MangaEntry e) => "https://mangadex.org/title/${e.id}";

  @override
  Future<List<MangaEntry>> search(
    String s, {
    int page = 0,
    int count = 10,
    AnimeSafeMode safeMode = AnimeSafeMode.safe,
    List<MangaId>? includesTag,
  }) async {
    final res = await client.getUriLog<Map<String, dynamic>>(
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
        if (safeMode == AnimeSafeMode.safe) "contentRating[1]": "suggestive",
        if (includesTag != null && includesTag.isNotEmpty)
          ...makeTags(includesTag),
      }),
      LogReq("Manga search page $page", _log),
      options: Options(
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        responseType: ResponseType.json,
      ),
    );

    return MangaDexEntries.fromJson(res.data!).emptyIfNotOk();
  }

  @override
  Future<List<MangaEntry>> top(int page, int count) =>
      search("", page: page, count: count);

  @override
  Future<List<MangaGenre>> tags() async {
    final res = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(site.url, "/manga/tag"),
      const LogReq("Manga tags", _log),
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
      ),
    );

    return MangaDexGenres.fromJson(res.data!).emptyIfNotOk();
  }

  @override
  Future<double> score(MangaEntry e) async {
    final res = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(site.url, "/statistics/manga/${e.id}"),
      const LogReq("Manga score", _log),
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
      ),
    );

    if (res.data == null) {
      return 0;
    }

    final tt = (res.data!["statistics"] as Map<String, dynamic>).values.first
        as Map<String, dynamic>;

    final t = (tt["rating"] as Map<String, dynamic>)["average"];

    return t == null ? -1 : (t as num).toDouble();
  }

  @override
  Future<MangaEntry> single(MangaId id) async {
    final res = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(site.url, "/manga/$id", {
        "includes[0]": "cover_art",
        "includes[1]": "manga",
      }),
      const LogReq("Manga single", _log),
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
      ),
    );

    return MangaDexEntries.fromJson(res.data!).emptyIfNotOk().first;
  }

  @override
  Future<List<MangaChapter>> chapters(
    MangaId id, {
    int page = 0,
    int count = 100,
    MangaChapterOrder order = MangaChapterOrder.desc,
  }) async {
    final res = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(site.url, "/manga/$id/feed", {
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
      LogReq("Manga chapters page $page", _log),
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
      ),
    );

    return MangaDexChapters.fromJson(res.data!).filterLanguage("en");
  }

  @override
  Future<List<MangaImage>> imagesForChapter(MangaId id) async {
    final res = await client.getUriLog<Map<String, dynamic>>(
      Uri.https(site.url, "/at-home/server/$id"),
      const LogReq("Manga single", _log),
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
      ),
    );

    return MangaDexImages.fromJson(res.data!).emptyIfNotOk();
  }

  static Map<String, dynamic> makeTags(List<MangaId> includesTag) {
    final m = <String, dynamic>{};

    for (final (i, id) in includesTag.indexed) {
      m["includedTags[$i]"] = (id as MangaStringId).id;
    }

    return m;
  }
}
