// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';

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
