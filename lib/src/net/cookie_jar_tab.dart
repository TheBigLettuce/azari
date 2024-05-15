// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "package:cookie_jar/cookie_jar.dart";
// import "package:gallery/src/interfaces/booru/booru.dart";

// Cookie jar from the booru's clients are stored here.
// Currently useless.
// class CookieJarTab {
//   factory CookieJarTab() {
//     if (_global != null) {
//       return _global!;
//     }

//     _global = CookieJarTab._new();
//     return _global!;
//   }

//   CookieJarTab._new();
//   final Map<Booru, CookieJar> _tab = {};

//   CookieJar get(Booru b) {
//     final res = _tab[b];
//     if (res == null) {
//       final emptyJar = CookieJar();
//       _tab[b] = emptyJar;
//       return emptyJar;
//     }

//     return res;
//   }
// }

// CookieJarTab? _global;
