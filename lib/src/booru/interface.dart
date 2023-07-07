// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/schemas/settings.dart';
import '../db/isar.dart';
import '../schemas/post.dart';

abstract class BooruAPI {
  Dio get client;
  bool get wouldBecomeStale;
  String get name;
  String get domain;
  Booru get booru;
  int? get currentPage;

  Future<Post> singlePost(int id);

  Future<List<Post>> page(int p, String tags, BooruTagging excludedTags);

  Future<List<Post>> fromPost(
      int postId, String tags, BooruTagging excludedTags);

  Future<List<String>> completeTag(String tag);

  Uri browserLink(int id);

  void setCookies(List<Cookie> cookies);

  void close();
}

int numberOfElementsPerRefresh() {
  var settings = settingsIsar().settings.getSync(0)!;
  if (settings.listViewBooru) {
    return 20;
  }

  return 10 * settings.picturesPerRow.number;
}

bool isSafeModeEnabled() => settingsIsar().settings.getSync(0)!.safeMode;

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

//enum Rating { questionable, explicit, safe }

const String kTorUserAgent =
    "Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0";

class CookieJarTab {
  final Map<Booru, CookieJar> _tab = {};

  CookieJar get(Booru b) {
    var res = _tab[b];
    if (res == null) {
      var emptyJar = CookieJar();
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
