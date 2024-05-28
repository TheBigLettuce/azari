// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "package:flutter/material.dart";

// abstract interface class CacheElement {}

// mixin class SimpleMapCache implements CachedDbValues {
//   final _m = <Key, CacheElement>{};

//   @override
//   T putIfAbsent<T extends CacheElement>(
//     Key key,
//     T Function() ifAbsent,
//   ) =>
//       _m.putIfAbsent(key, ifAbsent) as T;

//   @override
//   void clear() => _m.clear();
// }

// abstract interface class CachedDbValues {
//   T putIfAbsent<T extends CacheElement>(
//     Key key,
//     T Function() ifAbsent,
//   );

//   void clear();
// }

// class ValuesCache<T extends CachedDbValues> extends InheritedWidget {
//   const ValuesCache({
//     super.key,
//     required this.cache,
//     required super.child,
//   });

//   final T cache;

//   static T of<T extends CachedDbValues>(BuildContext context) {
//     final widget = context.dependOnInheritedWidgetOfExactType<ValuesCache<T>>();

//     return widget!.cache;
//   }

//   @override
//   bool updateShouldNotify(ValuesCache<T> oldWidget) => cache != oldWidget.cache;
// }
