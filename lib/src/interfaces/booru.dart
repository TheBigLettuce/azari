// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import '../db/schemas/post.dart';
import '../net/booru/danbooru.dart';
import '../net/booru/gelbooru.dart';
import 'tags.dart';

/// Enum which holds all the currently supported sites by this app.
/// All of the implementations of [BooruAPI] should be added here.
/// Prefixes, names and urls should be unique.
enum Booru {
  gelbooru(string: "Gelbooru", prefix: "g", url: "gelbooru.com"),
  danbooru(string: "Danbooru", prefix: "d", url: "danbooru.donmai.us");

  // Name. starting with an uppercase letter.
  final String string;

  /// Prefix ensures that the filenames will be unique.
  /// This is useful in the folders which have images from various sources.
  final String prefix;

  /// Url to the booru. All the requests are made to the booru API use this.
  /// Scheme is always assumed to be https.
  final String url;

  static Booru? fromPrefix(String prefix) {
    for (var b in Booru.values) {
      if (b.prefix == prefix) {
        return b;
      }
    }

    return null;
  }

  const Booru({required this.string, required this.prefix, required this.url});
}

/// The interface to interact with the various booru APIs.
///
/// Implemenations of this interface should hold no state, other than the [client].
/// In case when booru API doesn't support getting posts down a certain post number,
/// it should keep the page number and increase it after calls to [fromPost],
/// return the current page in [currentPage], return true in [wouldBecomeStale]
/// and reset page number after calls to [page].
abstract class BooruAPI {
  // The client with which all the requests are made to the booru API.
  Dio get client;

  /// Some booru do not support pulling posts down a certain post number,
  /// this flag reflects this.
  bool get wouldBecomeStale;

  /// Booru enum of this API. All the boorus should be added to this enum.
  Booru get booru;

  /// Some boorus do not support pulling posts down a certain post number,
  /// and instead API implementations use paging to make it work.
  /// This should be not null if [wouldBecomeStale] is true.
  int? get currentPage;

  /// Get a single post by it's id.
  /// This is used in many places, like tags and single post loading in the "Tags" page.
  Future<Post> singlePost(int id);

  /// Get posts by a certain page.
  /// This is only used to refresh the grid, the code which loads and presets the posts uses [fromPost] for further posts loading.
  /// The boorus which do not support geting posts down a certain post number should keep a page number internally,
  /// and return it in [currentPage].
  Future<(List<Post>, int?)> page(int p, String tags, BooruTagging excludedTags,
      {SafeMode? overrideSafeMode});

  /// Get the post's notes.
  /// Usually used for translations.
  Future<Iterable<String>> notes(int postId);

  /// Get posts down a certain post number.
  /// The boorus which do not support geting posts down a certain post number should keep a page number internally,
  /// and use paging to load the posts.
  Future<(List<Post>, int?)> fromPost(
      int postId, String tags, BooruTagging excludedTags,
      {SafeMode? overrideSafeMode});

  /// Tag completition, this shouldn't present more than 10 at a time.
  Future<List<String>> completeTag(String tag);

  /// Constructs a link to the post to be loaded in the browser, outside the app.
  Uri browserLink(int id);

  /// Sets the cookies for all the requests done with the [client].
  /// This is useful with Cloudlfare, but currently is usesless.
  void setCookies(List<Cookie> cookies);

  /// After the call to [close], [client] should not work.
  void close();

  /// [fromSettings] returns a selected *booru API, consulting the settings.
  /// Some *booru have no way to retreive posts down
  /// of a post number, in this case [page] comes in handy:
  /// that is, it makes refreshes on restore few.
  static BooruAPI fromSettings({int? page}) {
    return BooruAPI.fromEnum(Settings.fromDb().selectedBooru, page: page);
  }

  static BooruAPI fromEnum(Booru booru, {required int? page}) {
    final dio = Dio(BaseOptions(
      responseType: ResponseType.json,
    ));

    final jar = UnsaveableCookieJar(CookieJarTab().get(booru));
    dio.interceptors.add(CookieManager(jar));

    return switch (booru) {
      Booru.danbooru => Danbooru(dio, jar),
      Booru.gelbooru => Gelbooru(page ?? 0, dio, jar),
    };
  }

  static numberOfElementsPerRefresh() {
    final settings = Settings.fromDb();
    if (settings.booru.listView) {
      return 20;
    }

    return 10 * settings.booru.columns.number;
  }
}

String stripHtml(String s) {
  var first = s.indexOf("\u003c");

  while (first != -1) {
    s = s.replaceRange(first, s.indexOf("\u003e") + 1, "");
    first = s.indexOf("\u003c");
  }

  return s;
}

class CloudflareException implements Exception {}

class UnsaveableCookieJar implements CookieJar {
  final CookieJar _proxy;

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) =>
      _proxy.delete(uri, withDomainSharedCookie);

  @override
  Future<void> deleteAll() => _proxy.deleteAll();

  @override
  bool get ignoreExpires => _proxy.ignoreExpires;

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) => _proxy.loadForRequest(uri);

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) =>
      Future.value();

  void replaceDirectly(Uri uri, List<Cookie> cookies) async {
    await _proxy.deleteAll();
    _proxy.saveFromResponse(uri, cookies);
  }

  const UnsaveableCookieJar(CookieJar jar) : _proxy = jar;
}

/// Cookie jar from the booru's clients are stored here.
/// Currently useless.
class CookieJarTab {
  final Map<Booru, CookieJar> _tab = {};

  CookieJar get(Booru b) {
    final res = _tab[b];
    if (res == null) {
      final emptyJar = CookieJar();
      _tab[b] = emptyJar;
      return emptyJar;
    }

    return res;
  }

  CookieJarTab._new();
  factory CookieJarTab() {
    if (_global != null) {
      return _global!;
    }

    _global = CookieJarTab._new();
    return _global!;
  }
}

CookieJarTab? _global;
